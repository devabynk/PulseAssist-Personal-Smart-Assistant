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
                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_content, content)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
