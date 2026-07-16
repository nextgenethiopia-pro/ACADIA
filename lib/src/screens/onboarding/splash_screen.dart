import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/services/app_update_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  // Splash images from admin (up to 3 from ACADIA spec)
  List<String> _splashImages = [];
  int _currentImageIndex = 0;
  Timer? _imageTimer;
  bool _isLoadingImages = true;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
    _loadSplashImages();
    _navigateToNext();
  }

  Future<void> _loadSplashImages() async {
    try {
      final firebaseService = FirebaseService();
      final settings = await firebaseService.getAppSettings();

      if (settings != null && settings['splash_images'] != null) {
        final value = settings['splash_images'];
        if (value is List) {
          _splashImages = List<String>.from(value);
          // Limit to maximum 3 images as per ACADIA spec
          if (_splashImages.length > 3) {
            _splashImages = _splashImages.take(3).toList();
          }
        }
      }

      if (mounted) {
        setState(() => _isLoadingImages = false);
      }

      // Start image cycling if we have multiple admin images
      if (_splashImages.length > 1) {
        _startImageCycling();
      }
    } catch (e) {
      debugPrint('Error loading splash images: $e');
      if (mounted) setState(() => _isLoadingImages = false);
    }
  }

  void _startImageCycling() {
    _imageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _splashImages.isNotEmpty) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _splashImages.length;
        });
      }
    });
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    
    _imageTimer?.cancel();
    _controller.stop();

    // Force-update / maintenance gate driven by Firestore settings/app.
    final status = await AppUpdateService().checkStatus();
    if (status.blocks) {
      if (mounted) await _showBlockingDialog(status);
      return;
    }

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    final isAuthenticated = FirebaseAuth.instance.currentUser != null;
    final emailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!mounted) return;

    // Navigation logic
    if (onboardingComplete && isAuthenticated && emailVerified) {
      context.go('/dashboard');
    } else if (onboardingComplete && isAuthenticated && !emailVerified) {
      context.go('/verify-email');
    } else if (onboardingComplete && !isAuthenticated) {
      context.go('/login');
    } else {
      context.go('/welcome');
    }
  }

  Future<void> _showBlockingDialog(AppUpdateStatus status) async {
    final isMaintenance = status.action == AppUpdateAction.maintenance;
    final title = isMaintenance ? 'Under Maintenance' : 'Update Required';
    final body = status.message ??
        (isMaintenance
            ? 'ACADIA is temporarily unavailable for maintenance. Please try again later.'
            : 'A new version of ACADIA is required to continue. Please update to keep learning.');

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            if (!isMaintenance && (status.updateUrl?.isNotEmpty ?? false))
              ElevatedButton(
                onPressed: () async {
                  final uri = Uri.tryParse(status.updateUrl!);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text('Update Now'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _imageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image - splash.jpg (required)
          Image.asset(
            'assets/images/splash.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to gradient if image not found
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.darkBackground],
                  ),
                ),
              );
            },
          ),

          // Admin splash images overlay (up to 3 images)
          if (_splashImages.isNotEmpty && !_isLoadingImages)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Image.network(
                _splashImages[_currentImageIndex],
                key: ValueKey<int>(_currentImageIndex),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(color: Colors.transparent);
                },
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),

          // Dark overlay for text readability
          Container(color: Colors.black45),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(color: AppColors.primary, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logos/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.primary,
                            child: const Icon(
                              Icons.school,
                              size: 64,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // App Name
                const Text(
                  'ACADIA',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline
                const Text(
                  'Empowering Ethiopian Students',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 48),

                // Loading Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 3,
                        borderRadius: BorderRadius.circular(2),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Image indicators (for admin splash images)
                if (_splashImages.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _splashImages.asMap().entries.map((entry) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentImageIndex == entry.key ? 20 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: _currentImageIndex == entry.key
                              ? AppColors.primary
                              : Colors.white38,
                        ),
                      );
                    }).toList(),
                  ),

                // Version info
                const SizedBox(height: 16),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}