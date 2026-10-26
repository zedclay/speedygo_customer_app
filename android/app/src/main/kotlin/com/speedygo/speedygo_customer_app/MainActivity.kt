package com.speedygo.speedygo_customer_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ensureOrderChannel()
    }

    /** High-importance channel for Customer order pushes (id shared with backend). */
    private fun ensureOrderChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(ORDER_CHANNEL_ID) != null) return
        manager.createNotificationChannel(
            NotificationChannel(
                ORDER_CHANNEL_ID,
                "Mises à jour de commande",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Alertes pour le suivi de vos commandes"
            },
        )
    }

    private companion object {
        const val ORDER_CHANNEL_ID = "customer_order_updates"
    }
}
