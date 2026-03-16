package com.abynk.smart_assistant

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class NoteWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.note_widget).apply {
                val title = widgetData.getString("title", "Smart Notes")
                val content = widgetData.getString("content", "No recent notes")
                val isTransparent = widgetData.getBoolean("widget_theme_transparent", false)

                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_content, content)

                val primaryTextColor = context.getColor(R.color.widget_text_primary)
                val secondaryTextColor = context.getColor(R.color.widget_text_secondary)

                if (isTransparent) {
                    setInt(R.id.widget_background, "setBackgroundResource", R.drawable.widget_background_transparent)
                } else {
                    setInt(R.id.widget_background, "setBackgroundResource", R.drawable.widget_background_solid)
                }

                setTextColor(R.id.widget_title, primaryTextColor)
                setTextColor(R.id.widget_content, secondaryTextColor)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
