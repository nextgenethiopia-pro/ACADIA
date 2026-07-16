import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/constants/colors.dart';

class EntranceTipsScreen extends StatefulWidget {
  const EntranceTipsScreen({super.key});

  @override
  State<EntranceTipsScreen> createState() => _EntranceTipsScreenState();
}

class _EntranceTipsScreenState extends State<EntranceTipsScreen> {
  List<String> _examTips = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _hasNetworkError = false;
  String? _headerTitle;
  String? _headerSubtitle;
  String? _motivationTitle;
  String? _motivationMessage;

  @override
  void initState() {
    super.initState();
    _loadTips();
  }

  Future<void> _loadTips() async {
    if (mounted) {
      setState(() {
        _hasNetworkError = false;
        _errorMessage = null;
        if (!_isLoading) _isRefreshing = true;
      });
    }

    try {
      final firebaseService = FirebaseService();
      final settings = await firebaseService.getAppSettings();

      // Load exam tips from settings
      if (settings != null && settings['exam_tips'] != null) {
        final tipsValue = settings['exam_tips'];
        if (tipsValue is List) {
          _examTips = List<String>.from(tipsValue);
        } else if (tipsValue is String) {
          _examTips = [tipsValue];
        }
      }

      // Load header and motivation settings
      if (settings != null && settings['entrance_tips_config'] != null) {
        final config = settings['entrance_tips_config'];
        _headerTitle = config['title']?.toString();
        _headerSubtitle = config['subtitle']?.toString();
        _motivationTitle = config['motivation_title']?.toString();
        _motivationMessage = config['motivation_message']?.toString();
      }

      // Add default tips if none from database
      if (_examTips.isEmpty) {
        _examTips = [
          'Start preparing early - don\'t wait until the last minute',
          'Create a study schedule and stick to it',
          'Practice with past exam papers regularly',
          'Focus on understanding concepts, not just memorizing',
          'Take care of your health - sleep, eat well, exercise',
          'Join study groups to discuss difficult topics',
          'Use flashcards for quick revision of key terms',
          'Stay calm and confident during the exam',
          'Read questions carefully before answering',
          'Manage your time effectively during the exam',
        ];
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _hasNetworkError = true;
          _errorMessage = 'Failed to load exam tips. Please check your connection.';
        });
        
        _showErrorSnackBar(_errorMessage!);
      }
      debugPrint('Error loading tips: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadTips,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Tips'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading exam tips...'),
                ],
              ),
            )
          : _hasNetworkError
              ? _buildErrorState(theme)
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadTips();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header (admin configurable)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.amber, Colors.deepOrange],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb, color: Colors.white, size: 40),
                              const SizedBox(height: 12),
                              Text(
                                _headerTitle ?? 'Exam Success Tips',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _headerSubtitle ?? 'Strategies to help you excel in your entrance exam',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_examTips.length} tips',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tips List
                        Text(
                          'Preparation Tips',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._examTips.asMap().entries.map((entry) {
                          return _buildTipCard(entry.key + 1, entry.value);
                        }),
                        const SizedBox(height: 24),

                        // Motivation Card (admin configurable)
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.05)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.emoji_events, color: AppColors.primary, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  _motivationTitle ?? 'You\'ve got this!',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _motivationMessage ?? 'With consistent effort and the right preparation, you can achieve your goals. Believe in yourself!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[600], height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildTipCard(int number, String tip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Optional: Show tip details or share
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tip,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Connection Error',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to load exam tips',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTips,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}