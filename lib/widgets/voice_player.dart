import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class VoicePlayer extends StatefulWidget {
  final String path;
  final bool isDark;
  final VoidCallback? onDelete;

  const VoicePlayer({
    super.key,
    required this.path,
    required this.isDark,
    this.onDelete,
  });

  @override
  State<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<VoicePlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _audioPlayer = AudioPlayer();

    // Set up listeners
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
          _isLoading = false;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _isPlaying = false;
        });
      }
    });

    // Try to get duration immediately
    try {
      await _audioPlayer.setSourceDeviceFile(widget.path);
      // Small delay to allow duration to load
      await Future.delayed(const Duration(milliseconds: 200));
      final d = await _audioPlayer.getDuration();
      if (d != null && mounted) {
        setState(() {
          _duration = d;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading audio: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = widget.isDark
        ? Colors.blueAccent[100]!
        : Colors.blueAccent;
    final bgColor = widget.isDark
        ? Colors.blue.withAlpha(50)
        : Colors.blue.withAlpha(30);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: baseColor.withAlpha(100)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: baseColor,
                    ),
                  )
                : Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
            color: baseColor,
            onPressed: _isLoading
                ? null
                : () async {
                    if (_isPlaying) {
                      await _audioPlayer.pause();
                    } else {
                      // If paused, resume. If stopped/completed, play from start or current position.
                      if (_position > Duration.zero && _position < _duration) {
                        await _audioPlayer.resume();
                      } else {
                        // Re-set source and play to ensure it works after completion
                        await _audioPlayer.play(DeviceFileSource(widget.path));
                      }
                    }
                  },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: baseColor,
                    inactiveTrackColor: baseColor.withAlpha(70),
                    thumbColor: baseColor,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    min: 0,
                    max: _duration.inMilliseconds.toDouble() > 0
                        ? _duration.inMilliseconds.toDouble()
                        : 1.0,
                    value: _position.inMilliseconds.toDouble().clamp(
                      0,
                      _duration.inMilliseconds.toDouble() > 0
                          ? _duration.inMilliseconds.toDouble()
                          : 1.0,
                    ),
                    onChanged: _isLoading
                        ? null
                        : (value) async {
                            final position = Duration(
                              milliseconds: value.toInt(),
                            );
                            await _audioPlayer.seek(position);
                          },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: Colors.redAccent,
              onPressed: () {
                _audioPlayer.stop(); // Stop before delete
                widget.onDelete!();
              },
            ),
        ],
      ),
    );
  }
}
