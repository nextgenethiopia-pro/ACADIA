import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import '../../core/constants/colors.dart';
import '../../widgets/common/gradient_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Map<String, dynamic> _welcomeContent = {};
  String? _welcomeImageUrl;
  bool _isLoading = true;
  Timer? _slideTimer;
  bool _showTutorial = false;
  int _tutorialStep = 0;
  bool _showVideoTutorial = false;
  String _selectedLanguage = 'English';
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  // Local tutorial videos
  final Map<String, String> _videoAssets = {
    'English': 'assets/videos/tutorial_english.mp4',
    'Amharic': 'assets/videos/tutorial_amharic.mp4',
    'Afaan Oromoo': 'assets/videos/tutorial_oromo.mp4',
  };

  @override
  void initState() {
    super.initState();
    _loadWelcomeContent();
  }

  void _startAutoSlide() {
    _slideTimer?.cancel();
    _slideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_slides.length > 1 && mounted) {
        final nextPage = (_currentPage + 1) % _slides.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadWelcomeContent() async {
    try {
      final firebaseService = FirebaseService();
      final settings = await firebaseService.getAppSettings();

      if (settings != null && settings['welcome_content'] != null) {
        if (mounted) {
          setState(() {
            _welcomeContent = Map<String, dynamic>.from(settings['welcome_content']);
            _welcomeImageUrl = settings['welcome_image']?.toString();
            _isLoading = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoSlide());
        }
      } else {
        if (mounted) {
          setState(() {
            _welcomeContent = {
              'slides': [
                {'image': 'assets/images/class_learning.jpg', 'title': 'Learn Anywhere'},
                {'image': 'assets/images/students_pc.jpg', 'title': 'Digital Learning'},
                {'image': 'assets/images/female_students.jpg', 'title': 'Made for Ethiopia'},
              ],
              'main_title': 'Empowering Ethiopian Students Through Digital Education',
              'subtitle': 'የኢትዮጵያ ተማሪዎችን በዲጂታል ትምህርት ማብቃት',
              'button_text': 'GET STARTED',
            };
            _isLoading = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoSlide());
        }
      }
    } catch (e) {
      debugPrint('Error loading welcome content: $e');
      // Continue with default content if Firestore fails
      if (mounted) {
        setState(() {
          _welcomeContent = {
            'slides': [
              {'image': 'assets/images/class_learning.jpg', 'title': 'Learn Anywhere'},
              {'image': 'assets/images/students_pc.jpg', 'title': 'Digital Learning'},
              {'image': 'assets/images/female_students.jpg', 'title': 'Made for Ethiopia'},
            ],
            'main_title': 'Empowering Ethiopian Students Through Digital Education',
            'subtitle': 'የኢትዮጵያ ተማሪዎችን በዲጂታል ትምህርት ማብቃት',
            'button_text': 'GET STARTED',
          };
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoSlide());
      }
    }
  }

  List<Map<String, dynamic>> get _slides {
    final slides = _welcomeContent['slides'];
    List<Map<String, dynamic>> slideList = [];

    if (_welcomeImageUrl != null) {
      slideList.add({
        'image': _welcomeImageUrl,
        'title': _welcomeContent['main_title'] ?? 'Welcome to ACADIA',
        'is_network': true,
      });
    }

    if (slides is List) {
      slideList.addAll(List<Map<String, dynamic>>.from(slides));
    }

    if (slideList.isEmpty) {
      slideList = [
        {'image': null, 'title': 'Learn Anywhere'},
        {'image': null, 'title': 'Achieve Your Dreams'},
        {'image': null, 'title': 'Made for Ethiopia'},
      ];
    }

    return slideList;
  }

  List<Map<String, dynamic>> get _tutorialSteps {
    return [
      {
        'title': 'Browse Your Subjects',
        'description': 'Explore all your subjects with chapters organized by the Ethiopian curriculum. Each chapter has videos, notes, quizzes, exams, and flashcards.',
        'icon': Icons.explore,
      },
      {
        'title': 'Purchase Your Grade Package',
        'description': 'One payment unlocks all subjects for your grade. Choose from Telebirr, M-PESA, CBE, CBO, or Awash Bank. Upload your receipt and get verified within 24 hours.',
        'icon': Icons.shopping_cart,
      },
      {
        'title': 'Submit Payment',
        'description': 'Make payment to the provided account, take a clear screenshot of your receipt, upload it in the app with your transaction reference, and wait for admin approval.',
        'icon': Icons.payment,
      },
      {
        'title': 'Start Learning',
        'description': 'Once approved, all content is unlocked! Download videos and notes for offline study. Track your progress, take quizzes, and prepare for exams.',
        'icon': Icons.school,
      },
    ];
  }

  void _startTutorial() {
    setState(() {
      _showTutorial = true;
      _tutorialStep = 0;
      _showVideoTutorial = false;
    });
  }

  void _startVideoTutorial() {
    setState(() {
      _showTutorial = true;
      _showVideoTutorial = true;
      _selectedLanguage = 'English';
    });
  }

  Future<void> _loadVideo(String language) async {
    if (_videoController != null) {
      await _videoController!.dispose();
    }

    setState(() {
      _isVideoInitialized = false;
      _selectedLanguage = language;
    });

    final assetPath = _videoAssets[language];
    if (assetPath == null) return;

    try {
      _videoController = VideoPlayerController.asset(assetPath)
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _isVideoInitialized = true);
            _videoController!.play();
          }
        }).catchError((error) {
          debugPrint('Error loading video: $error');
        });
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _nextTutorialStep() {
    if (_tutorialStep < _tutorialSteps.length - 1) {
      setState(() => _tutorialStep++);
    } else {
      _closeTutorial();
    }
  }

  void _previousTutorialStep() {
    if (_tutorialStep > 0) {
      setState(() => _tutorialStep--);
    }
  }

  void _closeTutorial() {
    _videoController?.pause();
    setState(() {
      _showTutorial = false;
      _tutorialStep = 0;
      _showVideoTutorial = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Help icon
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: _startTutorial,
                      icon: const Icon(Icons.help_outline, size: 28),
                      tooltip: 'How to use ACADIA',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 280,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) => setState(() => _currentPage = index),
                      itemCount: _slides.isNotEmpty ? _slides.length : 1,
                      itemBuilder: (context, index) {
                        if (_slides.isEmpty) return _buildPlaceholder();
                        final slide = _slides[index];
                        final image = slide['image']?.toString();
                        final isNetwork = slide['is_network'] == true;
                        final title = slide['title']?.toString() ?? '';

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 220,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: image != null
                                    ? isNetwork
                                        ? Image.network(image, fit: BoxFit.cover, width: double.infinity,
                                            errorBuilder: (_, __, ___) => _buildPlaceholder())
                                        : Image.asset(image, fit: BoxFit.cover, width: double.infinity,
                                            errorBuilder: (_, __, ___) => _buildPlaceholder())
                                    : _buildPlaceholder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (title.isNotEmpty)
                              Text(title, textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.isNotEmpty ? _slides.length : 1,
                      (index) => Container(
                        width: 8, height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index ? AppColors.primary : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _welcomeContent['main_title'] ?? 'Welcome to ACADIA',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _welcomeContent['subtitle'] ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    text: _welcomeContent['button_text'] ?? 'GET STARTED',
                    onPressed: () => context.push('/academic-path'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already a member? '),
                      TextButton(
                        onPressed: () => context.push('/login'),
                        child: const Text('LOG IN'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Tutorial Overlay
          if (_showTutorial)
            _showVideoTutorial ? _buildVideoTutorialOverlay() : _buildStepTutorialOverlay(),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primary.withAlpha(((255 * 0.2)).toInt()),
      child: const Center(child: Icon(Icons.school, size: 80, color: AppColors.primary)),
    );
  }

  // ============================================================
  // STEP-BY-STEP TUTORIAL OVERLAY
  // ============================================================

  Widget _buildStepTutorialOverlay() {
    final currentStep = _tutorialSteps[_tutorialStep];
    final isLastStep = _tutorialStep == _tutorialSteps.length - 1;

    return Container(
      color: Colors.black.withAlpha(((255 * 0.9)).toInt()),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Step ${_tutorialStep + 1} of ${_tutorialSteps.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          _closeTutorial();
                          _startVideoTutorial();
                        },
                        child: const Text('Watch Video', style: TextStyle(color: Colors.amber)),
                      ),
                      IconButton(
                        onPressed: _closeTutorial,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Step icon
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(((255 * 0.1)).toInt()),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(currentStep['icon'] as IconData, size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      currentStep['title'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      currentStep['description'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            // Navigation
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _tutorialSteps.length,
                      (index) => Container(
                        width: 8, height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _tutorialStep == index ? Colors.white : Colors.white.withAlpha(((255 * 0.4)).toInt()),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Navigation buttons
                  Row(
                    children: [
                      if (_tutorialStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousTutorialStep,
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
                            child: const Text('Previous', style: TextStyle(color: Colors.white)),
                          ),
                        )
                      else
                        const Expanded(child: SizedBox()),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _nextTutorialStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          child: Text(isLastStep ? 'Got It!' : 'Next'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _closeTutorial,
                    child: const Text('Skip Tutorial', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VIDEO TUTORIAL OVERLAY
  // ============================================================

  Widget _buildVideoTutorialOverlay() {
    return Container(
      color: Colors.black.withAlpha(((255 * 0.95)).toInt()),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tutorial Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          _videoController?.pause();
                          _videoController?.dispose();
                          _videoController = null;
                          setState(() {
                            _showVideoTutorial = false;
                            _tutorialStep = 0;
                          });
                        },
                        child: const Text('Step Guide', style: TextStyle(color: Colors.amber)),
                      ),
                      IconButton(
                        onPressed: _closeTutorial,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Language selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['English', 'Amharic', 'Afaan Oromoo'].map((lang) {
                  final isSelected = _selectedLanguage == lang;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(lang, style: TextStyle(fontSize: 12, color: isSelected ? Colors.black : Colors.white)),
                      selected: isSelected,
                      onSelected: (v) => _loadVideo(lang),
                      selectedColor: Colors.white,
                      backgroundColor: Colors.white.withAlpha(((255 * 0.2)).toInt()),
                      side: BorderSide.none,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Video player
            Expanded(
              child: _isVideoInitialized && _videoController != null
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                        if (!_videoController!.value.isPlaying)
                          GestureDetector(
                            onTap: () => setState(() => _videoController!.play()),
                            child: Container(
                              width: 64, height: 64,
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                            ),
                          ),
                      ],
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text('Loading video...', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
            ),

            // Video controls
            if (_isVideoInitialized && _videoController != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    VideoProgressIndicator(
                      _videoController!,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: Colors.white,
                        bufferedColor: Colors.white.withAlpha(((255 * 0.3)).toInt()),
                        backgroundColor: Colors.white.withAlpha(((255 * 0.1)).toInt()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_10, color: Colors.white),
                          onPressed: () {
                            final position = _videoController!.value.position;
                            _videoController!.seekTo(
                              position - const Duration(seconds: 10) < Duration.zero
                                  ? Duration.zero
                                  : position - const Duration(seconds: 10),
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        Container(
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: IconButton(
                            icon: Icon(
                              _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.black, size: 32,
                            ),
                            onPressed: () {
                              setState(() {
                                _videoController!.value.isPlaying
                                    ? _videoController!.pause()
                                    : _videoController!.play();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: const Icon(Icons.forward_10, color: Colors.white),
                          onPressed: () {
                            final position = _videoController!.value.position;
                            final duration = _videoController!.value.duration;
                            _videoController!.seekTo(
                              position + const Duration(seconds: 10) > duration
                                  ? duration
                                  : position + const Duration(seconds: 10),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Close button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _closeTutorial,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('GOT IT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}