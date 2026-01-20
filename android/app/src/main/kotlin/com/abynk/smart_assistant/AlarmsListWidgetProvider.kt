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
                
                setTextViewText(R.id.widget_title, title)
                
                try {
                    val alarmsArray = JSONArray(alarmsDataJson)
                    
                    if (alarmsArray.length() == 0) {
                        // Show empty message
                        setViewVisibility(R.id.empty_message, View.VISIBLE)
                        setTextViewText(R.id.empty_message, emptyMessage)
                        setViewVisibility(R.id.alarm_item_1, View.GONE)
                        setViewVisibility(R.id.alarm_item_2, View.GONE)
                        setViewVisibility(R.id.alarm_item_3, View.GONE)
                    } else {
                        // Hide empty message
                        setViewVisibility(R.id.empty_message, View.GONE)
                        
                        // Display up to 3 alarms
                        for (i in 0 until minOf(3, alarmsArray.length())) {
                            val alarm = alarmsArray.getJSONObject(i)
                            val alarmTime = alarm.getString("time")
                            val alarmTitle = alarm.getString("title")
                            val alarmStatus = alarm.getString("status")
                            val isActive = alarm.getBoolean("isActive")
                            
                            val statusColor = if (isActive) Color.parseColor("#4CAF50") else Color.parseColor("#999999")
                            
                            when (i) {
                                0 -> {
                                    setViewVisibility(R.id.alarm_item_1, View.VISIBLE)
                                    setTextViewText(R.id.alarm_item_1_time, alarmTime)
                                    setTextViewText(R.id.alarm_item_1_title, alarmTitle)
                                    setTextViewText(R.id.alarm_item_1_status, alarmStatus)
                                    setTextColor(R.id.alarm_item_1_status, statusColor)
                                }
                                1 -> {
                                    setViewVisibility(R.id.alarm_item_2, View.VISIBLE)
                                    setTextViewText(R.id.alarm_item_2_time, alarmTime)
                                    setTextViewText(R.id.alarm_item_2_title, alarmTitle)
                                    setTextViewText(R.id.alarm_item_2_status, alarmStatus)
                                    setTextColor(R.id.alarm_item_2_status, statusColor)
                                }
                                2 -> {
                                    setViewVisibility(R.id.alarm_item_3, View.VISIBLE)
                                    setTextViewText(R.id.alarm_item_3_time, alarmTime)
                                    setTextViewText(R.id.alarm_item_3_title, alarmTitle)
                                    setTextViewText(R.id.alarm_item_3_status, alarmStatus)
                                    setTextColor(R.id.alarm_item_3_status, statusColor)
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
