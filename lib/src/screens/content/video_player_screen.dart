import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:acadia/src/local_database/isar_service.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:acadia/src/core/services/download_manager.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String contentId;
  final String title;
  final String? videoUrl;

  const VideoPlayerScreen({
    super.key,
    required this.contentId,
    required this.title,
    this.videoUrl,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  final IsarService _isarService = IsarService.instance;
  late final DownloadManager _downloadManager = DownloadManager();

  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isCompleted = false;
  bool _showControls = true;
  Timer? _controlsTimer;

  bool _isDownloaded = false;
  bool _isDownloading = false;
  String? _localPath;
  double _downloadProgress = 0.0;
  bool _isFullscreen = false;

  // Audio / Volume
  double _volume = 1.0;
  bool _isMuted = false;

  // Speed control
  double _playbackSpeed = 1.0;
  final List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  bool _showSpeedMenu = false;

  // YouTube stream
  bool _isYouTube = false;
  late final WebViewController _webViewController;
  bool _isWebViewReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _detectVideoType();
    _loadVideo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // ALWAYS strictly restore portrait orientation and system UI mode on exit
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _controller?.dispose();
    _controlsTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _controlsTimer?.cancel();
      if (_controller != null && _controller!.value.isPlaying) {
        _controller!.pause();
        if (mounted) setState(() => _showControls = true);
      }
      if (_isYouTube && _isWebViewReady) {
        _webViewController.runJavaScript(
          "var v=document.querySelector('video'); if(v){v.pause();}",
        );
      }
    }
  }

  void _detectVideoType() {
    final url = widget.videoUrl?.toLowerCase() ?? '';
    _isYouTube = url.contains('youtube.com') || url.contains('youtu.be');

    if (_isYouTube && widget.videoUrl != null) {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (progress) {
              if (progress >= 100) {
                if (mounted) setState(() => _isWebViewReady = true);
              }
            },
            onPageFinished: (url) {
              if (mounted) setState(() => _isWebViewReady = true);
            },
            onWebResourceError: (error) {
              debugPrint('❌ YouTube stream error: ${error.description}');
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _errorMessage =
                      'Could not load this video stream. Check your connection and try again.';
                  _isLoading = false;
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.videoUrl!));
    }
  }

  Future<void> _loadVideo() async {
    if (_isYouTube) {
      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final downloadedContent = await _isarService.getDownloadedContentById(
          widget.contentId,
          user.uid,
        );

        if (downloadedContent?.contentPath != null) {
          final file = File(downloadedContent!.contentPath!);
          if (await file.exists() && await file.length() > 0) {
            _localPath = downloadedContent.contentPath;
            _isDownloaded = true;
            await _initializeController(File(_localPath!));
            return;
          }
        }
      }

      // If not stored locally, attempt online streaming if videoUrl is available
      final url = widget.videoUrl?.trim() ?? '';
      if (url.isNotEmpty && Uri.tryParse(url)?.hasScheme == true) {
        debugPrint('🌐 Streaming video from URL: $url');
        await _initializeControllerFromNetwork(url);
        return;
      }

      setState(() {
        _isDownloaded = false;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading video: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage =
            'Unable to play this video. It may be unavailable offline or the file could be damaged.';
      });
    }
  }

  Future<void> _initializeController(File file) async {
    _controller?.dispose();
    final controller = VideoPlayerController.file(file);
    _controller = controller;

    await controller.initialize();
    controller.addListener(_videoListener);

    if (mounted) {
      setState(() {
        _isInitialized = true;
        _isLoading = false;
        _hasError = false;
      });
      controller.play();
      _startControlsTimer();
    }
  }

  Future<void> _initializeControllerFromNetwork(String url) async {
    _controller?.dispose();
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;

    await controller.initialize();
    controller.addListener(_videoListener);

    if (mounted) {
      setState(() {
        _isInitialized = true;
        _isLoading = false;
        _hasError = false;
      });
      controller.play();
      _startControlsTimer();
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;
    if (_controller!.value.hasError) {
      debugPrint(
          '❌ Playback error: ${_controller!.value.errorDescription ?? 'unknown'}');
      setState(() {
        _hasError = true;
        _errorMessage =
            'Unable to play this video. It may be unavailable offline or the file could be damaged.';
      });
      return;
    }

    if (_controller!.value.isCompleted && !_isCompleted) {
      _onVideoComplete();
    }
    setState(() {});
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controller != null && _controller!.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      // ONLY the video player screen rotates to landscape
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      // Return to previous normal portrait state
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _setPlaybackSpeed(double speed) {
    _controller?.setPlaybackSpeed(speed);
    setState(() {
      _playbackSpeed = speed;
      _showSpeedMenu = false;
    });
  }

  void _toggleMute() {
    if (_controller == null) return;
    if (_isMuted) {
      _controller!.setVolume(_volume);
      setState(() => _isMuted = false);
    } else {
      _controller!.setVolume(0.0);
      setState(() => _isMuted = true);
    }
  }

  void _seekRelative(int seconds) {
    if (_controller == null || !_isInitialized) return;
    final current = _controller!.value.position;
    final total = _controller!.value.duration;
    var target = current + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (target > total) target = total;
    _controller!.seekTo(target);
    _startControlsTimer();
  }

  Future<void> _downloadMP4() async {
    final url = widget.videoUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No download URL available')),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final path = await _downloadManager.downloadContent(
        contentId: widget.contentId,
        title: widget.title,
        downloadUrl: url,
        contentType: 'video',
        fileFormat: 'mp4',
        subject: '',
        chapter: '',
        grade: '',
        onProgress: (progress) {
          if (mounted) setState(() => _downloadProgress = progress);
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
          _localPath = path;
        });
        await _initializeController(File(path));
      }
    } catch (e) {
      debugPrint('Error downloading video: $e');
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download failed. Please check your connection and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onVideoComplete() async {
    if (!_isCompleted) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _isarService.markContentCompleted(widget.contentId, user.uid);
        }
        if (mounted) setState(() => _isCompleted = true);
      } catch (e) {
        debugPrint('Error marking video complete: $e');
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // PopScope ensures hardware back button restores orientation and exits cleanly
    return PopScope(
      canPop: !_isFullscreen,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_isFullscreen) {
          _toggleFullscreen();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Loading ACADIA Video...', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      );
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_isYouTube) {
      return _buildYouTubePlayer();
    }

    if (!_isDownloaded && (_controller == null || !_isInitialized)) {
      return _buildNotDownloadedState();
    }

    return _buildModernVideoPlayer();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Video Playback Error',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to play this video.',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.portraitUp,
                      DeviceOrientation.portraitDown,
                    ]);
                    context.pop();
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  label: const Text('Go Back', style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _loadVideo,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotDownloadedState() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: _isDownloading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _downloadProgress > 0 ? _downloadProgress : null,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Downloading... ${(_downloadProgress * 100).toInt()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Saving securely to ACADIA local storage',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_download_outlined, color: AppColors.primary, size: 64),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Download this lesson video for uninterrupted offline study.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _downloadMP4,
                      icon: const Icon(Icons.download),
                      label: const Text('Download for Offline Study'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildYouTubePlayer() {
    return Column(
      children: [
        AppBar(
          title: Text(widget.title, style: const TextStyle(fontSize: 16)),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
            onPressed: () {
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
                DeviceOrientation.portraitDown,
              ]);
              context.pop();
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white),
              onPressed: _toggleFullscreen,
            ),
          ],
        ),
        Expanded(
          child: _isWebViewReady
              ? WebViewWidget(controller: _webViewController)
              : const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),
        ),
      ],
    );
  }

  Widget _buildModernVideoPlayer() {
    final controller = _controller!;
    final isPlaying = controller.value.isPlaying;
    final isBuffering = controller.value.isBuffering;
    final position = controller.value.position;
    final duration = controller.value.duration;

    return GestureDetector(
      onTap: _toggleControls,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Layer
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio > 0 ? controller.value.aspectRatio : 16 / 9,
              child: VideoPlayer(controller),
            ),
          ),

          // Buffering Indicator Overlay
          if (isBuffering)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
            ),

          // Overlay Controls (Google/Files modern styling with ACADIA Branding)
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: Container(
              color: Colors.black45,
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () {
                              if (_isFullscreen) {
                                _toggleFullscreen();
                              } else {
                                SystemChrome.setPreferredOrientations([
                                  DeviceOrientation.portraitUp,
                                  DeviceOrientation.portraitDown,
                                ]);
                                context.pop();
                              }
                            },
                          ),
                          const SizedBox(width: 4),
                          // ACADIA Branding Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ACADIA',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                          // Playback Speed Button
                          TextButton(
                            onPressed: () => setState(() => _showSpeedMenu = !_showSpeedMenu),
                            child: Text(
                              '${_playbackSpeed}x',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Center Transport Controls (Rewind 10s, Play/Pause, Forward 10s)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 40,
                          icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                          onPressed: () => _seekRelative(-10),
                        ),
                        const SizedBox(width: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            iconSize: 52,
                            icon: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                isPlaying ? controller.pause() : controller.play();
                              });
                              _startControlsTimer();
                            },
                          ),
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          iconSize: 40,
                          icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                          onPressed: () => _seekRelative(10),
                        ),
                      ],
                    ),

                    // Bottom Bar (Seek Bar, Time Display, Volume, Fullscreen)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VideoProgressIndicator(
                            controller,
                            allowScrubbing: true,
                            colors: VideoProgressColors(
                              playedColor: AppColors.primary,
                              bufferedColor: Colors.white30,
                              backgroundColor: Colors.white12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              Row(
                                children: [
                                  // Volume toggle
                                  IconButton(
                                    icon: Icon(
                                      _isMuted || _volume == 0
                                          ? Icons.volume_off_rounded
                                          : _volume < 0.5
                                              ? Icons.volume_down_rounded
                                              : Icons.volume_up_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: _toggleMute,
                                  ),
                                  // Fullscreen toggle
                                  IconButton(
                                    icon: Icon(
                                      _isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    onPressed: _toggleFullscreen,
                                    tooltip: _isFullscreen ? 'Exit Fullscreen' : 'Fullscreen',
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

          // Speed Selection Popup Menu
          if (_showSpeedMenu)
            Positioned(
              top: 56,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _speedOptions.map((speed) {
                      final isSelected = _playbackSpeed == speed;
                      return ListTile(
                        dense: true,
                        title: Text(
                          '${speed}x',
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary, size: 18) : null,
                        onTap: () => _setPlaybackSpeed(speed),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}