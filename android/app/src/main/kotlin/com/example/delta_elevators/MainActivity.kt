package com.delta_elevator

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        DeltaNotificationChannels.createDefaultChannel(this)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        DeltaNotificationChannels.createDefaultChannel(this)
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.delta_elevator/notifications",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "ensureDefaultChannel" -> {
                    DeltaNotificationChannels.createDefaultChannel(this)
                    result.success(DeltaNotificationChannels.CHANNEL_ID)
                }
                else -> result.notImplemented()
            }
        }
    }
}
