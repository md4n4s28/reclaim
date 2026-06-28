package com.reclaim.app

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import java.util.Calendar
import kotlin.random.Random

class MotivationReceiver : BroadcastReceiver() {

    companion object {
        const val TAG = "MotivationReceiver"
        const val CHANNEL_ID = "daily_motivation_channel"
        const val NOTIFICATION_ID = 200

        private val motivationalQuotes = listOf(
            "Every minute you resist, you're rewiring your brain. Keep going!",
            "You are stronger than a 5-second urge.",
            "Don't trade your long-term goals for short-term gratification.",
            "A clean day today is a massive victory for tomorrow.",
            "Breathe. You have the power to choose your path.",
            "Remember why you started. Don't give up now.",
            "Your future self is thanking you for the choices you make today."
        )

        fun scheduleMotivationAlarms(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            // Schedule alarms for 8:00, 11:00, 14:00, 17:00, 20:00, 23:00
            val hours = listOf(8, 11, 14, 17, 20, 23)
            
            for (i in hours.indices) {
                val hour = hours[i]
                val intent = Intent(context, MotivationReceiver::class.java).apply {
                    action = "com.reclaim.action.TRIGGER_MOTIVATION"
                    putExtra("hour_triggered", hour)
                }
                
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    i, // Unique request code per hour slot
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                val calendar = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, hour)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                    if (before(Calendar.getInstance())) {
                        add(Calendar.DATE, 1) // If time has passed, schedule for tomorrow
                    }
                }

                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            calendar.timeInMillis,
                            pendingIntent
                        )
                    } else {
                        alarmManager.setExact(
                            AlarmManager.RTC_WAKEUP,
                            calendar.timeInMillis,
                            pendingIntent
                        )
                    }
                    Log.d(TAG, "Scheduled motivation alarm for $hour:00 successfully")
                } catch (e: Exception) {
                    Log.e(TAG, "Error scheduling alarm for hour $hour", e)
                }
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "com.reclaim.action.TRIGGER_MOTIVATION" || intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "Triggering notification or rescheduling alarms")
            
            if (intent.action == "com.reclaim.action.TRIGGER_MOTIVATION") {
                showMotivationNotification(context)
            }
            
            // Reschedule alarms for tomorrow
            scheduleMotivationAlarms(context)
        }
    }

    private fun showMotivationNotification(context: Context) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Daily Motivation",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Daily reminders to stay strong and focused."
            }
            nm.createNotificationChannel(channel)
        }

        val randomQuote = motivationalQuotes[Random.nextInt(motivationalQuotes.size)]
        
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = PendingIntent.getActivity(
            context,
            999,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle("Reclaim Your Focus 🛡️")
            .setContentText(randomQuote)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        nm.notify(NOTIFICATION_ID + Random.nextInt(100), notification)
        Log.d(TAG, "Motivation notification sent: $randomQuote")
    }
}
