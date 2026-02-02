package com.abynk.smart_assistant

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WeatherWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.weather_widget).apply {
                val city = widgetData.getString("weather_city", "--")
                val temp = widgetData.getString("weather_temp", "--")
                val condition = widgetData.getString("weather_condition", "--")
                val updated = widgetData.getString("weather_updated", "")
                val isTransparent = widgetData.getBoolean("widget_theme_transparent", false)
                
                setTextViewText(R.id.widget_city, city)
                setTextViewText(R.id.widget_temp, temp)
                setTextViewText(R.id.widget_condition, condition)
                setTextViewText(R.id.widget_updated, updated)
                
                if (isTransparent) {
                    setInt(R.id.widget_background, "setBackgroundResource", R.drawable.widget_background_transparent)
                } else {
                    setInt(R.id.widget_background, "setBackgroundResource", R.drawable.widget_background_solid)
                }
                
                // Use system color resources that adapt to dark/light mode
                val textPrimary = context.getColor(R.color.widget_text_primary)
                val textSecondary = context.getColor(R.color.widget_text_secondary)
                val accentColor = context.getColor(R.color.widget_accent)
                
                setTextColor(R.id.widget_city, textPrimary)
                setTextColor(R.id.widget_temp, accentColor)
                setTextColor(R.id.widget_condition, textSecondary)
                setTextColor(R.id.widget_updated, textSecondary)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
