package com.sujithchalla.bitlock

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Main activity. Hosts the `bitlock/security` method channel used by
 * the Dart `SecureScreen` widget to toggle FLAG_SECURE while
 * controlled-viewing screens are visible, so those screens block
 * supported capture paths (screenshots / screen recording on
 * standard Android). FLAG_SECURE does not stop rooted devices or an
 * external camera, and no UI copy claims otherwise.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "bitlock/security")
            .setMethodCallHandler { call, result ->
                if (call.method == "setFlagSecure") {
                    val on = call.arguments as? Boolean ?: false
                    runOnUiThread {
                        if (on) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
