import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/constants/academic_structure.dart';
import 'package:acadia/src/core/constants/content_structure.dart';
import 'package:acadia/src/widgets/common/subject_icon_widget.dart';
import 'package:acadia/src/core/services/package_service.dart';

class SubjectPortalScreen extends StatefulWidget {
  final String subjectId;
  const SubjectPortalScreen({super.key, required this.subjectId});

  @override
  State<SubjectPortalScreen> createState() => _SubjectPortalScreenState();
}

class _SubjectPortalScreenState extends State<SubjectPortalScreen> {
  String? _userGrade;
  String? _userStream;
  String? _userPath;
  Map<String, List<String>> _contentStructure = {};
  final Map<String, double> _unitProgress = {};
  final Map<String, bool> _unitCompleted = {};
  bool _isLoading = true;
  bool _isPurchased = false;
  DateTime? _purchaseExpiry;
  List<String> _contentTypes = [];
  final PackageService _packageService = PackageService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firebaseService = FirebaseService();

      _userGrade = prefs.getString('grade') ?? prefs.getString('selected_grade');
      _userStream = prefs.getString('stream') ?? prefs.getString('selected_stream');
      _userPath = prefs.getString('academic_path');

      // Check purchase status using PackageService
      _isPurchased = await _packageService.hasActivePackage();
      
      // If purchased, get expiry date
      if (_isPurchased) {
        final daysRemaining = await _packageService.getDaysRemaining();
        if (daysRemaining > 0) {
          _purchaseExpiry = DateTime.now().add(Duration(days: daysRemaining));
        }
      }

      // Load content structure based on user's academic path
      _loadContentStructure();

      // Fetch content types dynamically from Firebase for this subject
      final contentData = await firebaseService.getDocuments('content', where: {
        'subject': widget.subjectId,
        'status': 'approved',
      });
      
      // Extract unique content types from actual content data
      final Set<String> uniqueTypes = {};
      for (final item in contentData) {
        final type = item['content_type']?.toString();
        if (type != null && type.isNotEmpty) {
          uniqueTypes.add(type);
        }
      }
      
      if (mounted) {
        setState(() {
          _contentTypes = uniqueTypes.toList();
        });
      }

      // Load progress from local database or Firebase
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _loadUserProgress(userId);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading subject data: $e');
    }
  }

  void _loadContentStructure() {
    final stream = _userStream?.toLowerCase() ?? 'natural';
    final grade = _userGrade ?? '9';

    // Get hardcoded content structure for the subject
    _contentStructure = ContentStructure.getSubjectContent(grade, stream, widget.subjectId);
  }

  Future<void> _loadUserProgress(String userId) async {
    try {
      final firebaseService = FirebaseService();
      
      // Get progress for this subject from Firestore
      final progressData = await firebaseService.getDocuments('user_progress', where: {
        'user_id': userId,
        'subject_id': widget.subjectId,
      });
      
      for (final item in progressData) {
        final unitName = item['unit_name']?.toString();
        if (unitName != null) {
          _unitCompleted[unitName] = item['is_completed'] == true;
          _unitProgress[unitName] = (item['progress'] as num?)?.toDouble() ?? 0.0;
        }
      }
    } catch (e) {
      debugPrint('Error loading user progress: $e');
    }
  }

  double _getOverallProgress() {
    final units = _contentStructure.keys.toList();
    if (units.isEmpty) return 0.0;
    if (_unitProgress.isEmpty) return 0.0;
    
    double total = 0;
    for (final unit in units) {
      total += _unitProgress[unit] ?? 0.0;
    }
    return total / units.length;
  }

  int _getCompletedCount() => _unitCompleted.values.where((c) => c).length;
  int _getInProgressCount() => _unitProgress.values.where((p) => p > 0 && p < 1.0).length;
  int _getPendingCount() {
    final units = _contentStructure.keys.toList();
    return units.length - _getCompletedCount() - _getInProgressCount();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorHex = AcademicStructure.subjectColors[widget.subjectId] ?? '#607D8B';
    final subjectColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.subjectId)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final overallProgress = _getOverallProgress();
    final completedCount = _getCompletedCount();
    final inProgressCount = _getInProgressCount();
    final pendingCount = _getPendingCount();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.subjectId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [subjectColor, subjectColor.withAlpha(((255 * 0.7)).toInt())],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(((255 * 0.2)).toInt()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SubjectIconWidget(
                            subject: widget.subjectId,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_contentStructure.length} Units',
                          style: TextStyle(
                            color: Colors.white.withAlpha(((255 * 0.9)).toInt()),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Overall Progress
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isPurchased
                    ? subjectColor.withAlpha(((255 * 0.1)).toInt())
                    : Colors.orange.withAlpha(((255 * 0.1)).toInt()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPurchased
                      ? subjectColor.withAlpha(((255 * 0.3)).toInt())
                      : Colors.orange.withAlpha(((255 * 0.5)).toInt()),
                ),
              ),
              child: Column(
                children: [
                  if (!_isPurchased) ...[
                    Row(
                      children: [
                        Icon(Icons.lock_outline, color: Colors.orange[700], size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Content Locked',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                              Text(
                                'Purchase this grade to unlock all units',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.orange[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/payment'),
                      icon: const Icon(Icons.lock_open),
                      label: const Text('UNLOCK NOW'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (_purchaseExpiry != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Valid until: ${_purchaseExpiry!.day}/${_purchaseExpiry!.month}/${_purchaseExpiry!.year}',
                            style: TextStyle(color: Colors.green[700], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Overall Progress',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isPurchased ? '${(overallProgress * 100).toInt()}%' : 'Locked',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _isPurchased ? subjectColor : Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: overallProgress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(subjectColor),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProgressStat('$completedCount', 'Completed'),
                      _buildProgressStat('$inProgressCount', 'In Progress'),
                      _buildProgressStat('$pendingCount', 'Pending'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Content Types
          if (_contentTypes.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Content Types',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _contentTypes.map((type) {
                          return _buildContentTypeChip(type, subjectColor);
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Units List
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Units',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final units = _contentStructure.keys.toList();
                final unit = units[index];
                return _buildUnitCard(
                  context,
                  unit: unit,
                  unitNumber: index + 1,
                  subjectColor: subjectColor,
                );
              },
              childCount: _contentStructure.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildContentTypeChip(String type, Color color) {
    final icon = _getContentTypeIcon(type);
    final label = _getContentTypeLabel(type);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(((255 * 0.1)).toInt()),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(((255 * 0.3)).toInt())),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitCard(
    BuildContext context, {
    required String unit,
    required int unitNumber,
    required Color subjectColor,
  }) {
    final progress = _unitProgress[unit] ?? 0.0;
    final isCompleted = _unitCompleted[unit] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: _isPurchased ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _isPurchased ? Colors.transparent : Colors.grey[300]!,
        ),
      ),
      child: InkWell(
        onTap: () {
          final contentTypes = _contentStructure[unit] ?? [];
          context.push(
            '/chapter/${Uri.encodeComponent(unit)}',
            extra: {
              'unit': unit,
              'subjectId': widget.subjectId,
              'contentTypes': contentTypes,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _isPurchased
                      ? subjectColor.withAlpha(((255 * 0.1)).toInt())
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _isPurchased
                      ? (isCompleted
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : Text(
                              '$unitNumber',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: subjectColor,
                              ),
                            ))
                      : Icon(Icons.lock, color: Colors.grey[400]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isPurchased ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (!_isPurchased) ...[
                      Text(
                        'Purchase to unlock',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else if (isCompleted) ...[
                      Text(
                        'Completed ✓',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      if (progress > 0 && progress < 1.0) ...[
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(subjectColor),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(progress * 100).toInt()}% complete',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Tap to start learning',
                          style: TextStyle(
                            fontSize: 12,
                            color: subjectColor,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              if (_isPurchased)
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getContentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video': return Icons.play_circle_outline;
      case 'short_note': return Icons.description;
      case 'quiz': return Icons.quiz;
      case 'exam': return Icons.assignment;
      case 'flashcard': return Icons.style;
      case 'past_paper': return Icons.folder_open;
      default: return Icons.article;
    }
  }

  String _getContentTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'video': return 'Video';
      case 'short_note': return 'Short Note';
      case 'quiz': return 'Quiz';
      case 'exam': return 'Exam';
      case 'flashcard': return 'Flashcard';
      case 'past_paper': return 'Past Paper';
      default: return type;
    }
  }
}