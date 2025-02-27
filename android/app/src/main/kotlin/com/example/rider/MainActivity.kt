package com.np.dropit.packer

import android.app.PictureInPictureParams
import android.os.Build
import android.provider.Settings
import android.os.Bundle
import android.os.Handler
import android.widget.Toast
import android.app.KeyguardManager
import android.content.Context
import android.util.Rational
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.np.dropit.packer/pip"
    private val CALL_CHANNEL = "com.np.dropit.packer/call"

    private var isActivityResumed = false  // To track activity state

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 🔥 Store the Flutter Engine instance
        FlutterEngineCache.getInstance().put("enginer", flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Set up the platform channel for PiP mode
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
                if (call.method == "enterPipMode") {
                    enterPipMode()
                    result.success(null)
                } else if (call.method == "isScreenLocked"){
                    result.success(isDeviceLocked())
                } else {
                    result.notImplemented()
                }
            }
        }

        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CALL_CHANNEL).setMethodCallHandler { call, result ->
                if (call.method == "startCallActivity") {
                    val intent = Intent(this, CallActivity::class.java)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    startActivity(intent)
                    result.success("Call Activity Started")
                } else if (call.method == "isScreenLocked"){
                    result.success(isDeviceLocked())
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isDeviceLocked(): Boolean {
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        return keyguardManager.isKeyguardLocked
    }

    private fun checkOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            Toast.makeText(this, "Grant 'Display Over Other Apps' permission", Toast.LENGTH_LONG).show()
        }
    }

    override fun onResume() {
        super.onResume()
        isActivityResumed = true  // Mark activity as resumed
    }

    override fun onPause() {
        super.onPause()
        isActivityResumed = false  // Mark activity as paused
    }

    // Handle PiP mode changes
    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: android.content.res.Configuration?
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)

        // Safely call the binary messenger and notify Flutter about PiP mode status
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).invokeMethod(
                "onPipModeChanged",
                isInPictureInPictureMode
            )
        }
    }

    // Manually enter PiP mode
    fun enterPipMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Check if the activity is in the resumed state before entering PiP mode
            if (isActivityResumed) {
                val manufacturer = Build.MANUFACTURER
                if (manufacturer.equals("OnePlus", ignoreCase = true) || manufacturer.equals("Xiaomi", ignoreCase = true) || manufacturer.equals("Poco", ignoreCase = true)) {
                    // For OnePlus devices, introduce a delay before entering PiP mode
                    Handler().postDelayed({
                        val aspectRatio = Rational(16, 9)  // Set the aspect ratio for PiP window
                        val pipBuilder = PictureInPictureParams.Builder()
                        pipBuilder.setAspectRatio(aspectRatio)
                        enterPictureInPictureMode(pipBuilder.build())
                    }, 200)
                } else {
                    // For other devices, enter PiP mode immediately
                    val aspectRatio = Rational(16, 9)  // Set the aspect ratio for PiP window
                    val pipBuilder = PictureInPictureParams.Builder()
                    pipBuilder.setAspectRatio(aspectRatio)
                    enterPictureInPictureMode(pipBuilder.build())
                }
            } else {
                // Log or handle the case when the activity is not resumed
                println("Cannot enter PiP mode. Activity is not in resumed state.")
            }
        }
    }

    companion object {
        fun callAccepted() {
            val engine = FlutterEngineCache.getInstance().get("enginer")
            engine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, "com.np.dropit.packer/call")
                    .invokeMethod("callAccepted", null)
            }
        }
    }
}