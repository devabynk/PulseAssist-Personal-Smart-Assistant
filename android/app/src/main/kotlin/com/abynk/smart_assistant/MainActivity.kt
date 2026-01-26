package com.abynk.smart_assistant

import android.media.RingtoneManager
import android.media.Ringtone
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.abynk.smart_assistant/ringtones"
    private var currentRingtone: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getRingtones" -> {
                    val ringtones = getRingtones()
                    result.success(ringtones)
                }
                "playRingtone" -> {
                    val uri = call.argument<String>("uri")
                    if (uri != null) {
                        playRingtone(uri)
                        result.success(null)
                    } else {
                        result.error("INVALID_URI", "Uri cannot be null", null)
                    }
                }
                "stopRingtone" -> {
                    stopRingtone()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getRingtones(): List<Map<String, Any>> {
        val ringtones = mutableListOf<Map<String, Any>>()
        val manager = RingtoneManager(this)
        manager.setType(RingtoneManager.TYPE_ALARM)
        
        val cursor = manager.cursor
        try {
            while (cursor.moveToNext()) {
                val title = cursor.getString(RingtoneManager.TITLE_COLUMN_INDEX)
                val uri = cursor.getString(RingtoneManager.URI_COLUMN_INDEX) + "/" + cursor.getString(RingtoneManager.ID_COLUMN_INDEX)
                
                ringtones.add(mapOf(
                    "title" to title,
                    "uri" to uri,
                    "isDefault" to false
                ))
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        // Add default alarm sound manually if not present? 
        // Or just let user pick from list.
        // Let's add "Default" generic logic if list is empty?
        
        return ringtones
    }

    private fun playRingtone(uriString: String) {
        stopRingtone()
        try {
            val uri = Uri.parse(uriString)
            currentRingtone = RingtoneManager.getRingtone(applicationContext, uri)
            currentRingtone?.play()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopRingtone() {
        currentRingtone?.let {
            if (it.isPlaying) {
                it.stop()
            }
        }
        currentRingtone = null
    }
}
