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
                    // For transparent dark bg, text should be white
                    setTextColor(R.id.widget_city, android.graphics.Color.WHITE)
                    setTextColor(R.id.widget_temp, android.graphics.Color.WHITE)
                    setTextColor(R.id.widget_condition, android.graphics.Color.LTGRAY)
                    setTextColor(R.id.widget_updated, android.graphics.Color.LTGRAY)
                } else {
                    setInt(R.id.widget_background, "setBackgroundResource", R.drawable.widget_background_solid)
                    // For solid white bg, text should be black
                    setTextColor(R.id.widget_city, android.graphics.Color.BLACK)
                    setTextColor(R.id.widget_temp, android.graphics.Color.BLACK)
                    setTextColor(R.id.widget_condition, android.graphics.Color.DKGRAY)
                    setTextColor(R.id.widget_updated, android.graphics.Color.DKGRAY)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
