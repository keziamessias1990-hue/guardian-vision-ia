package com.example.guardian_notification_fixture;

import android.app.Activity;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.os.Bundle;

public final class ProbeActivity extends Activity {
    @Override
    public void onCreate(Bundle state) {
        super.onCreate(state);
        NotificationManager notifications = getSystemService(NotificationManager.class);
        notifications.createNotificationChannel(new NotificationChannel(
                "fixture", "Notificações fictícias", NotificationManager.IMPORTANCE_DEFAULT));
        boolean risk = getIntent().getBooleanExtra("risk", false);
        notifications.notify(risk ? 2 : 1, new Notification.Builder(this, "fixture")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setCategory(Notification.CATEGORY_MESSAGE)
                .setContentTitle("Notificação fictícia de teste")
                .setContentText(risk
                        ? "Não conte para seus pais. Vamos conversar no Discord."
                        : "Olá, tudo bem?")
                .build());
        finish();
    }
}
