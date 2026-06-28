package com.delta_elevator

import android.app.Application

class DeltaApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        DeltaNotificationChannels.createDefaultChannel(this)
    }
}
