package com.abynk.smart_assistant

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

class RemindersListWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.reminders_list_widget).apply {
                val title = widgetData.getString("title", "Reminders") ?: "Reminders"
                val remindersDataJson = widgetData.getString("reminders_data", "[]") ?: "[]"
                val emptyMessage = widgetData.getString("empty_message", "No reminders") ?: "No reminders"
                
                setTextViewText(R.id.widget_title, title)
                
                try {
                    val remindersArray = JSONArray(remindersDataJson)
                    
                    if (remindersArray.length() == 0) {
                        // Show empty message
                        setViewVisibility(R.id.empty_message, View.VISIBLE)
                        setTextViewText(R.id.empty_message, emptyMessage)
                        setViewVisibility(R.id.reminder_item_1, View.GONE)
                        setViewVisibility(R.id.reminder_item_2, View.GONE)
                        setViewVisibility(R.id.reminder_item_3, View.GONE)
                    } else {
                        // Hide empty message
                        setViewVisibility(R.id.empty_message, View.GONE)
                        
                        // Display up to 3 reminders
                        for (i in 0 until minOf(3, remindersArray.length())) {
                            val reminder = remindersArray.getJSONObject(i)
                            val reminderTitle = reminder.getString("title")
                            val reminderDateTime = reminder.getString("dateTime")
                            val priority = reminder.getString("priority")
                            val isOverdue = reminder.getBoolean("isOverdue")
                            
                            // Set priority color
                            val priorityColor = when (priority) {
                                "high" -> Color.parseColor("#F44336")
                                "medium" -> Color.parseColor("#FF9800")
                                "low" -> Color.parseColor("#4CAF50")
                                else -> Color.parseColor("#FF9800")
                            }
                            
                            when (i) {
                                0 -> {
                                    setViewVisibility(R.id.reminder_item_1, View.VISIBLE)
                                    setTextViewText(R.id.reminder_item_1_title, reminderTitle)
                                    setTextViewText(R.id.reminder_item_1_datetime, reminderDateTime)
                                    setInt(R.id.reminder_item_1_priority, "setBackgroundColor", priorityColor)
                                }
                                1 -> {
                                    setViewVisibility(R.id.reminder_item_2, View.VISIBLE)
                                    setTextViewText(R.id.reminder_item_2_title, reminderTitle)
                                    setTextViewText(R.id.reminder_item_2_datetime, reminderDateTime)
                                    setInt(R.id.reminder_item_2_priority, "setBackgroundColor", priorityColor)
                                }
                                2 -> {
                                    setViewVisibility(R.id.reminder_item_3, View.VISIBLE)
                                    setTextViewText(R.id.reminder_item_3_title, reminderTitle)
                                    setTextViewText(R.id.reminder_item_3_datetime, reminderDateTime)
                                    setInt(R.id.reminder_item_3_priority, "setBackgroundColor", priorityColor)
                                }
                            }
                        }
                    }
                } catch (e: Exception) {
                    // Error parsing JSON, show empty state
                    setViewVisibility(R.id.empty_message, View.VISIBLE)
                    setTextViewText(R.id.empty_message, emptyMessage)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
