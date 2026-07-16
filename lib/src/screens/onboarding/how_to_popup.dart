import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import '../../core/constants/colors.dart';

class HowToPopup extends StatefulWidget {
  const HowToPopup({super.key});

  @override
  State<HowToPopup> createState() => _HowToPopupState();
}

class _HowToPopupState extends State<HowToPopup> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;
  List<Map<String, dynamic>> _slides = [];
  String _popupTitle = 'How to Use ACADIA';
  String _buttonText = 'GOT IT';
  bool _isLoading = true;

  // Step icons (from ACADIA spec)
  final List<IconData> _stepIcons = [
    Icons.explore,
    Icons.shopping_cart,
    Icons.payment,
    Icons.school,
  ];

  // Step colors
  final List<Color> _stepColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _loadHowToContent();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHowToContent() async {
    try {
      final firebaseService = FirebaseService();
      final settings = await firebaseService.getAppSettings();

      if (settings != null && settings['how_to_content'] != null) {
        final value = Map<String, dynamic>.from(settings['how_to_content']);
        if (mounted) {
          setState(() {
            final slides = value['slides'];
            if (slides is List) {
              _slides = List<Map<String, dynamic>>.from(slides);
            }
            _popupTitle = value['title'] ?? 'How to Use ACADIA';
            _buttonText = value['button_text'] ?? 'GOT IT';
            _isLoading = false;
          });
        }
      } else {
        // Default content from ACADIA spec
        if (mounted) {
          setState(() {
            _slides = [
              {
                'title': 'Browse Your Subjects',
                'description': 'Explore all your subjects organized by chapters. Each chapter has videos, notes, quizzes, exams, and flashcards for complete learning.',
              },
              {
                'title': 'Purchase Your Grade Package',
                'description': 'One payment unlocks all subjects for your grade with one-year validity. Choose from Telebirr, M-PESA, CBE, CBO, or Awash Bank.',
              },
              {
                'title': 'Submit Payment',
                'description': 'Upload your payment receipt screenshot and enter transaction details. Admin will verify and unlock your content.',
              },
              {
                'title': 'Start Learning Offline',
                'description': 'Download content for offline use. Track your progress, take quizzes, pass exams, and prepare for your future!',
              },
            ];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading how-to content: $e');
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('how_to_seen', true);
    await prefs.setBool('show_how_to', !_dontShowAgain);

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: MediaQuery.of(context).size.width - 48,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              _popupTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Slides
            SizedBox(
              height: 320,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  final color = _stepColors[index % _stepColors.length];
                  final stepNumber = index + 1;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        // Step indicator with icon
                        Container(
                          height: 130,
                          width: 130,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(65),
                            border: Border.all(color: color.withOpacity(0.3), width: 2),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_stepIcons[index], color: color, size: 48),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Step $stepNumber',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Title
                        Text(
                          slide['title'] ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        // Description
                        Text(
                          slide['description'] ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Step indicators (dots)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == index
                        ? _stepColors[index % _stepColors.length]
                        : Colors.grey[300],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Don't show again checkbox
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _dontShowAgain,
                    onChanged: (value) => setState(() => _dontShowAgain = value ?? false),
                    activeColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
                  child: Text(
                    "Don't show this again",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // GOT IT / Next button
            Row(
              children: [
                if (_currentPage < _slides.length - 1) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _finish,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Skip', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _stepColors[_currentPage % _stepColors.length],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Next', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}