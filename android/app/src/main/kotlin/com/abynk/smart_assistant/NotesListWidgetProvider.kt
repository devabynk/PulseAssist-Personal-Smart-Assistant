package com.abynk.smart_assistant

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

class NotesListWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.notes_list_widget).apply {
                val title = widgetData.getString("title", "My Notes") ?: "My Notes"
                val notesDataJson = widgetData.getString("notes_data", "[]") ?: "[]"
                val emptyMessage = widgetData.getString("empty_message", "No notes yet") ?: "No notes yet"
                
                setTextViewText(R.id.widget_title, title)
                
                try {
                    val notesArray = JSONArray(notesDataJson)
                    
                    if (notesArray.length() == 0) {
                        // Show empty message
                        setViewVisibility(R.id.empty_message, View.VISIBLE)
                        setTextViewText(R.id.empty_message, emptyMessage)
                        setViewVisibility(R.id.note_item_1_title, View.GONE)
                        setViewVisibility(R.id.note_item_1_content, View.GONE)
                        setViewVisibility(R.id.note_item_2_title, View.GONE)
                        setViewVisibility(R.id.note_item_2_content, View.GONE)
                        setViewVisibility(R.id.note_item_3_title, View.GONE)
                        setViewVisibility(R.id.note_item_3_content, View.GONE)
                    } else {
                        // Hide empty message
                        setViewVisibility(R.id.empty_message, View.GONE)
                        
                        // Display up to 3 notes
                        for (i in 0 until minOf(3, notesArray.length())) {
                            val note = notesArray.getJSONObject(i)
                            val noteTitle = note.getString("title")
                            val noteContent = note.getString("content")
                            
                            when (i) {
                                0 -> {
                                    setViewVisibility(R.id.note_item_1_title, View.VISIBLE)
                                    setViewVisibility(R.id.note_item_1_content, View.VISIBLE)
                                    setTextViewText(R.id.note_item_1_title, noteTitle)
                                    setTextViewText(R.id.note_item_1_content, noteContent)
                                }
                                1 -> {
                                    setViewVisibility(R.id.note_item_2_title, View.VISIBLE)
                                    setViewVisibility(R.id.note_item_2_content, View.VISIBLE)
                                    setTextViewText(R.id.note_item_2_title, noteTitle)
                                    setTextViewText(R.id.note_item_2_content, noteContent)
                                }
                                2 -> {
                                    setViewVisibility(R.id.note_item_3_title, View.VISIBLE)
                                    setViewVisibility(R.id.note_item_3_content, View.VISIBLE)
                                    setTextViewText(R.id.note_item_3_title, noteTitle)
                                    setTextViewText(R.id.note_item_3_content, noteContent)
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
