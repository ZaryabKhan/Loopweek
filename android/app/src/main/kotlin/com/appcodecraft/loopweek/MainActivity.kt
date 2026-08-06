package com.appcodecraft.loopweek

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "loopweek/notification_cache",
        ).setMethodCallHandler { call, result ->
            if (call.method == "clearScheduledNotifications") {
                val prefs =
                    applicationContext.getSharedPreferences(
                        "scheduled_notifications",
                        Context.MODE_PRIVATE,
                    )
                prefs.edit().clear().apply()
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}