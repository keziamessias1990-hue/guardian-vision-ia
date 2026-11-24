package com.example.guardian_kids

import android.app.KeyguardManager
import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class GuardianNotificationListener : NotificationListenerService() {
    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null
    private var ready = false
    private var busy = false
    private val sentCandidates = LinkedHashMap<String, Long>()

    override fun onListenerConnected() {
        NotificationProtection.stop(this)
        if (engine == null) startEngine()
    }

    private fun startEngine() {
        val worker = FlutterEngine(applicationContext, null, false)
        val bridge = MethodChannel(worker.dartExecutor.binaryMessenger, "guardian/notification_worker")
        bridge.setMethodCallHandler { call, result ->
            when (call.method) {
                "ready" -> {
                    ready = true
                    NotificationProtection.connected = true
                    result.success(null)
                }
                "session" -> {
                    val id = call.argument<Number>("id")?.toLong()
                    val session = NotificationProtection.current(this)
                    result.success(if (session != null && session.id == id) {
                        mapOf("childId" to session.childId, "token" to session.token)
                    } else null)
                }
                "policyLink", "applyPolicy", "invalidateLink", "unlinked" -> {
                    try {
                        when (call.method) {
                            "policyLink" -> {
                                NotificationProtection.current(this)
                                result.success(DeviceLinkStorage.read(this)?.get("deviceToken"))
                            }
                            "applyPolicy" -> result.success(NotificationProtection.applyPolicy(
                                this,
                                call.argument<String>("deviceToken"),
                                call.argument<List<String>>("sources").orEmpty().toSet(),
                            ))
                            "invalidateLink" -> {
                                call.argument<String>("deviceToken")?.let {
                                    NotificationProtection.invalidateLink(this, it)
                                }
                                result.success(null)
                            }
                            "unlinked" -> {
                                val id = call.argument<Number>("id")?.toLong()
                                val session = NotificationProtection.current(this)
                                if (session != null && session.id == id) {
                                    NotificationProtection.invalidateLink(this, session.token)
                                }
                                result.success(null)
                            }
                        }
                    } catch (_: Exception) {
                        result.error("protection_sync", "Não foi possível sincronizar a proteção.", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        engine = worker
        channel = bridge
        worker.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint(
            FlutterInjector.instance().flutterLoader().findAppBundlePath(), "notificationWorker",
        ))
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        if (!ready || busy || !NotificationProtection.selectedSource(sbn.packageName)) return
        val session = NotificationProtection.current(this) ?: return
        val keyguard = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
        if (keyguard.isKeyguardLocked) return
        val notification = sbn.notification
        if (notification.flags and Notification.FLAG_GROUP_SUMMARY != 0 ||
            notification.flags and Notification.FLAG_ONGOING_EVENT != 0 ||
            notification.category != Notification.CATEGORY_MESSAGE ||
            notification.visibility == Notification.VISIBILITY_SECRET) return

        val key = sbn.key
        if (sentCandidates[key] == sbn.postTime) return
        val extras = notification.extras ?: return
        val content = (extras.getCharSequence(Notification.EXTRA_TEXT)
            ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT))
            ?.take(1000)?.toString()?.trim().orEmpty()
        if (content.isEmpty()) return

        sentCandidates[key] = sbn.postTime
        if (sentCandidates.size > 128) sentCandidates.remove(sentCandidates.keys.first())
        busy = true
        channel?.invokeMethod(
            "analyze",
            mapOf("text" to content, "id" to session.id, "time" to sbn.postTime),
            object : MethodChannel.Result {
                override fun success(result: Any?) { busy = false }
                override fun error(code: String, message: String?, details: Any?) { busy = false }
                override fun notImplemented() { busy = false }
            },
        )
    }

    override fun onListenerDisconnected() {
        shutdown()
    }

    override fun onDestroy() {
        shutdown()
        super.onDestroy()
    }

    private fun shutdown() {
        NotificationProtection.connected = false
        NotificationProtection.stop(this)
        channel?.setMethodCallHandler(null)
        engine?.destroy()
        channel = null
        engine = null
        ready = false
        busy = false
        sentCandidates.clear()
    }
}
