package com.deviceinfo.device_info

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class NotificationService : NotificationListenerService() {

    companion object {
        val notificationLog = mutableListOf<Map<String, Any>>()
        private const val MAX_LOG_SIZE = 500
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return
        val extras = sbn.notification.extras
        val entry = mapOf(
            "packageName" to sbn.packageName,
            "title" to (extras?.getCharSequence("android.title")?.toString() ?: ""),
            "text" to (extras?.getCharSequence("android.text")?.toString() ?: ""),
            "timestamp" to sbn.postTime,
            "isOngoing" to sbn.isOngoing,
            "isClearable" to sbn.isClearable
        )
        synchronized(notificationLog) {
            notificationLog.add(0, entry)
            if (notificationLog.size > MAX_LOG_SIZE) {
                notificationLog.removeAt(notificationLog.size - 1)
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // Optional: track dismissed notifications
    }
}
