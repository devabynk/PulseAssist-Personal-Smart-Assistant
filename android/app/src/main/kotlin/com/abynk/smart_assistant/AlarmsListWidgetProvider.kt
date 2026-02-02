package com.abynk.smart_assistant

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

class AlarmsListWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.alarms_list_widget).apply {
                val title = widgetData.getString("title", "Alarms") ?: "Alarms"
                val alarmsDataJson = widgetData.getString("alarms_data", "[]") ?: "[]"
                val emptyMessage = widgetData.getString("empty_message", "No alarms set") ?: "No alarms set"
                val isTransparent = widgetData.getBoolean("widget_theme_transparent", false)
                
                setTextViewText(R.id.widget_title, title)
                
                // Use system color resources that adapt to dark/light mode
                val primaryTextColor = context.getColor(R.color.widget_text_primary)
                val secondaryTextColor = context.getColor(R.color.widget_text_secondary)
                val statusColorActive = context.getColor(R.color.widget_success)
                
                if (isTransparent) {
                    setInt(R.id.widget_background, "setBackgroundResource", R.drawable.widget_background_transparent)
                } else {
                    setInt(R.id.widget_background, "setBackgroundResource", R.drawable.widget_background_solid)
                }
                
                setTextColor(R.id.widget_title, primaryTextColor)
                setTextColor(R.id.empty_message, secondaryTextColor)

                try {
                    val alarmsArray = JSONArray(alarmsDataJson)
                    
                    if (alarmsArray.length() == 0) {
                        setViewVisibility(R.id.empty_message, View.VISIBLE)
                        setTextViewText(R.id.empty_message, emptyMessage)
                        setViewVisibility(R.id.alarm_item_1, View.GONE)
                        setViewVisibility(R.id.alarm_item_2, View.GONE)
                        setViewVisibility(R.id.alarm_item_3, View.GONE)
                    } else {
                        setViewVisibility(R.id.empty_message, View.GONE)
                        
                        // Reset visibility first to ensure clean state
                        setViewVisibility(R.id.alarm_item_1, View.GONE)
                        setViewVisibility(R.id.alarm_item_2, View.GONE)
                        setViewVisibility(R.id.alarm_item_3, View.GONE)

                        val count = minOf(3, alarmsArray.length())
                        for (i in 0 until count) {
                            val alarm = alarmsArray.getJSONObject(i)
                            val alarmTime = alarm.getString("time")
                            val alarmTitle = alarm.getString("title")
                            val alarmStatus = alarm.getString("status") // This is localized string like "Active"
                            val isActive = alarm.getBoolean("isActive")
                            
                            val statusColor = if (isActive) statusColorActive else secondaryTextColor
                            
                            // Helper to set item views
                            fun setItem(timeId: Int, titleId: Int, statusId: Int, containerId: Int) {
                                setViewVisibility(containerId, View.VISIBLE)
                                setTextViewText(timeId, alarmTime)
                                setTextViewText(titleId, alarmTitle)
                                setTextViewText(statusId, alarmStatus)
                                
                                setTextColor(timeId, primaryTextColor)
                                setTextColor(titleId, secondaryTextColor) // Title is secondary
                                setTextColor(statusId, statusColor)
                            }
                            
                            when (i) {
                                0 -> setItem(R.id.alarm_item_1_time, R.id.alarm_item_1_title, R.id.alarm_item_1_status, R.id.alarm_item_1)
                                1 -> setItem(R.id.alarm_item_2_time, R.id.alarm_item_2_title, R.id.alarm_item_2_status, R.id.alarm_item_2)
                                2 -> setItem(R.id.alarm_item_3_time, R.id.alarm_item_3_title, R.id.alarm_item_3_status, R.id.alarm_item_3)
                            }
                        }
                    }
                } catch (e: Exception) {
                    setViewVisibility(R.id.empty_message, View.VISIBLE)
                    setTextViewText(R.id.empty_message, emptyMessage)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
