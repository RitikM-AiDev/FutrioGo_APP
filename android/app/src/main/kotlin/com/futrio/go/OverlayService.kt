package com.futrio.go

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterSurfaceView
import io.flutter.embedding.android.FlutterTextureView
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class OverlayService : Service() {

    companion object {
        const val CHANNEL_ID = "futrio_overlay_channel"
        const val NOTIFICATION_ID = 1
        const val ENGINE_ID = "futrio_overlay_engine"
        const val METHOD_CHANNEL = "com.futrio.go/overlay"
        var instance: OverlayService? = null
    }

    private var windowManager: WindowManager? = null
    private var flutterView: FlutterView? = null
    private var flutterEngine: FlutterEngine? = null
    private var methodChannel: MethodChannel? = null
    private var isFocusable = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        startForegroundNotification()
        setupFlutterEngine()
        addOverlayWindow()
    }

    private fun startForegroundNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Futrio Go Overlay",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Futrio Go overlay service"
                setShowBadge(false)
            }
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }

        val stopIntent = Intent(this, OverlayService::class.java).apply {
            action = "STOP"
        }
        val stopPending = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Futrio Go")
            .setContentText("Overlay active — tap to dismiss")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Dismiss", stopPending)
            .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    private fun setupFlutterEngine() {
        flutterEngine = FlutterEngine(this)
        flutterEngine!!.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine!!)

        methodChannel = MethodChannel(
            flutterEngine!!.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        )
        methodChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "setFocusable" -> {
                    val focusable = call.argument<Boolean>("focusable") ?: false
                    setWindowFocusable(focusable)
                    result.success(null)
                }
                "closeOverlay" -> {
                    stopSelf()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun addOverlayWindow() {
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 0
            y = 0
        }

        flutterView = FlutterView(this, FlutterTextureView(this))
        flutterView!!.attachToFlutterEngine(flutterEngine!!)

        windowManager!!.addView(flutterView, params)
    }

    fun setWindowFocusable(focusable: Boolean) {
        isFocusable = focusable
        val lp = flutterView?.layoutParams as? WindowManager.LayoutParams ?: return
        if (focusable) {
            lp.flags = lp.flags and WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE.inv()
        } else {
            lp.flags = lp.flags or WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
        }
        windowManager?.updateViewLayout(flutterView, lp)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP") {
            stopSelf()
        }
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        flutterView?.let { windowManager?.removeView(it) }
        flutterView?.detachFromFlutterEngine()
        flutterEngine?.destroy()
        FlutterEngineCache.getInstance().remove(ENGINE_ID)
    }
}

