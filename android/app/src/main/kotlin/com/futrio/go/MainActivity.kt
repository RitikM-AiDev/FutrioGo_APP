package com.futrio.go

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    companion object {
        private const val OVERLAY_PERMISSION_REQ = 1234
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        checkAndStartOverlay()
    }

    private fun checkAndStartOverlay() {
        if (!Settings.canDrawOverlays(this)) {
            // Ask user to grant overlay permission
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivityForResult(intent, OVERLAY_PERMISSION_REQ)
        } else {
            launchOverlayService()
        }
    }

    private fun launchOverlayService() {
        startForegroundService(Intent(this, OverlayService::class.java))
        // Close the launcher activity — the overlay service runs independently
        finish()
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == OVERLAY_PERMISSION_REQ) {
            if (Settings.canDrawOverlays(this)) {
                launchOverlayService()
            } else {
                // Permission denied — show minimal message and exit
                finish()
            }
        }
    }
}
