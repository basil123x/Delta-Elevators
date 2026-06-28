package com.delta_elevator

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build

object DeltaNotificationChannels {
    const val CHANNEL_ID = "7e8d57cb-ec8e-4dca-9393-7b1e9a92b9f0"
    const val CHANNEL_NAME = "Delta Elevator Notifications"
    const val SOUND_NAME = "elevator_ding"

    fun createDefaultChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val notificationManager =
            context.getSystemService(NotificationManager::class.java) ?: return

        val soundUri =
            Uri.parse("android.resource://${context.packageName}/raw/$SOUND_NAME")
        val audioAttributes =
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

        val channel =
            NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                setSound(soundUri, audioAttributes)
                enableVibration(true)
            }

        notificationManager.createNotificationChannel(channel)
    }
}
