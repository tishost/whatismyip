package io.digdns.whatismyip

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "io.digdns.whatismyip/back_button"
    private var flutterEngine: FlutterEngine? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        this.flutterEngine = flutterEngine
    }
    
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Send back press event to Flutter
        val messenger = flutterEngine?.dartExecutor?.binaryMessenger
        if (messenger != null) {
            val channel = MethodChannel(messenger, CHANNEL)
            
            channel.invokeMethod("onBackPressed", null, object : io.flutter.plugin.common.MethodChannel.Result {
                override fun success(result: Any?) {
                    // Check if Flutter wants to handle it
                    if (result is Map<*, *>) {
                        val handled = result["handled"] as? Boolean
                        if (handled == false) {
                            // Close app on main thread
                            runOnUiThread {
                                finish()
                            }
                        }
                        // Don't call super - Flutter will handle exit internally
                    }
                }
                
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    // If Flutter can't handle it, close app
                    runOnUiThread {
                        finish()
                    }
                }
                
                override fun notImplemented() {
                    runOnUiThread {
                        finish()
                    }
                }
            })
            // Don't call super here - wait for Flutter response
        } else {
            // Flutter engine not ready, close app
            super.onBackPressed()
        }
    }
}

