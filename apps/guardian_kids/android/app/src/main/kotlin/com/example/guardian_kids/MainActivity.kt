package com.example.guardian_kids

import android.Manifest
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "guardian/notification_controls")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "loadDeviceLink" -> {
                        try {
                            val link = DeviceLinkStorage.read(this)
                            NotificationProtection.loadApproval(this)
                            result.success(link)
                        } catch (_: Exception) {
                            result.error("device_link_read_failed", "Não foi possível recuperar o vínculo.", null)
                        }
                    }
                    "saveDeviceLink" -> {
                        try {
                            val childId = requireNotNull(call.argument<String>("childId"))
                            val token = requireNotNull(call.argument<String>("deviceToken"))
                            DeviceLinkStorage.save(this, childId, token)
                            NotificationProtection.loadApproval(this)
                            NotificationProtection.linkRevoked = false
                            result.success(null)
                        } catch (_: Exception) {
                            result.error("device_link_save_failed", "Não foi possível guardar o vínculo.", null)
                        }
                    }
                    "status" -> result.success(NotificationProtection.status(this))
                    "access" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(null)
                    }
                    "indicatorPermission" -> {
                        if (Build.VERSION.SDK_INT >= 33) {
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 41)
                        } else {
                            startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName))
                        }
                        result.success(null)
                    }
                    "start", "restoreProtection", "stop" -> {
                        try {
                            val sources = call.argument<List<String>>("sources").orEmpty().toSet()
                            val token = call.argument<String>("deviceToken")
                            when (call.method) {
                                "start" -> result.success(
                                    NotificationProtection.start(this, sources, call.argument<String>("childId"), token),
                                )
                                "restoreProtection" -> result.success(NotificationProtection.restore(this, sources, token))
                                "stop" -> {
                                    NotificationProtection.stop(this, forgetApproval = true)
                                    result.success(null)
                                }
                            }
                        } catch (_: Exception) {
                            result.error("protection_storage", "Não foi possível atualizar a proteção no Android.", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
