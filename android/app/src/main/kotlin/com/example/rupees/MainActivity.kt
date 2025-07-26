package com.example.rupees

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "flutter.dev/device_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAndroidSdkVersion" -> {
                    try {
                        val sdkVersion = Build.VERSION.SDK_INT
                        result.success(sdkVersion)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get Android SDK version", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
