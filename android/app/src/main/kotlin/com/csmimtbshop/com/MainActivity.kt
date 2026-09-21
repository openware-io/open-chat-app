package com.csmimtbshop.com

import android.app.PictureInPictureParams
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import android.provider.Settings
import android.util.Log
import android.util.Rational
import android.view.View
import android.view.WindowManager
import com.cloudwebrtc.webrtc.FlutterWebRTCPlugin
import com.cloudwebrtc.webrtc.video.LocalVideoTrack
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private lateinit var callPlatformChannel: MethodChannel
    private lateinit var secureScreenChannel: MethodChannel
    private lateinit var shareIntentChannel: MethodChannel
    private lateinit var messageKeepAliveChannel: MethodChannel
    private var pendingSharedItems: List<Map<String, String>>? = null
    private val backgroundBlurBindings = mutableMapOf<String, BackgroundBlurBinding>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        configureEdgeToEdge()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        callPlatformChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CALL_PLATFORM_CHANNEL,
        )
        CallPlatformBridge.attach(callPlatformChannel)
        callPlatformChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setCallState" -> {
                    val active = call.argument<Boolean>("active") == true
                    val video = call.argument<Boolean>("video") == true
                    val remoteName = call.argument<String>("remoteName").orEmpty()
                    val connectedAtMillis =
                        call.argument<Number>("connectedAtMillis")?.toLong() ?: 0L
                    CallPlatformBridge.active = active
                    CallPlatformBridge.video = video
                    configurePictureInPictureParams()
                    if (active) {
                        CallForegroundService.start(
                            this,
                            video,
                            remoteName,
                            connectedAtMillis,
                        )
                    } else {
                        clearBackgroundBlurProcessors()
                        CallForegroundService.stop(this)
                    }
                    result.success(null)
                }

                "enterPictureInPicture" -> result.success(enterCallPictureInPicture())
                "ensureSystemOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                        Settings.canDrawOverlays(this)
                    ) {
                        result.success(true)
                    } else {
                        startActivity(
                            Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName"),
                            ),
                        )
                        result.success(false)
                    }
                }
                "setBackgroundBlur" -> {
                    val trackId = call.argument<String>("trackId").orEmpty()
                    val enabled = call.argument<Boolean>("enabled") == true
                    result.success(setBackgroundBlur(trackId, enabled))
                }
                else -> result.notImplemented()
            }
        }

        secureScreenChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SECURE_SCREEN_CHANNEL,
        )
        secureScreenChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setSecure" -> {
                    val secure = call.argument<Boolean>("secure") == true
                    setSecureScreen(secure)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        shareIntentChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SHARE_INTENT_CHANNEL,
        )
        shareIntentChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingShare" -> {
                    val items = pendingSharedItems
                    pendingSharedItems = null
                    result.success(items)
                }
                else -> result.notImplemented()
            }
        }

        messageKeepAliveChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MESSAGE_KEEP_ALIVE_CHANNEL,
        )
        messageKeepAliveChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    try {
                        MessageKeepAliveService.start(this)
                        result.success(null)
                    } catch (error: RuntimeException) {
                        Log.e(TAG, "Unable to start message keep-alive service", error)
                        result.error(
                            "MESSAGE_KEEP_ALIVE_START_FAILED",
                            error.message,
                            null,
                        )
                    }
                }
                "stop" -> {
                    MessageKeepAliveService.stop(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // 冷启动（分享直接拉起 App）时，此刻即可处理初始 intent。
        handleShareIntent(intent)
    }

    /** 私密聊天/私密群聊禁止截图与录屏：加 FLAG_SECURE（截图失败、录屏内容为黑屏）。 */
    private fun setSecureScreen(secure: Boolean) {
        runOnUiThread {
            if (secure) {
                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        clearBackgroundBlurProcessors()
        CallPlatformBridge.detach(callPlatformChannel)
        if (::messageKeepAliveChannel.isInitialized) {
            messageKeepAliveChannel.setMethodCallHandler(null)
        }
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onStart() {
        super.onStart()
        CallForegroundService.setAppVisible(this, true)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleShareIntent(intent)
    }

    /** 解析 ACTION_SEND / ACTION_SEND_MULTIPLE：文本 + 各内容 URI 拷贝到缓存后回调 Flutter。 */
    private fun handleShareIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action ?: return
        if (action != Intent.ACTION_SEND && action != Intent.ACTION_SEND_MULTIPLE) return

        val items = mutableListOf<Map<String, String>>()
        val text = intent.getStringExtra(Intent.EXTRA_TEXT)
        if (!text.isNullOrBlank()) {
            items.add(mapOf("type" to "text", "text" to text))
        }

        val uris = mutableListOf<Uri>()
        val clipData = intent.clipData
        if (clipData != null) {
            for (i in 0 until clipData.itemCount) {
                clipData.getItemAt(i).uri?.let { uris.add(it) }
            }
        } else {
            val stream = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_STREAM)
            }
            stream?.let { uris.add(it) }
        }

        for (uri in uris) {
            copySharedUri(uri)?.let { items.add(it) }
        }
        if (items.isEmpty()) return

        pendingSharedItems = items
        if (::shareIntentChannel.isInitialized) {
            shareIntentChannel.invokeMethod("onSharedMedia", items)
        }
    }

    private fun copySharedUri(uri: Uri): Map<String, String>? {
        return try {
            val mime = contentResolver.getType(uri) ?: "application/octet-stream"
            val kind = mimeTypeKind(mime)
            val name = queryDisplayName(uri) ?: "shared_${System.currentTimeMillis()}.${extensionForMime(mime)}"
            val dir = File(cacheDir, "shared_media").apply { mkdirs() }
            val file = File(dir, "shared_${System.currentTimeMillis()}_${name.replace(Regex("[^A-Za-z0-9._-]"), "_")}")
            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(file).use { output -> input.copyTo(output) }
            } ?: return null
            mapOf("type" to kind, "path" to file.absolutePath, "mimeType" to mime, "displayName" to name)
        } catch (_: Exception) {
            null
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        return try {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (idx >= 0) cursor.getString(idx) else null
                } else null
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun extensionForMime(mime: String): String = when {
        mime.startsWith("image/jpeg") || mime.startsWith("image/jpg") -> "jpg"
        mime.startsWith("image/png") -> "png"
        mime.startsWith("image/webp") -> "webp"
        mime.startsWith("image/gif") -> "gif"
        mime.startsWith("image/heic") || mime.startsWith("image/heif") -> "heic"
        mime.startsWith("image/") -> "jpg"
        mime.startsWith("video/") -> "mp4"
        mime == "application/pdf" -> "pdf"
        else -> "bin"
    }

    private fun mimeTypeKind(mime: String): String = when {
        mime.startsWith("image/") -> "image"
        mime.startsWith("video/") -> "video"
        else -> "file"
    }

    override fun onResume() {
        super.onResume()
        if (intent?.getBooleanExtra(EXTRA_RESTORE_ACTIVE_CALL, false) != true) return
        intent.removeExtra(EXTRA_RESTORE_ACTIVE_CALL)
        Handler(Looper.getMainLooper()).post {
            if (CallPlatformBridge.active) {
                CallPlatformBridge.invoke("restoreCall")
            }
        }
    }

    override fun onStop() {
        CallForegroundService.setAppVisible(this, false)
        super.onStop()
    }

    private fun setBackgroundBlur(trackId: String, enabled: Boolean): Boolean {
        if (trackId.isBlank()) return false
        val existing = backgroundBlurBindings.remove(trackId)
        if (existing != null) {
            existing.track.removeProcessor(existing.processor)
            existing.processor.close()
        }
        if (!enabled) return true

        val plugin = FlutterWebRTCPlugin.sharedSingleton ?: return false
        val track = plugin.getLocalTrack(trackId) as? LocalVideoTrack ?: return false
        return try {
            val processor = BackgroundBlurProcessor()
            track.addProcessor(processor)
            backgroundBlurBindings[trackId] = BackgroundBlurBinding(track, processor)
            true
        } catch (error: Throwable) {
            android.util.Log.e("BackgroundBlur", "Unable to attach processor", error)
            false
        }
    }

    private fun clearBackgroundBlurProcessors() {
        val bindings = backgroundBlurBindings.values.toList()
        backgroundBlurBindings.clear()
        for (binding in bindings) {
            binding.track.removeProcessor(binding.processor)
            binding.processor.close()
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (!CallPlatformBridge.active || !CallPlatformBridge.video) return
        CallPlatformBridge.invoke("preparePictureInPicture")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) return
        // enterPictureInPictureMode 必须在 Activity 仍处于前台时调用。部分 MIUI
        // 设备在原来的 220ms 延迟结束前已经执行 onStop，导致 PiP 静默失败。
        enterCallPictureInPicture()
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration,
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        CallPlatformBridge.invoke(
            "pictureInPictureModeChanged",
            mapOf("inPictureInPicture" to isInPictureInPictureMode),
        )
    }

    private fun enterCallPictureInPicture(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
            !CallPlatformBridge.active ||
            !CallPlatformBridge.video ||
            isInPictureInPictureMode
        ) {
            return false
        }
        return try {
            val entered = enterPictureInPictureMode(buildPictureInPictureParams())
            if (!entered) {
                Log.w(TAG, "Android rejected video call picture-in-picture")
            }
            entered
        } catch (error: RuntimeException) {
            Log.e(TAG, "Unable to enter video call picture-in-picture", error)
            false
        }
    }

    private fun configurePictureInPictureParams() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            setPictureInPictureParams(buildPictureInPictureParams())
        }
    }

    private fun buildPictureInPictureParams(): PictureInPictureParams =
        PictureInPictureParams.Builder()
            .setAspectRatio(Rational(9, 16))
            .apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    setSeamlessResizeEnabled(false)
                    setAutoEnterEnabled(
                        CallPlatformBridge.active && CallPlatformBridge.video,
                    )
                }
            }
            .build()

    private fun configureEdgeToEdge() {
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes = window.attributes.apply {
                layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility =
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                    View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                    View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
        }
    }

    companion object {
        const val EXTRA_RESTORE_ACTIVE_CALL = "com.gv.chat.extra.RESTORE_ACTIVE_CALL"
        private const val TAG = "GvCallPiP"
        private const val CALL_PLATFORM_CHANNEL = "com.gv.chat/call_platform"
        private const val SECURE_SCREEN_CHANNEL = "com.gv.chat/secure_screen"
        private const val SHARE_INTENT_CHANNEL = "com.gv.chat/share_intent"
        private const val MESSAGE_KEEP_ALIVE_CHANNEL = "com.gv.chat/message_keep_alive"
        private const val PIP_PREPARE_DELAY_MILLIS = 220L
    }

    private data class BackgroundBlurBinding(
        val track: LocalVideoTrack,
        val processor: BackgroundBlurProcessor,
    )
}
