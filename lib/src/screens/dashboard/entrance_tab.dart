import 'package:flutter/material.dart';
import 'package:acadia/src/core/constants/academic_structure.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/services/package_service.dart';

class EntranceTab extends StatefulWidget {
  const EntranceTab({super.key, this.refreshSignal = 0});

  /// Bumped by the parent (dashboard) whenever this tab becomes visible.
  ///
  /// The tab stays alive inside the dashboard's IndexedStack, so its purchase
  /// status is otherwise only checked once at startup. Re-checking on signal
  /// change makes the Entrance pack unlock immediately after an admin approves
  /// the payment, without needing an app restart.
  final int refreshSignal;

  @override
  State<EntranceTab> createState() => _EntranceTabState();
}

class _EntranceTabState extends State<EntranceTab>
    with WidgetsBindingObserver {
  String? _userGrade;
  String? _userStream;
  bool _isLoading = true;
  bool _isEligible = false;
  bool _hasPurchased = false;

  // Fetched content counts
  Map<String, int> _pastPapersCount = {};
  Map<String, int> _entranceExamCount = {};
  bool _isContentLoading = true;

  List<String> _subjects = [];

  // Custom subject icon assets
  static const Map<String, String> _subjectIconAssets = {
    'Mathematics': 'assets/icons/subjects_icon/Math_icon.jpg',
    'English': 'assets/icons/subjects_icon/English_icon.jpg',
    'Physics': 'assets/icons/subjects_icon/Physics_icon.jpg',
    'Chemistry': 'assets/icons/subjects_icon/Chemistry_icon.jpg',
    'Biology': 'assets/icons/subjects_icon/Biology_icon.jpg',
    'Aptitude': 'assets/icons/subjects_icon/Aptitude_icon.jpg',
    'Geography': 'assets/icons/subjects_icon/Geography_icon.jpg',
    'History': 'assets/icons/subjects_icon/History_icon.jpg',
    'Economics': 'assets/icons/subjects_icon/Economics_icon.jpg',
  };

  static const Map<String, Color> _subjectColors = {
    'Mathematics': Color(0xFF9C27B0),
    'English': Color(0xFF2196F3),
    'Physics': Color(0xFFFF9800),
    'Chemistry': Color(0xFF4CAF50),
    'Biology': Color(0xFFE91E63),
    'Aptitude': Color(0xFF708090),
    'Geography': Color(0xFF009688),
    'History': Color(0xFF795548),
    'Economics': Color(0xFFFF5722),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EntranceTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal && _isEligible) {
      _checkPurchaseStatus();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Admin approval happens on another device, so re-check when the student
    // comes back to the app.
    if (state == AppLifecycleState.resumed && _isEligible) {
      _checkPurchaseStatus();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _userGrade = prefs.getString('grade') ?? prefs.getString('selected_grade');
      _userStream = prefs.getString('stream') ?? prefs.getString('selected_stream');

      _isEligible = _userGrade == '11' || _userGrade == '12';

      if (_isEligible) {
        await _checkPurchaseStatus();
        await _fetchEntranceContent(); // NEW: Fetch content from admin
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading entrance data: $e');
    }
  }

  Future<void> _checkPurchaseStatus() async {
    try {
      // Check if user has an active package via PackageService
      final packageService = PackageService();
      final hasPackage = await packageService.hasActivePackage();

      if (hasPackage) {
        setState(() => _hasPurchased = true);
        return;
      }

      if (mounted) {
        setState(() => _hasPurchased = false);
      }
    } catch (e) {
      debugPrint('Error checking purchase status: $e');
    }
  }

  Future<void> _fetchEntranceContent() async {
    if (!mounted) return;
    setState(() => _isContentLoading = true);

    try {
      // Entrance navigation is hardcoded for offline use. Do not query
      // GitHub until the user opens a specific year/subject/unit.
      final stream = _normalizeStream(_userStream);
      final streamKey = stream == 'social_science' ? 'social' : 'natural';
      final subjects = AcademicStructure.getEntranceSubjects(streamKey);

      final pastPapers = <String, int>{
        for (final subject in subjects) subject: 0,
      };
      final entranceExams = <String, int>{
        for (final subject in subjects) subject: 0,
      };

      if (mounted) {
        setState(() {
          _subjects = subjects;
          _pastPapersCount = pastPapers;
          _entranceExamCount = entranceExams;
          _isContentLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error building hardcoded entrance navigation: $e');
      if (mounted) {
        setState(() {
          _subjects = [];
          _pastPapersCount = {};
          _entranceExamCount = {};
          _isContentLoading = false;
        });
      }
    }
  }

  String _normalizeStream(String? stream) {
    switch (stream?.trim().toLowerCase()) {
      case 'natural':
      case 'natural science':
      case 'natural_science':
        return 'natural_science';
      case 'social':
      case 'social science':
      case 'social_science':
        return 'social_science';
      default:
        return '';
    }
  }

  String get _streamDisplayName {
    if (_userStream == 'natural') return 'Natural Science';
    if (_userStream == 'social') return 'Social Science';
    return '';
  }

  String get _requiredPackageName {
    if (_userGrade == '11') {
      return _userStream == 'social' ? 'Grade 11 Social Science' : 'Grade 11 Natural Science';
    } else if (_userGrade == '12') {
      return _userStream == 'social' ? 'Grade 12 Social Science' : 'Grade 12 Natural Science';
    }
    return 'Grade Package';
  }

  Widget _getSubjectIcon(String subject, {double size = 24}) {
    final assetPath = _subjectIconAssets[subject];
    if (assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.asset(assetPath, width: size, height: size, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(_getSubjectFallbackIcon(subject), size: size)),
      );
    }
    return Icon(_getSubjectFallbackIcon(subject), size: size);
  }

  IconData _getSubjectFallbackIcon(String subject) {
    switch (subject) {
      case 'Mathematics': return Icons.functions;
      case 'Physics': return Icons.calculate;
      case 'Chemistry': return Icons.biotech;
      case 'Biology': return Icons.science;
      case 'English': return Icons.menu_book;
      case 'Aptitude': return Icons.psychology;
      case 'Economics': return Icons.trending_up;
      case 'Geography': return Icons.public;
      case 'History': return Icons.history_edu;
      default: return Icons.school;
    }
  }

  Color _getSubjectColor(String subject) {
    return _subjectColors[subject] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isEligible) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('Entrance Exam Preparation',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Available for Grade 11 and 12 students only.',
                  style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (!_hasPurchased) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.amber[600]),
              const SizedBox(height: 16),
              const Text('Content Locked', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Purchase the $_requiredPackageName Package to unlock entrance exam preparation.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await context.push('/payment');
                  if (mounted) await _checkPurchaseStatus();
                },
                icon: const Icon(Icons.payment),
                label: const Text('Purchase Package'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _checkPurchaseStatus,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Already paid? Refresh status'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1A237E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('University Entrance Exam',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                            Text('Grade $_userGrade - $_streamDisplayName',
                                style: TextStyle(color: Colors.white.withOpacity(0.9))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ============================================
            // SECTION 1: PAST PAPERS (with count from admin)
            // ============================================
            _buildSectionCard(
              title: 'Past Papers',
              subtitle: 'Complete national exams from 2010 onwards',
              icon: Icons.description,
              color: Colors.blue,
              count: _pastPapersCount.values.fold<int>(0, (sum, count) => sum + count),
              onViewAll: () => context.push('/entrance/past-papers', extra: {
                'subjects': _subjects,
                'stream': _userStream,
                'grade': _userGrade,
              }),
            ),
            const SizedBox(height: 20),

            // ============================================
            // SECTION 2: ENTRANCE EXAM (with count from admin)
            // ============================================
            _buildSectionCard(
              title: 'Entrance Exam',
              subtitle: 'Practice questions by grade and chapter',
              icon: Icons.quiz,
              color: Colors.orange,
              count: _entranceExamCount.values.fold<int>(0, (sum, count) => sum + count),
              onViewAll: () => context.push('/entrance/exam', extra: {
                'subjects': _subjects,
                'stream': _userStream,
                'grade': _userGrade,
              }),
            ),
            const SizedBox(height: 20),

            // ============================================
            // SECTION 3: STUDY SCHEDULE
            // ============================================
            _buildSectionCard(
              title: 'Study Schedule',
              subtitle: 'Plan your exam preparation',
              icon: Icons.calendar_today,
              color: Colors.green,
              onViewAll: () => context.push('/entrance/schedule'),
            ),
            const SizedBox(height: 20),

            // ============================================
            // SECTION 4: EXAM TIPS (from admin settings)
            // ============================================
            _buildSectionCard(
              title: 'Exam Tips',
              subtitle: 'Strategies for success',
              icon: Icons.lightbulb,
              color: Colors.amber,
              onViewAll: () => context.push('/entrance/tips'),
            ),

            const SizedBox(height: 16),

            // Loading indicator for content
            if (_isContentLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    int? count,
    required VoidCallback onViewAll,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onViewAll,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    if (count != null && count > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count items available',
                          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
