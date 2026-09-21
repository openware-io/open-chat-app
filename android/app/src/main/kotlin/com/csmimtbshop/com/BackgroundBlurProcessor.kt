package com.csmimtbshop.com

import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import com.cloudwebrtc.webrtc.video.LocalVideoTrack
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.segmentation.Segmentation
import com.google.mlkit.vision.segmentation.selfie.SelfieSegmenterOptions
import org.webrtc.JavaI420Buffer
import org.webrtc.VideoFrame
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.floor

/**
 * Applies an on-device person mask to the local WebRTC track.
 *
 * Segmentation runs asynchronously at a capped rate. Every captured frame is
 * then composited synchronously with the latest valid mask, so both the local
 * preview and the encoded remote track receive the same blurred result.
 */
class BackgroundBlurProcessor :
    LocalVideoTrack.ExternalVideoFrameProcessing,
    AutoCloseable {

    private val segmenter = Segmentation.getClient(
        SelfieSegmenterOptions.Builder()
            .setDetectorMode(SelfieSegmenterOptions.STREAM_MODE)
            .enableRawSizeMask()
            .build(),
    )
    private val segmentationRunning = AtomicBoolean(false)

    @Volatile
    private var latestMask: PersonMask? = null

    @Volatile
    private var closed = false

    private var lastSegmentationAtMillis = 0L
    private var workspace: BlurWorkspace? = null
    private var captureHandler: Handler? = null

    override fun onFrame(frame: VideoFrame): VideoFrame {
        if (closed) return frame
        val releaseHandler = captureReleaseHandler() ?: return frame
        val i420 = frame.buffer.toI420() ?: return frame
        try {
            maybeRunSegmentation(i420, frame.rotation)
            val mask = latestMask ?: return frame
            if (!mask.matches(i420.width, i420.height, frame.rotation) || mask.isStale()) {
                return frame
            }

            val currentWorkspace = workspaceFor(i420.width, i420.height)
            currentWorkspace.read(i420)
            currentWorkspace.blur()
            val output = JavaI420Buffer.allocate(i420.width, i420.height)
            currentWorkspace.writeComposited(output, mask)
            val processed = VideoFrame(output, frame.rotation, frame.timestampNs)

            // LocalVideoTrack's processor API returns a frame instead of
            // exposing the downstream sink callback. Release our initial
            // reference on the capture looper immediately after that callback
            // has returned; downstream native users retain it when necessary.
            releaseHandler.post(processed::release)
            return processed
        } catch (error: Throwable) {
            // A visual effect must never interrupt the camera or the call.
            android.util.Log.w(TAG, "Background blur frame fallback", error)
            return frame
        } finally {
            i420.release()
        }
    }

    private fun maybeRunSegmentation(buffer: VideoFrame.I420Buffer, rotation: Int) {
        val now = SystemClock.elapsedRealtime()
        if (now - lastSegmentationAtMillis < SEGMENTATION_INTERVAL_MILLIS) return
        if (!segmentationRunning.compareAndSet(false, true)) return
        lastSegmentationAtMillis = now

        val width = buffer.width
        val height = buffer.height
        val normalizedRotation = normalizeRotation(rotation)
        val nv21 = i420ToNv21(buffer)
        val image = InputImage.fromByteArray(
            nv21,
            width,
            height,
            normalizedRotation,
            InputImage.IMAGE_FORMAT_NV21,
        )
        segmenter.process(image)
            .addOnSuccessListener { result ->
                if (closed) return@addOnSuccessListener
                val source = result.buffer.duplicate()
                source.rewind()
                val values = FloatArray(source.remaining() / Float.SIZE_BYTES)
                for (index in values.indices) {
                    values[index] = source.float
                }
                if (values.size == result.width * result.height) {
                    latestMask = PersonMask(
                        values = values,
                        width = result.width,
                        height = result.height,
                        sourceWidth = width,
                        sourceHeight = height,
                        rotation = normalizedRotation,
                        createdAtMillis = SystemClock.elapsedRealtime(),
                    )
                }
            }
            .addOnFailureListener { error ->
                android.util.Log.w(TAG, "Person segmentation failed", error)
            }
            .addOnCompleteListener {
                segmentationRunning.set(false)
            }
    }

    private fun captureReleaseHandler(): Handler? {
        val looper = Looper.myLooper() ?: return null
        val current = captureHandler
        if (current != null && current.looper === looper) return current
        return Handler(looper).also { captureHandler = it }
    }

    private fun workspaceFor(width: Int, height: Int): BlurWorkspace {
        val current = workspace
        if (current != null && current.width == width && current.height == height) {
            return current
        }
        return BlurWorkspace(width, height).also { workspace = it }
    }

    override fun close() {
        if (closed) return
        closed = true
        latestMask = null
        workspace = null
        segmenter.close()
    }

    private fun i420ToNv21(buffer: VideoFrame.I420Buffer): ByteArray {
        val width = buffer.width
        val height = buffer.height
        val chromaWidth = (width + 1) / 2
        val chromaHeight = (height + 1) / 2
        val output = ByteArray(width * height + chromaWidth * chromaHeight * 2)
        copyPlaneToArray(
            buffer.dataY,
            buffer.strideY,
            width,
            height,
            output,
            0,
        )
        val u = buffer.dataU.duplicate()
        val v = buffer.dataV.duplicate()
        var outputIndex = width * height
        for (row in 0 until chromaHeight) {
            val uRow = row * buffer.strideU
            val vRow = row * buffer.strideV
            for (column in 0 until chromaWidth) {
                output[outputIndex++] = v.get(vRow + column)
                output[outputIndex++] = u.get(uRow + column)
            }
        }
        return output
    }

    private fun copyPlaneToArray(
        source: ByteBuffer,
        sourceStride: Int,
        width: Int,
        height: Int,
        target: ByteArray,
        targetOffset: Int,
    ) {
        val input = source.duplicate()
        var outputIndex = targetOffset
        for (row in 0 until height) {
            val inputRow = row * sourceStride
            for (column in 0 until width) {
                target[outputIndex++] = input.get(inputRow + column)
            }
        }
    }

    private data class PersonMask(
        val values: FloatArray,
        val width: Int,
        val height: Int,
        val sourceWidth: Int,
        val sourceHeight: Int,
        val rotation: Int,
        val createdAtMillis: Long,
    ) {
        fun matches(frameWidth: Int, frameHeight: Int, frameRotation: Int): Boolean =
            sourceWidth == frameWidth &&
                sourceHeight == frameHeight &&
                rotation == normalizeRotation(frameRotation)

        fun isStale(): Boolean =
            SystemClock.elapsedRealtime() - createdAtMillis > MASK_MAX_AGE_MILLIS

        fun personAlpha(rawX: Int, rawY: Int): Float {
            val nx = (rawX + 0.5f) / sourceWidth.toFloat()
            val ny = (rawY + 0.5f) / sourceHeight.toFloat()
            val uprightX: Float
            val uprightY: Float
            when (rotation) {
                90 -> {
                    uprightX = 1f - ny
                    uprightY = nx
                }

                180 -> {
                    uprightX = 1f - nx
                    uprightY = 1f - ny
                }

                270 -> {
                    uprightX = ny
                    uprightY = 1f - nx
                }

                else -> {
                    uprightX = nx
                    uprightY = ny
                }
            }
            val maskX = floor(uprightX.coerceIn(0f, 0.999999f) * width).toInt()
            val maskY = floor(uprightY.coerceIn(0f, 0.999999f) * height).toInt()
            val confidence = values[maskY * width + maskX]
            val edge = ((confidence - PERSON_EDGE_START) /
                (PERSON_EDGE_END - PERSON_EDGE_START)).coerceIn(0f, 1f)
            return edge * edge * (3f - 2f * edge)
        }
    }

    private class BlurWorkspace(
        val width: Int,
        val height: Int,
    ) {
        private val chromaWidth = (width + 1) / 2
        private val chromaHeight = (height + 1) / 2
        private val y = ByteArray(width * height)
        private val yTemporary = ByteArray(width * height)
        private val yBlurred = ByteArray(width * height)
        private val u = ByteArray(chromaWidth * chromaHeight)
        private val uTemporary = ByteArray(chromaWidth * chromaHeight)
        private val uBlurred = ByteArray(chromaWidth * chromaHeight)
        private val v = ByteArray(chromaWidth * chromaHeight)
        private val vTemporary = ByteArray(chromaWidth * chromaHeight)
        private val vBlurred = ByteArray(chromaWidth * chromaHeight)

        fun read(buffer: VideoFrame.I420Buffer) {
            readPlane(buffer.dataY, buffer.strideY, width, height, y)
            readPlane(buffer.dataU, buffer.strideU, chromaWidth, chromaHeight, u)
            readPlane(buffer.dataV, buffer.strideV, chromaWidth, chromaHeight, v)
        }

        fun blur() {
            boxBlur(y, width, height, LUMA_BLUR_RADIUS, yTemporary, yBlurred)
            boxBlur(u, chromaWidth, chromaHeight, CHROMA_BLUR_RADIUS, uTemporary, uBlurred)
            boxBlur(v, chromaWidth, chromaHeight, CHROMA_BLUR_RADIUS, vTemporary, vBlurred)
        }

        fun writeComposited(output: JavaI420Buffer, mask: PersonMask) {
            writePlane(
                original = y,
                blurred = yBlurred,
                width = width,
                height = height,
                target = output.dataY,
                targetStride = output.strideY,
                mask = mask,
                coordinateScale = 1,
            )
            writePlane(
                original = u,
                blurred = uBlurred,
                width = chromaWidth,
                height = chromaHeight,
                target = output.dataU,
                targetStride = output.strideU,
                mask = mask,
                coordinateScale = 2,
            )
            writePlane(
                original = v,
                blurred = vBlurred,
                width = chromaWidth,
                height = chromaHeight,
                target = output.dataV,
                targetStride = output.strideV,
                mask = mask,
                coordinateScale = 2,
            )
        }

        private fun writePlane(
            original: ByteArray,
            blurred: ByteArray,
            width: Int,
            height: Int,
            target: ByteBuffer,
            targetStride: Int,
            mask: PersonMask,
            coordinateScale: Int,
        ) {
            var sourceIndex = 0
            for (row in 0 until height) {
                val targetRow = row * targetStride
                for (column in 0 until width) {
                    val alpha = mask.personAlpha(
                        (column * coordinateScale).coerceAtMost(mask.sourceWidth - 1),
                        (row * coordinateScale).coerceAtMost(mask.sourceHeight - 1),
                    )
                    val foreground = original[sourceIndex].toInt() and 0xff
                    val background = blurred[sourceIndex].toInt() and 0xff
                    val value = background + ((foreground - background) * alpha).toInt()
                    target.put(targetRow + column, value.coerceIn(0, 255).toByte())
                    sourceIndex++
                }
            }
        }

        private fun readPlane(
            source: ByteBuffer,
            sourceStride: Int,
            width: Int,
            height: Int,
            target: ByteArray,
        ) {
            val input = source.duplicate()
            var targetIndex = 0
            for (row in 0 until height) {
                val sourceRow = row * sourceStride
                for (column in 0 until width) {
                    target[targetIndex++] = input.get(sourceRow + column)
                }
            }
        }

        private fun boxBlur(
            source: ByteArray,
            width: Int,
            height: Int,
            radius: Int,
            temporary: ByteArray,
            output: ByteArray,
        ) {
            if (width == 0 || height == 0) return
            val window = radius * 2 + 1
            for (row in 0 until height) {
                val rowOffset = row * width
                var sum = 0
                for (offset in -radius..radius) {
                    val x = offset.coerceIn(0, width - 1)
                    sum += source[rowOffset + x].toInt() and 0xff
                }
                for (column in 0 until width) {
                    temporary[rowOffset + column] = (sum / window).toByte()
                    val removeX = (column - radius).coerceIn(0, width - 1)
                    val addX = (column + radius + 1).coerceIn(0, width - 1)
                    sum -= source[rowOffset + removeX].toInt() and 0xff
                    sum += source[rowOffset + addX].toInt() and 0xff
                }
            }

            for (column in 0 until width) {
                var sum = 0
                for (offset in -radius..radius) {
                    val y = offset.coerceIn(0, height - 1)
                    sum += temporary[y * width + column].toInt() and 0xff
                }
                for (row in 0 until height) {
                    output[row * width + column] = (sum / window).toByte()
                    val removeY = (row - radius).coerceIn(0, height - 1)
                    val addY = (row + radius + 1).coerceIn(0, height - 1)
                    sum -= temporary[removeY * width + column].toInt() and 0xff
                    sum += temporary[addY * width + column].toInt() and 0xff
                }
            }
        }
    }

    companion object {
        private const val TAG = "BackgroundBlur"
        private const val SEGMENTATION_INTERVAL_MILLIS = 100L
        private const val MASK_MAX_AGE_MILLIS = 1_000L
        private const val PERSON_EDGE_START = 0.35f
        private const val PERSON_EDGE_END = 0.72f
        private const val LUMA_BLUR_RADIUS = 12
        private const val CHROMA_BLUR_RADIUS = 6

        private fun normalizeRotation(rotation: Int): Int =
            ((rotation % 360) + 360) % 360
    }
}
