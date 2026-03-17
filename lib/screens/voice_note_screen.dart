import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../core/utils/extensions.dart';

class VoiceNoteScreen extends StatefulWidget {
  final String? existingPath;

  const VoiceNoteScreen({super.key, this.existingPath});

  @override
  State<VoiceNoteScreen> createState() => _VoiceNoteScreenState();
}

class _VoiceNoteScreenState extends State<VoiceNoteScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  bool _isRecording = false;
  bool _isPaused = false;
  String? _recordingPath;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _recordingPath = widget.existingPath;
  }

  void _returnResult() {
    Navigator.pop(context, {
      'path': _recordingPath!,
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hintColor = isDark ? Colors.white38 : Colors.black38;
    final fgColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.voiceNote),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          if (_recordingPath != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _returnResult,
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              TextField(
                controller: _titleController,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: fgColor,
                ),
                decoration: InputDecoration(
                  hintText: l10n.noteTitle,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  hintStyle: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: hintColor,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 12),
              Divider(color: fgColor.withAlpha(30)),
              const SizedBox(height: 12),

              // Description field
              TextField(
                controller: _descController,
                style: theme.textTheme.bodyLarge?.copyWith(color: fgColor),
                decoration: InputDecoration(
                  hintText: l10n.noteContent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: hintColor,
                  ),
                ),
                maxLines: 4,
                textInputAction: TextInputAction.done,
              ),

              const SizedBox(height: 40),

              // Recording area
              Center(
                child: Column(
                  children: [
                    // Recording status badge
                    if (_isRecording) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.fiber_manual_record,
                              color: Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.recording.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Timer
                    Text(
                      _formatDuration(_duration),
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w200,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Controls
                    if (!_isRecording && _recordingPath == null)
                      GestureDetector(
                        onTap: _startRecording,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withAlpha(102),
                                blurRadius: 12,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      )
                    else if (_isRecording)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _togglePause,
                            icon: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.withAlpha(51),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPaused
                                    ? Icons.play_arrow_rounded
                                    : Icons.pause_rounded,
                                size: 32,
                              ),
                            ),
                            iconSize: 56,
                          ),
                          const SizedBox(width: 32),
                          GestureDetector(
                            onTap: _stopRecording,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(26),
                                border:
                                    Border.all(color: Colors.red, width: 3),
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
                      Column(
                        children: [
                          Text(
                            l10n.voiceNoteAttached,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: () =>
                                    setState(() => _recordingPath = null),
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                label: Text(
                                  l10n.delete,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: _returnResult,
                                icon: const Icon(Icons.check),
                                label: Text(l10n.save),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      theme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ses kaydı için mikrofon izni gereklidir.'),
          ),
        );
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      if (!mounted) return;

      setState(() {
        _isRecording = true;
        _recordingPath = path;
        _duration = Duration.zero;
      });

      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stop();
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
    } catch (_) {}
  }

  Future<void> _togglePause() async {
    try {
      if (_isPaused) {
        await _recorder.resume();
      } else {
        await _recorder.pause();
      }
      setState(() => _isPaused = !_isPaused);
    } catch (_) {}
  }

  void _startTimer() {
    Future.doWhile(() async {
      if (!_isRecording) return false;
      if (!_isPaused) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted && _isRecording) {
          setState(() => _duration += const Duration(seconds: 1));
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
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
    _titleController.dispose();
    _descController.dispose();
    _recorder.dispose();
    super.dispose();
  }
}
