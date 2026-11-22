package com.reclaim.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import java.util.Calendar

/**
 * Discreet 2x2 Android Home Screen App Widget.
 *
 * Designed with neutral productivity terminology ("DAILY FOCUS", "DAYS ON TRACK", "MOMENTUM")
 * so outside observers cannot deduce that it tracks addiction/relapse recovery,
 * allowing users to proudly keep their streak visible on their home screen.
 */
class ReclaimStreakWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE ||
            intent.action == ACTION_UPDATE_STREAK
        ) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, ReclaimStreakWidget::class.java)
            val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            if (allWidgetIds != null && allWidgetIds.isNotEmpty()) {
                onUpdate(context, appWidgetManager, allWidgetIds)
            }
        }
    }

    companion object {
        const val ACTION_UPDATE_STREAK = "com.reclaim.app.ACTION_UPDATE_STREAK"

        private val QUOTES = arrayOf(
            "Strength through consistency.",
            "Discipline equals freedom.",
            "Small daily wins create giant victories.",
            "Energy flows where focus goes.",
            "Master your mind, master your world.",
            "One day or day one. You decide.",
            "Focus on the process, not the noise.",
            "Build momentum every single day."
        )

        fun updateAllWidgets(context: Context) {
            try {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val thisWidget = ComponentName(context, ReclaimStreakWidget::class.java)
                val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
                if (allWidgetIds != null && allWidgetIds.isNotEmpty()) {
                    val intent = Intent(context, ReclaimStreakWidget::class.java).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, allWidgetIds)
                    }
                    context.sendBroadcast(intent)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        private fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_streak_layout)

            // Read streak from FlutterSharedPreferences
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val streak = try {
                prefs.getLong("flutter.streak", 0L).toInt()
            } catch (e: Exception) {
                try {
                    prefs.getInt("flutter.streak", 0)
                } catch (e2: Exception) {
                    0
                }
            }

            // Streak number and label
            views.setTextViewText(R.id.widget_streak_count, streak.toString())
            views.setTextViewText(
                R.id.widget_streak_label,
                if (streak == 1) "DAY ON TRACK" else "DAYS ON TRACK"
            )

            // Milestone progress calculation
            val milestones = intArrayOf(3, 7, 14, 30, 60, 90, 180, 365)
            var targetMilestone = 365
            for (m in milestones) {
                if (m > streak) {
                    targetMilestone = m
                    break
                }
            }
            views.setProgressBar(R.id.widget_progress, targetMilestone, streak.coerceAtMost(targetMilestone), false)
            views.setTextViewText(R.id.widget_subtag, "GOAL: ${targetMilestone}D")

            // Daily discreet quote based on day of year
            val dayOfYear = Calendar.getInstance().get(Calendar.DAY_OF_YEAR)
            val quote = QUOTES[dayOfYear % QUOTES.size]
            views.setTextViewText(R.id.widget_quote, quote)

            // Tapping widget launches Reclaim app
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getActivity(context, 0, launchIntent, flags)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
