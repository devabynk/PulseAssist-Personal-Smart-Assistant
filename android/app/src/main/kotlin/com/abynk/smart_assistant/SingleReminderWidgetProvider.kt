package com.abynk.smart_assistant

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class SingleReminderWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.single_reminder_widget).apply {
                val titleLabel = widgetData.getString("title", "Next Reminder") ?: "Next Reminder"
                val reminderTitle = widgetData.getString("reminder_title", "No reminders") ?: "No reminders"
                val reminderDescription = widgetData.getString("reminder_description", "") ?: ""
                val reminderDateTime = widgetData.getString("reminder_datetime", "") ?: ""
                val reminderDueIn = widgetData.getString("reminder_due_in", "") ?: ""
                val priority = widgetData.getString("reminder_priority", "medium") ?: "medium"
                
                setTextViewText(R.id.widget_title_label, titleLabel)
                setTextViewText(R.id.reminder_title, reminderTitle)
                setTextViewText(R.id.reminder_description, reminderDescription)
                setTextViewText(R.id.reminder_datetime, reminderDateTime)
                setTextViewText(R.id.reminder_due_in, reminderDueIn)
                
                // Set priority color using system resources
                val priorityColor = when (priority) {
                    "high" -> context.getColor(R.color.widget_priority_high)
                    "medium" -> context.getColor(R.color.widget_priority_medium)
                    "low" -> context.getColor(R.color.widget_priority_low)
                    else -> context.getColor(R.color.widget_priority_medium)
                }
                setInt(R.id.reminder_priority_indicator, "setBackgroundColor", priorityColor)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
