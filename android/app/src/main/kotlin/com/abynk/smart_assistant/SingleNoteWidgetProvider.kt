package com.abynk.smart_assistant

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class SingleNoteWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.single_note_widget).apply {
                val titleLabel = widgetData.getString("title", "Latest Note") ?: "Latest Note"
                val noteTitle = widgetData.getString("note_title", "No notes yet") ?: "No notes yet"
                val noteContent = widgetData.getString("note_content", "Tap to open") ?: "Tap to open"
                val noteColor = widgetData.getString("note_color", "#FFB74D") ?: "#FFB74D"
                val noteUpdated = widgetData.getString("note_updated", "") ?: ""
                
                setTextViewText(R.id.widget_title_label, titleLabel)
                setTextViewText(R.id.note_title, noteTitle)
                setTextViewText(R.id.note_content, noteContent)
                setTextViewText(R.id.note_updated, noteUpdated)
                
                // Set background color
                try {
                    val color = Color.parseColor(noteColor)
                    setInt(R.id.widget_container, "setBackgroundColor", color)
                } catch (e: Exception) {
                    // Use default color if parsing fails
                    setInt(R.id.widget_container, "setBackgroundColor", Color.parseColor("#FFB74D"))
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
