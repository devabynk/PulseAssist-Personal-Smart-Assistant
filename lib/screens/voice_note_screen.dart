import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:smart_assistant/providers/settings_provider.dart';

class VoiceNoteScreen extends StatefulWidget {
  final String? existingPath;
  
  const VoiceNoteScreen({super.key, this.existingPath});

  @override
  State<VoiceNoteScreen> createState() => _VoiceNoteScreenState();
}

class _VoiceNoteScreenState extends State<VoiceNoteScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  String? _recordingPath;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _recordingPath = widget.existingPath;
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Provider.of<SettingsProvider>(context).locale.languageCode == 'tr';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTr ? 'Sesli Not' : 'Voice Note'),
        actions: [
          if (_recordingPath != null)
            IconButton(
              icon: Icon(Icons.check),
              onPressed: () => Navigator.pop(context, _recordingPath),
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Recording Status
            if (_isRecording) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Text(
                      _isPaused 
                          ? (isTr ? 'DURAKLATILDI' : 'PAUSED') 
                          : (isTr ? 'KAYDEDİLİYOR' : 'RECORDING'),
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
            ],
            
            // Timer
            Text(
              _formatDuration(_duration),
              style: TextStyle(
                fontSize: 64, 
                fontWeight: FontWeight.w200,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            
            SizedBox(height: 64),
            
            // Controls
            if (!_isRecording && _recordingPath == null)
              // Initial State: Start Button
              GestureDetector(
                onTap: _startRecording,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 12, spreadRadius: 4)
                    ],
                  ),
                  child: Icon(Icons.mic, color: Colors.white, size: 36),
                ),
              )
            else if (_isRecording)
              // Recording State: Pause & Stop
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   IconButton(
                    onPressed: _togglePause,
                    icon: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 32),
                    ),
                    iconSize: 56,
                  ),
                  SizedBox(width: 32),
                  GestureDetector(
                    onTap: _stopRecording,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.red, width: 3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else if (_recordingPath != null)
              // Review State
              Column(
                children: [
                  Text(isTr ? 'Kayıt Yapıldı' : "Recording Saved", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(() => _recordingPath = null),
                        icon: Icon(Icons.delete, color: Colors.red),
                        label: Text(isTr ? 'Sil' : "Discard", style: TextStyle(color: Colors.red)),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, _recordingPath),
                        icon: Icon(Icons.check),
                        label: Text(isTr ? 'Kaydı Kullan' : "Use Recording"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    try {
      // Check and request permission
      if (!await _recorder.hasPermission()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Microphone permission is required to record voice notes'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                // Open app settings
              },
            ),
          ),
        );
        return;
      }
      
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      
      setState(() {
        _isRecording = true;
        _recordingPath = path;
        _duration = Duration.zero;
      });
      
      // Start duration timer
      _startTimer();
    } catch (e) {
      debugPrint('Error starting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stop();
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _togglePause() async {
    try {
      if (_isPaused) {
        await _recorder.resume();
      } else {
        await _recorder.pause();
      }
      setState(() => _isPaused = !_isPaused);
    } catch (e) {
      debugPrint('Error toggling pause: $e');
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      if (!_isRecording) return false;
      if (!_isPaused) {
        await Future.delayed(Duration(seconds: 1));
        if (mounted && _isRecording) {
          setState(() => _duration += Duration(seconds: 1));
        }
      } else {
        await Future.delayed(Duration(milliseconds: 100));
      }
      return _isRecording;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }
}
