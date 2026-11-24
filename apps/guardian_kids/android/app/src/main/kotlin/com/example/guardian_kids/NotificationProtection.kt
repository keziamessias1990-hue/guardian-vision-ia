package com.example.guardian_kids

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.os.Build
import android.os.SystemClock
import android.provider.Settings

// Accessed on Android's main thread by the activity and listener.
internal object NotificationProtection {
    private const val channelId = "guardian_protection"
    private const val indicatorId = 402
    private val supported = setOf("com.whatsapp", "com.discord", "org.telegram.messenger", "com.roblox.client")

    data class Session(val id: Long, val sources: Set<String>, val childId: String, val token: String)
    private var nextId = 0L
    private var session: Session? = null
    private var indicatorRequestedAt = 0L
    private var policyValidUntil = 0L
    var connected = false
    var linkRevoked = false
    private var rememberedSources: Set<String>? = null

    private fun manager(context: Context) =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun hasAccess(context: Context): Boolean {
        val component = ComponentName(context, GuardianNotificationListener::class.java)
        return if (Build.VERSION.SDK_INT >= 27) {
            manager(context).isNotificationListenerAccessGranted(component)
        } else {
            Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners")
                .orEmpty().split(':').any { ComponentName.unflattenFromString(it) == component }
        }
    }

    private fun canShow(context: Context): Boolean {
        val manager = manager(context)
        if (!manager.areNotificationsEnabled()) return false
        return Build.VERSION.SDK_INT < 26 ||
            manager.getNotificationChannel(channelId)?.importance != NotificationManager.IMPORTANCE_NONE
    }

    fun loadApproval(context: Context) {
        rememberedSources = DeviceLinkStorage.approvedSources(context)
    }

    fun status(context: Context): Map<String, Any> {
        val access = hasAccess(context)
        val indicator = canShow(context)
        if (rememberedSources != null && (!access || !indicator)) {
            stop(context, forgetApproval = true)
        }
        val active = current(context)
        return mapOf(
            "linkRevoked" to linkRevoked,
            "access" to access,
            "connected" to connected,
            "indicatorAllowed" to indicator,
            "resumePending" to (active == null && session == null && rememberedSources != null),
            "sources" to (active?.sources?.toList() ?: emptyList<String>()),
        )
    }

    fun restore(context: Context, authorized: Set<String>, token: String?): Boolean {
        val approved = rememberedSources ?: return false
        val link = DeviceLinkStorage.read(context) ?: return false
        if (link["deviceToken"] != token) return false
        if (approved != authorized) {
            stop(context, forgetApproval = true)
            return false
        }
        if (session != null) return true
        return start(context, approved, link["childId"], token, remember = false)
    }

    fun applyPolicy(context: Context, token: String?, authorized: Set<String>): String? {
        val link = DeviceLinkStorage.read(context) ?: return null
        if (token != link["deviceToken"]) return null
        val active = current(context)
        if (rememberedSources != null && rememberedSources != authorized) {
            stop(context, forgetApproval = true)
            return "paused"
        }
        if (active == null) return "paused"
        policyValidUntil = SystemClock.elapsedRealtime() + 45_000
        return "active"
    }

    fun invalidateLink(context: Context, token: String) {
        val link = DeviceLinkStorage.read(context) ?: return
        if (link["deviceToken"] != token) return
        DeviceLinkStorage.clearIfMatches(context, token)
        linkRevoked = true
        stop(context, forgetApproval = true)
    }

    fun selectedSource(source: String): Boolean = session?.sources?.contains(source) == true

    fun current(context: Context): Session? {
        val value = session ?: return null
        if (SystemClock.elapsedRealtime() >= policyValidUntil) {
            stop(context)
            return null
        }
        if (!connected || !hasAccess(context) || !canShow(context)) {
            stop(context, forgetApproval = !hasAccess(context) || !canShow(context))
            return null
        }
        if (manager(context).activeNotifications.none { it.id == indicatorId }) {
            // Android posts asynchronously. While waiting, do not read or send.
            if (SystemClock.elapsedRealtime() - indicatorRequestedAt >= 2_000) stop(context, forgetApproval = true)
            return null
        }
        indicatorRequestedAt = 0
        return value
    }

    fun start(
        context: Context, sources: Set<String>, childId: String?, token: String?, remember: Boolean = true,
    ): Boolean {
        val allowedSources = if (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0)
            supported + "com.example.guardian_notification_fixture" else supported
        if (!connected || !hasAccess(context) || !canShow(context) || sources.isEmpty() ||
            !allowedSources.containsAll(sources) || childId.isNullOrBlank() || token.isNullOrBlank()) return false

        val manager = manager(context)
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(NotificationChannel(
                channelId, "Proteção de notificações", NotificationManager.IMPORTANCE_LOW,
            ))
        }
        val open = PendingIntent.getActivity(
            context, 0, Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        @Suppress("DEPRECATION")
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, channelId)
            else Notification.Builder(context)
        if (remember) {
            DeviceLinkStorage.save(context, childId, token, sources)
            rememberedSources = sources
        }
        indicatorRequestedAt = SystemClock.elapsedRealtime()
        policyValidUntil = indicatorRequestedAt + 45_000
        manager.notify(indicatorId, builder.setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentTitle("Guardian Kids · análise ativa")
            .setContentText("Toque para ver os aplicativos selecionados ou pausar.")
            .setContentIntent(open)
            .setOngoing(true)
            .build())
        session = Session(++nextId, sources, childId, token)
        return true
    }

    fun stop(context: Context, forgetApproval: Boolean = false) {
        session = null
        policyValidUntil = 0
        manager(context).cancel(indicatorId)
        if (forgetApproval) {
            rememberedSources = null
            try {
                DeviceLinkStorage.forgetApproval(context)
            } catch (_: Exception) {
                DeviceLinkStorage.clear(context)
                linkRevoked = true
            }
        }
    }

}
