package com.csmimtbshop.com

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import kotlin.math.abs

object CallPlatformBridge {
    var active: Boolean = false
    var video: Boolean = false
    private var channel: MethodChannel? = null

    fun attach(value: MethodChannel) {
        channel = value
    }

    fun detach(value: MethodChannel) {
        if (channel === value) channel = null
    }

    fun invoke(method: String, arguments: Any? = null) {
        channel?.invokeMethod(method, arguments)
    }
}

class CallForegroundService : Service() {
    private lateinit var windowManager: WindowManager
    private val overlayHandler = Handler(Looper.getMainLooper())
    private var overlayView: View? = null
    private var overlayTime: TextView? = null

    private var callActive = false
    private var video = false
    private var appVisible = true
    private var remoteName = ""
    private var connectedAtMillis = 0L

    private val overlayTicker = object : Runnable {
        override fun run() {
            updateElapsedTime()
            overlayHandler.postDelayed(this, TICK_INTERVAL_MILLIS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_HANG_UP -> {
                removeSystemOverlay()
                CallPlatformBridge.invoke("hangUp")
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }

            ACTION_STOP -> {
                callActive = false
                removeSystemOverlay()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }

            ACTION_APP_VISIBILITY -> {
                appVisible = intent.getBooleanExtra(EXTRA_APP_VISIBLE, true)
                updateSystemOverlay()
                return START_NOT_STICKY
            }
        }

        callActive = true
        video = intent?.getBooleanExtra(EXTRA_VIDEO, false) == true
        remoteName = intent?.getStringExtra(EXTRA_REMOTE_NAME).orEmpty()
        connectedAtMillis = intent?.getLongExtra(EXTRA_CONNECTED_AT_MILLIS, 0L) ?: 0L

        val notification = buildNotification(video, remoteName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val foregroundTypes = ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE or
                if (video) ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA else 0
            startForeground(NOTIFICATION_ID, notification, foregroundTypes)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        updateSystemOverlay()
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        callActive = false
        removeSystemOverlay()
        super.onDestroy()
    }

    private fun updateSystemOverlay() {
        val shouldShow = callActive && !video && !appVisible && canDrawOverlays()
        if (shouldShow) showSystemOverlay() else removeSystemOverlay()
    }

    private fun canDrawOverlays(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this)

    private fun showSystemOverlay() {
        if (overlayView != null) {
            updateElapsedTime()
            return
        }

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            isClickable = true
            contentDescription = getString(R.string.call_overlay_return_to_call)
        }
        val iconContainer = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.rgb(30, 194, 104))
            }
            elevation = dp(8).toFloat()
        }
        val icon = ImageView(this).apply {
            setImageResource(R.drawable.ic_call_overlay)
            contentDescription = getString(R.string.call_overlay_return_to_call)
        }
        iconContainer.addView(
            icon,
            FrameLayout.LayoutParams(dp(26), dp(26), Gravity.CENTER),
        )
        root.addView(iconContainer, LinearLayout.LayoutParams(dp(56), dp(56)))

        overlayTime = TextView(this).apply {
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            textSize = 13f
            setPadding(dp(8), dp(2), dp(8), dp(2))
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(10).toFloat()
                setColor(Color.argb(210, 24, 24, 24))
            }
            setShadowLayer(2f, 0f, 1f, Color.BLACK)
        }
        root.addView(
            overlayTime,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                dp(24),
            ).apply {
                topMargin = dp(4)
                gravity = Gravity.CENTER_HORIZONTAL
            },
        )

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = resources.displayMetrics.widthPixels - dp(84)
            y = dp(120)
        }
        attachDragAndOpenBehavior(root, params)

        try {
            windowManager.addView(root, params)
            overlayView = root
            overlayHandler.removeCallbacks(overlayTicker)
            overlayTicker.run()
        } catch (_: Throwable) {
            overlayView = null
            overlayTime = null
        }
    }

    private fun attachDragAndOpenBehavior(
        view: View,
        params: WindowManager.LayoutParams,
    ) {
        var downRawX = 0f
        var downRawY = 0f
        var startX = 0
        var startY = 0
        view.setOnTouchListener { _, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    downRawX = event.rawX
                    downRawY = event.rawY
                    startX = params.x
                    startY = params.y
                    true
                }

                MotionEvent.ACTION_MOVE -> {
                    params.x = startX + (event.rawX - downRawX).toInt()
                    params.y = startY + (event.rawY - downRawY).toInt()
                    overlayView?.let { windowManager.updateViewLayout(it, params) }
                    true
                }

                MotionEvent.ACTION_UP -> {
                    val dragThreshold = dp(6).toFloat()
                    val moved = abs(event.rawX - downRawX) > dragThreshold ||
                        abs(event.rawY - downRawY) > dragThreshold
                    if (!moved) openCallApp()
                    true
                }

                else -> false
            }
        }
    }

    private fun openCallApp() {
        startActivity(
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(MainActivity.EXTRA_RESTORE_ACTIVE_CALL, true)
            },
        )
    }

    private fun updateElapsedTime() {
        val elapsedSeconds = if (connectedAtMillis > 0L) {
            ((System.currentTimeMillis() - connectedAtMillis) / 1000L).coerceAtLeast(0L)
        } else {
            0L
        }
        val hours = elapsedSeconds / 3600L
        val minutes = (elapsedSeconds % 3600L) / 60L
        val seconds = elapsedSeconds % 60L
        overlayTime?.text = if (hours > 0L) {
            String.format(Locale.US, "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            String.format(Locale.US, "%02d:%02d", minutes, seconds)
        }
    }

    private fun removeSystemOverlay() {
        overlayHandler.removeCallbacks(overlayTicker)
        val view = overlayView
        overlayView = null
        overlayTime = null
        if (view != null) {
            try {
                windowManager.removeView(view)
            } catch (_: Throwable) {
                // The system may already have removed it with the app process.
            }
        }
    }

    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density + 0.5f).toInt()

    private fun buildNotification(video: Boolean, remoteName: String): Notification {
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openApp = PendingIntent.getActivity(
            this,
            REQUEST_OPEN_APP,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val hangUpIntent = Intent(this, CallForegroundService::class.java).apply {
            action = ACTION_HANG_UP
        }
        val hangUp = PendingIntent.getService(
            this,
            REQUEST_HANG_UP,
            hangUpIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val peer = remoteName.ifBlank { getString(R.string.call_notification_unknown_peer) }
        val message = getString(
            if (video) R.string.call_notification_video else R.string.call_notification_voice,
            peer,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(getString(R.string.call_notification_title))
            .setContentText(message)
            .setContentIntent(openApp)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_CALL)
            .setPriority(Notification.PRIORITY_HIGH)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                getString(R.string.call_notification_hang_up),
                hangUp,
            )
        if (connectedAtMillis > 0L) {
            builder.setWhen(connectedAtMillis).setUsesChronometer(true)
        }
        return builder.build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.call_notification_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = getString(R.string.call_notification_channel_description)
            setSound(null, null)
            enableVibration(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        private const val CHANNEL_ID = "gv_active_call"
        private const val NOTIFICATION_ID = 41001
        private const val REQUEST_OPEN_APP = 41002
        private const val REQUEST_HANG_UP = 41003
        private const val TICK_INTERVAL_MILLIS = 1000L
        private const val EXTRA_VIDEO = "video"
        private const val EXTRA_REMOTE_NAME = "remoteName"
        private const val EXTRA_CONNECTED_AT_MILLIS = "connectedAtMillis"
        private const val EXTRA_APP_VISIBLE = "appVisible"
        private const val ACTION_UPDATE = "com.gv.chat.call.UPDATE"
        private const val ACTION_STOP = "com.gv.chat.call.STOP"
        private const val ACTION_HANG_UP = "com.gv.chat.call.HANG_UP"
        private const val ACTION_APP_VISIBILITY = "com.gv.chat.call.APP_VISIBILITY"

        fun start(
            context: Context,
            video: Boolean,
            remoteName: String,
            connectedAtMillis: Long,
        ) {
            val intent = Intent(context, CallForegroundService::class.java).apply {
                action = ACTION_UPDATE
                putExtra(EXTRA_VIDEO, video)
                putExtra(EXTRA_REMOTE_NAME, remoteName)
                putExtra(EXTRA_CONNECTED_AT_MILLIS, connectedAtMillis)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun setAppVisible(context: Context, visible: Boolean) {
            if (!CallPlatformBridge.active) return
            context.startService(
                Intent(context, CallForegroundService::class.java).apply {
                    action = ACTION_APP_VISIBILITY
                    putExtra(EXTRA_APP_VISIBLE, visible)
                },
            )
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, CallForegroundService::class.java))
        }
    }
}
