import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/services/offline_database.dart';
import 'package:acadia/src/core/constants/colors.dart';

class FlashcardScreen extends StatefulWidget {
  final String contentId;
  final String title;

  const FlashcardScreen({
    super.key,
    required this.contentId,
    required this.title,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  int _currentCard = 1;
  int _totalCards = 0;
  bool _isFlipped = false;
  final Set<int> _masteredCards = {};
  bool _isLoading = true;
  bool _isRestarting = false;

  late AnimationController _controller;
  late Animation<double> _frontAnimation;
  late Animation<double> _backAnimation;

  List<Map<String, dynamic>> _flashcards = [];
  String _flashcardTitle = '';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _frontAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeInOut)),
    );

    _backAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeInOut)),
    );

    _loadFlashcards();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFlashcards() async {
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
        final filePath = result.first['local_path'] as String;
        final file = File(filePath);

        if (await file.exists()) {
          final jsonString = await file.readAsString();
          final data = json.decode(jsonString) as Map<String, dynamic>;

          final cards = List<Map<String, dynamic>>.from(data['cards'] ?? []);

          if (mounted) {
            setState(() {
              _flashcardTitle = data['title']?.toString() ?? widget.title;
              _flashcards = cards;
              _totalCards = cards.length;
              _isLoading = false;
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flashcard file not found. Please download it first.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading flashcards: $e');
    }
  }

  void _flipCard() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _nextCard({bool mastered = false}) {
    if (mastered) {
      _masteredCards.add(_currentCard);
    }

    if (_currentCard < _totalCards) {
      setState(() {
        _currentCard++;
        _isFlipped = false;
      });
      _controller.reset();
    } else {
      // Show completion dialog
      _showCompletionDialog();
    }
  }

  void _previousCard() {
    if (_currentCard > 1) {
      setState(() {
        _currentCard--;
        _isFlipped = false;
      });
      _controller.reset();
    }
  }

  void _restartFlashcards() {
    setState(() {
      _currentCard = 1;
      _masteredCards.clear();
      _isFlipped = false;
      _isRestarting = true;
    });
    _controller.reset();
    
    // Reset restarting flag after animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isRestarting = false);
      }
    });
  }

  void _showCompletionDialog() {
    final totalReviewed = _masteredCards.length;
    final totalCards = _totalCards;
    final masteredPercentage = totalCards > 0 ? (totalReviewed / totalCards * 100).toInt() : 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber[700], size: 28),
            const SizedBox(width: 8),
            const Text('Flashcards Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'You reviewed all $totalCards cards!',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Mastered:', style: TextStyle(color: Colors.green[700])),
                  Text('$totalReviewed cards', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (totalCards - totalReviewed > 0)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Need practice:', style: TextStyle(color: Colors.orange[700])),
                    Text('${totalCards - totalReviewed} cards', style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: masteredPercentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            Text('$masteredPercentage% Mastered', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restartFlashcards();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Flashcards...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_flashcards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.style_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('No flashcards available', style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Download the flashcard file first', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    final progress = _totalCards > 0 ? _currentCard / _totalCards : 0.0;
    final isMastered = _masteredCards.contains(_currentCard);
    final currentCard = _flashcards[_currentCard - 1];
    final masteredCount = _masteredCards.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_flashcardTitle, style: const TextStyle(fontSize: 16)),
        leading: IconButton(
          onPressed: () {
            if (_masteredCards.isNotEmpty || _currentCard > 1) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Exit Flashcards?'),
                  content: Text('You have reviewed $masteredCount of $_totalCards cards. Your progress will be lost.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Stay')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.pop();
                      },
                      child: const Text('Exit', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            } else {
              context.pop();
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$masteredCount/$_totalCards',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Card $_currentCard of $_totalCards',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (isMastered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text('Mastered', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
          ),

          // Flashcard (3D Flip Animation)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GestureDetector(
                onTap: _flipCard,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final isFront = _frontAnimation.value < 0.5;
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(isFront
                            ? _frontAnimation.value * 3.14159
                            : (1 - _backAnimation.value) * 3.14159),
                      alignment: Alignment.center,
                      child: isFront
                          ? _buildCardFace(
                              currentCard['front']?.toString() ?? currentCard['question']?.toString() ?? '',
                              isFront: true)
                          : _buildCardFace(
                              currentCard['back']?.toString() ?? currentCard['answer']?.toString() ?? '',
                              isFront: false),
                    );
                  },
                ),
              ),
            ),
          ),

          // Tap Hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedOpacity(
                opacity: _isFlipped ? 0.5 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(Icons.touch_app, color: Colors.grey[400], size: 16),
              ),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: _isFlipped ? Colors.grey[400] : Colors.grey[500],
                  fontSize: 12,
                ),
                child: Text(_isFlipped ? 'Tap to see question' : 'Tap to flip card'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Previous button (if not first card)
                  if (_currentCard > 1)
                    IconButton(
                      onPressed: _previousCard,
                      icon: Icon(Icons.chevron_left, size: 32, color: Colors.grey[600]),
                    ),
                  
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _nextCard(mastered: false),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text("DIDN'T KNOW", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.red[300]!),
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _nextCard(mastered: true),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('GOT IT!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  
                  // Next button (if not last card)
                  if (_currentCard < _totalCards)
                    IconButton(
                      onPressed: () => _nextCard(mastered: false),
                      icon: Icon(Icons.chevron_right, size: 32, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFace(String text, {required bool isFront}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isFront 
              ? [Colors.white, Colors.grey[50]!]
              : [AppColors.primary.withOpacity(0.05), AppColors.primary.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: (isFront ? AppColors.primary : Colors.green).withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isFront ? AppColors.primary.withOpacity(0.3) : Colors.green.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isFront ? AppColors.primary : Colors.green).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFront ? Icons.help_outline : Icons.lightbulb_outline,
              size: 48,
              color: isFront ? AppColors.primary : Colors.green,
            ),
          ),
          const SizedBox(height: 32),
          
          // Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              text,
              style: TextStyle(
                fontSize: isFront ? 22 : 18,
                fontWeight: isFront ? FontWeight.bold : FontWeight.normal,
                color: isFront ? Colors.black87 : Colors.grey[800],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          
          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (isFront ? AppColors.primary : Colors.green).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isFront ? 'QUESTION' : 'ANSWER',
              style: TextStyle(
                fontSize: 11,
                color: isFront ? AppColors.primary : Colors.green,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}