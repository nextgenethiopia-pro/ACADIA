import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:acadia/src/core/services/offline_database.dart';
import 'package:acadia/src/core/constants/colors.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String contentId;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.contentId,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  bool _isCompleted = false;
  String _videoTitle = '';
  String _videoDescription = '';
  bool _showControls = true;
  Timer? _controlsTimer;

  // Speed control
  double _playbackSpeed = 1.0;
  final List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  bool _showSpeedMenu = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controlsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    setState(() => _isLoading = true);
    try {
      final offlineDb = OfflineDatabase.instance;
      final db = await offlineDb.database;

      final result = await db.query(
        'offline_content',
        where: 'content_id = ?',
        whereArgs: [widget.contentId],
      );

      if (result.isNotEmpty) {
        final data = result.first;
        final filePath = data['local_path'] as String;
        final file = File(filePath);

        if (await file.exists()) {
          _controller = VideoPlayerController.file(file)
            ..initialize().then((_) {
              if (mounted) {
                setState(() {
                  _isInitialized = true;
                  _isLoading = false;
                  _videoTitle = data['title']?.toString() ?? widget.title;
                  _videoDescription = data['description']?.toString() ?? '';
                  _isCompleted = data['is_completed'] == 1;
                });
                _controller!.play();
                _startControlsTimer();
              }
            }).catchError((error) {
              debugPrint('Error initializing video: $error');
              if (mounted) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error playing video'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            });

          // Listen for completion
          _controller!.addListener(() {
            if (_controller!.value.position >= _controller!.value.duration &&
                _controller!.value.duration > Duration.zero) {
              _onVideoComplete();
            }
          });

          return;
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video file not found. Please download it first.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading video: $e');
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller!.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = true;
    });
    _startControlsTimer();
  }

  void _setPlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
      _showSpeedMenu = false;
    });
    _controller?.setPlaybackSpeed(speed);
  }

  void _toggleSpeedMenu() {
    setState(() => _showSpeedMenu = !_showSpeedMenu);
  }

  void _onVideoComplete() async {
    if (!_isCompleted) {
      try {
        final offlineDb = OfflineDatabase.instance;
        final db = await offlineDb.database;
        await db.update(
          'offline_content',
          {'is_completed': 1},
          where: 'content_id = ?',
          whereArgs: [widget.contentId],
        );

        if (mounted) {
          setState(() => _isCompleted = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video completed!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error marking video complete: $e');
      }
    }
  }

  Future<void> _markAsCompleted() async {
    try {
      final offlineDb = OfflineDatabase.instance;
      final db = await offlineDb.database;
      await db.update(
        'offline_content',
        {'is_completed': 1},
        where: 'content_id = ?',
        whereArgs: [widget.contentId],
      );

      if (mounted) {
        setState(() => _isCompleted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked as completed!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking as completed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark as completed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Colors.black,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              const Text(
                'Video not available',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Download the video first to play offline',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: SafeArea(
          child: Column(
            children: [
              // Header (visible based on controls)
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _videoTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_videoDescription.isNotEmpty)
                              Text(
                                _videoDescription,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      // Speed control button
                      Stack(
                        children: [
                          TextButton.icon(
                            onPressed: _toggleSpeedMenu,
                            icon: const Icon(Icons.speed, color: Colors.white, size: 20),
                            label: Text(
                              '${_playbackSpeed}x',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (_showSpeedMenu)
                            Positioned(
                              top: 40,
                              right: 0,
                              child: Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: _speedOptions.map((speed) {
                                      final isSelected = (_playbackSpeed == speed);
                                      return InkWell(
                                        onTap: () => _setPlaybackSpeed(speed),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (isSelected)
                                                const Icon(
                                                  Icons.check,
                                                  color: AppColors.primary,
                                                  size: 18,
                                                )
                                              else
                                                const SizedBox(width: 18),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${speed}x',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Completed',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Video Player
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_controller!),
                        
                        // Play/Pause overlay (visible when paused or controls shown)
                        if (!_controller!.value.isPlaying || _showControls)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _controller!.value.isPlaying
                                    ? _controller!.pause()
                                    : _controller!.play();
                              });
                              _startControlsTimer();
                            },
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24, width: 2),
                              ),
                              child: Icon(
                                _controller!.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Controls (bottom bar)
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.black.withOpacity(0.9),
                  child: Column(
                    children: [
                      // Progress bar
                      VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: AppColors.primary,
                          bufferedColor: AppColors.primary.withOpacity(0.3),
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_controller!.value.position),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            _formatDuration(_controller!.value.duration),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Controls row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Rewind 10s
                          IconButton(
                            icon: const Icon(Icons.replay_10, color: Colors.white, size: 28),
                            onPressed: () {
                              final position = _controller!.value.position;
                              _controller!.seekTo(
                                position - const Duration(seconds: 10) < Duration.zero
                                    ? Duration.zero
                                    : position - const Duration(seconds: 10),
                              );
                              _startControlsTimer();
                            },
                          ),
                          const SizedBox(width: 16),

                          // Play/Pause
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 32,
                              ),
                              onPressed: () {
                                setState(() {
                                  _controller!.value.isPlaying
                                      ? _controller!.pause()
                                      : _controller!.play();
                                });
                                _startControlsTimer();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Forward 10s
                          IconButton(
                            icon: const Icon(Icons.forward_10, color: Colors.white, size: 28),
                            onPressed: () {
                              final position = _controller!.value.position;
                              final duration = _controller!.value.duration;
                              _controller!.seekTo(
                                position + const Duration(seconds: 10) > duration
                                    ? duration
                                    : position + const Duration(seconds: 10),
                              );
                              _startControlsTimer();
                            },
                          ),
                          const SizedBox(width: 16),

                          // Volume
                          IconButton(
                            icon: Icon(
                              _controller!.value.volume > 0
                                  ? Icons.volume_up
                                  : Icons.volume_off,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: () {
                              setState(() {
                                _controller!.setVolume(
                                  _controller!.value.volume > 0 ? 0.0 : 1.0,
                                );
                              });
                              _startControlsTimer();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Mark Complete button
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isCompleted ? null : _markAsCompleted,
                        icon: Icon(
                          _isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                          size: 18,
                        ),
                        label: Text(_isCompleted ? 'Completed' : 'Mark as Completed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCompleted ? Colors.green : Colors.grey[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}