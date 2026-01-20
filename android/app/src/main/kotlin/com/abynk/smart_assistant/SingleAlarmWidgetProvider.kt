package com.abynk.smart_assistant

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class SingleAlarmWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.single_alarm_widget).apply {
                val titleLabel = widgetData.getString("title", "Next Alarm") ?: "Next Alarm"
                val alarmTitle = widgetData.getString("alarm_title", "No alarms set") ?: "No alarms set"
                val alarmTime = widgetData.getString("alarm_time", "--:--") ?: "--:--"
                val alarmStatus = widgetData.getString("alarm_status", "") ?: ""
                val alarmIn = widgetData.getString("alarm_in", "") ?: ""
                
                setTextViewText(R.id.widget_title_label, titleLabel)
                setTextViewText(R.id.alarm_title, alarmTitle)
                setTextViewText(R.id.alarm_time, alarmTime)
                setTextViewText(R.id.alarm_status, alarmStatus)
                setTextViewText(R.id.alarm_in, alarmIn)
                
                // Hide status badge if empty
                if (alarmStatus.isEmpty()) {
                    setViewVisibility(R.id.alarm_status, View.GONE)
                } else {
                    setViewVisibility(R.id.alarm_status, View.VISIBLE)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
