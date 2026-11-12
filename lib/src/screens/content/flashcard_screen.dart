import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:acadia/src/local_database/isar_service.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

class FlashcardScreen extends StatefulWidget {
  final String contentId;
  final String title;
  final String? downloadUrl;
  final int? expectedCardCount;

  const FlashcardScreen({
    super.key,
    required this.contentId,
    required this.title,
    this.downloadUrl,
    this.expectedCardCount,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  final IsarService _isarService = IsarService.instance;
  int _currentCard = 1;
  int _totalCards = 0;
  bool _isFlipped = false;
  final Set<int> _masteredCards = {};
  bool _isLoading = true;

  late AnimationController _controller;
  late Animation<double> _animation;

  List<Map<String, dynamic>> _flashcards = [];
  String _flashcardTitle = '';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final downloadedContent = await _isarService.getDownloadedContentById(
        widget.contentId,
        user.uid,
      );

      String? filePath;

      if (downloadedContent != null) {
        final dbPath = downloadedContent.contentPath;
        if (dbPath != null) {
          final file = File(dbPath);
          if (await file.exists()) {
            filePath = dbPath;
            debugPrint('✅ Found flashcard at DB path: $filePath');
          }
        }
      }

      if (filePath == null) {
        final directory = await getApplicationDocumentsDirectory();
        final jsonDir = Directory('${directory.path}/json_content');
        if (!await jsonDir.exists()) {
          await jsonDir.create(recursive: true);
        }

        final possiblePath = '${jsonDir.path}/${widget.contentId}.json';
        final file = File(possiblePath);
        if (await file.exists()) {
          filePath = possiblePath;
          debugPrint('✅ Found flashcard at json_content: $filePath');
        }
      }

      Map<String, dynamic>? data;
      if (filePath != null) {
        final file = File(filePath);
        final jsonString = await file.readAsString();
        data = json.decode(jsonString.replaceFirst('\uFEFF', ''))
            as Map<String, dynamic>;
      } else if (widget.downloadUrl != null &&
          widget.downloadUrl!.isNotEmpty) {
        final response = await Dio().get<String>(widget.downloadUrl!);
        if (response.data != null) {
          final jsonString = response.data!.replaceFirst('\uFEFF', '');
          data = json.decode(jsonString) as Map<String, dynamic>;
          final directory = await getApplicationDocumentsDirectory();
          final jsonDir = Directory('${directory.path}/json_content');
          if (!await jsonDir.exists()) {
            await jsonDir.create(recursive: true);
          }
          await File('${jsonDir.path}/${widget.contentId}.json')
              .writeAsString(jsonString);
        }
      }

      if (data == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'The flashcard file could not be loaded. Check your connection and try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      List<Map<String, dynamic>> cards = [];
      Map<String, dynamic>? nestedItem;
      if (data['cards'] != null) {
        cards = List<Map<String, dynamic>>.from(data['cards']);
      } else if (data['items'] != null) {
        final items = data['items'];
        if (items is List && items.isNotEmpty) {
          final firstItem = items[0];
          if (firstItem is Map && firstItem.containsKey('cards')) {
            nestedItem = Map<String, dynamic>.from(firstItem);
            cards = List<Map<String, dynamic>>.from(firstItem['cards']);
          } else {
            cards = List<Map<String, dynamic>>.from(items);
          }
        }
      }

      debugPrint('📊 Loaded ${cards.length} flashcards');

      if (mounted) {
        setState(() {
          _flashcardTitle = downloadedContent?.title ??
              nestedItem?['title']?.toString() ??
              data!['title']?.toString() ??
              widget.title;
          _flashcards = cards;
          _totalCards = cards.length;
          _isLoading = false;
        });
        if (cards.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This flashcard file contains no cards.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading flashcards: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'The flashcards could not be opened. The file may be invalid or unavailable.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _flipCard() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
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
    });
    _controller.reset();
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

    // FRONT: Question
    final String frontText = currentCard['front']?.toString() ?? 
                             currentCard['question']?.toString() ?? 
                             'Card ${_currentCard}';
    
    // BACK: Answer
    final String backText = currentCard['back']?.toString() ?? 
                            currentCard['answer']?.toString() ?? 
                            'No answer available';

    final difficulty = currentCard['difficulty']?.toString() ?? '';
    Color difficultyColor;
    if (difficulty == 'easy') {
      difficultyColor = Colors.green;
    } else if (difficulty == 'medium') {
      difficultyColor = Colors.orange;
    } else if (difficulty == 'hard') {
      difficultyColor = Colors.red;
    } else {
      difficultyColor = Colors.grey;
    }

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
          if (difficulty.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: difficultyColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: difficultyColor.withOpacity(0.3)),
              ),
              child: Text(
                difficulty.toUpperCase(),
                style: TextStyle(
                  color: difficultyColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 14),
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

          // ============================================
          // FIXED: Proper 3D flip with readable text on BOTH sides
          // ============================================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GestureDetector(
                onTap: _flipCard,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    // Determine which side to show
                    final bool showFront = _animation.value < 0.5;
                    
                    // Calculate the rotation angle
                    final double angle = _animation.value * 3.14159;
                    
                    // For the back side, we need to flip it back so text is readable
                    // But since we're using two separate widgets, we just rotate the container
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      alignment: Alignment.center,
                      child: showFront
                          ? _buildCardFace(frontText, isFront: true)
                          : Transform(
                              transform: Matrix4.identity()
                                ..rotateY(3.14159), // Rotate back so text is readable
                              alignment: Alignment.center,
                              child: _buildCardFace(backText, isFront: false),
                            ),
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
              Icon(
                _isFlipped ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[400],
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _isFlipped ? 'Tap to see question' : 'Tap to see answer',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
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