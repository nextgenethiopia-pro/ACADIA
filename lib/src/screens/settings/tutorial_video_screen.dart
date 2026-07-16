import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:acadia/src/core/constants/colors.dart';

class TutorialVideoScreen extends StatefulWidget {
  const TutorialVideoScreen({super.key});

  @override
  State<TutorialVideoScreen> createState() => _TutorialVideoScreenState();
}

class _TutorialVideoScreenState extends State<TutorialVideoScreen> {
  String _selectedLanguage = 'English';
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _showControls = true;
  Timer? _controlsTimer;

  // Local asset videos
  final Map<String, String> _videoAssets = {
    'English': 'assets/videos/tutorial_english.mp4',
    'Amharic': 'assets/videos/tutorial_amharic.mp4',
    'Afaan Oromoo': 'assets/videos/tutorial_oromo.mp4',
  };

  // Video descriptions
  final Map<String, String> _videoDescriptions = {
    'English': 'Learn how to browse subjects, purchase packages, submit payments, download content for offline use, and track your progress.',
    'Amharic': 'ትምህርቶችን እንዴት ማሰስ፣ ፓኬጆችን መግዛት፣ ክፍያ ማስረከብ፣ ይዘትን ለኦፍላይን አጠቃቀም ማውረድ እና እድገትዎን መከታተል እንደሚችሉ ይማሩ።',
    'Afaan Oromoo': 'Akka itti barnoota barbaaddan, paakeejii bittan, kaffaltii galmeessitan, qabiyyee offilaayinii fayyadamtuuf buufattanii fi akka itti dammaqina keessan hordoftan baradhaa.',
  };

  @override
  void initState() {
    super.initState();
    _loadVideo(_selectedLanguage);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controlsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadVideo(String language) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    setState(() {
      _isLoading = true;
      _isInitialized = false;
      _showControls = true;
    });

    final assetPath = _videoAssets[language];
    if (assetPath == null) return;

    try {
      _controller = VideoPlayerController.asset(assetPath)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _isLoading = false;
            });
            _controller!.play();
            _startControlsTimer();
          }
        }).catchError((error) {
          debugPrint('Error loading video: $error');
          if (mounted) setState(() => _isLoading = false);
        });
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller != null && _controller!.value.isPlaying) {
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

  @override
  Widget build(BuildContext context) {
    final description = _videoDescriptions[_selectedLanguage] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Use ACADIA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Language Selection Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.05), AppColors.secondary.withOpacity(0.02)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.language, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('Choose your preferred language for the tutorial',
                              style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        underline: const SizedBox(),
                        items: ['English', 'Amharic', 'Afaan Oromoo']
                            .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedLanguage = value);
                            _loadVideo(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            description,
                            style: TextStyle(color: Colors.blue[700], fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Video Player
          Expanded(
            child: GestureDetector(
              onTap: _toggleControls,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _isLoading
                      ? Container(
                          color: Colors.black,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 16),
                                Text('Loading video...', style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                        )
                      : _isInitialized && _controller != null
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                AspectRatio(
                                  aspectRatio: _controller!.value.aspectRatio,
                                  child: VideoPlayer(_controller!),
                                ),
                                // Play/Pause overlay
                                if (_showControls && !_controller!.value.isPlaying)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _controller!.play());
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
                                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                                    ),
                                  ),
                                // Pause overlay when paused and controls visible
                                if (_showControls && _controller!.value.isPlaying)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _controller!.pause());
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
                                      child: const Icon(Icons.pause, color: Colors.white, size: 36),
                                    ),
                                  ),
                              ],
                            )
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.video_library, size: 80, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Tutorial video not available',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Please add MP4 files to assets/videos/',
                                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      onPressed: () => context.pop(),
                                      icon: const Icon(Icons.arrow_back),
                                      label: const Text('Go Back'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                ),
              ),
            ),
          ),

          // Video Controls (bottom bar)
          if (_isInitialized && _controller != null)
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Progress bar
                      VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: AppColors.primary,
                          bufferedColor: AppColors.primary.withOpacity(0.3),
                          backgroundColor: Colors.grey[300]!,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(_controller!.value.position),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          Text(_formatDuration(_controller!.value.duration),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10, size: 28),
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
                          const SizedBox(width: 20),
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
                          const SizedBox(width: 20),
                          IconButton(
                            icon: const Icon(Icons.forward_10, size: 28),
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
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
}