package com.scholatransit.driver.scholatransit_driver_app

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FOREGROUND_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundLocationService" -> {
                    startForegroundLocationService()
                    result.success(true)
                }
                "stopForegroundLocationService" -> {
                    stopForegroundLocationService()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startForegroundLocationService() {
        val intent = Intent(this, ForegroundLocationService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopForegroundLocationService() {
        val intent = Intent(this, ForegroundLocationService::class.java)
        stopService(intent)
    }

    companion object {
        private const val FOREGROUND_CHANNEL =
            "com.scholatransit.driver/foreground_location_service"
    }
}
