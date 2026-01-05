package com.example.authenticator_app

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val SECURE_WINDOW_CHANNEL = "com.example.authenticator_app/secure_window"

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURE_WINDOW_CHANNEL)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "enableSecureFlag" -> {
            window?.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            result.success(null)
          }
          "disableSecureFlag" -> {
            window?.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            result.success(null)
          }
          else -> result.notImplemented()
        }
      }
  }
}
