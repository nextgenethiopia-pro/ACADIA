import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/services/firebase_service.dart';

class EntranceTab extends StatefulWidget {
  const EntranceTab({super.key});

  @override
  State<EntranceTab> createState() => _EntranceTabState();
}

class _EntranceTabState extends State<EntranceTab> {
  String? _userGrade;
  String? _userStream;
  bool _isLoading = true;
  bool _isEligible = false;
  bool _hasPurchased = false;

  // Fetched content counts
  Map<String, int> _pastPapersCount = {};
  Map<String, int> _entranceExamCount = {};
  bool _isContentLoading = true;

  // 6 subjects per stream
  final List<String> _naturalSubjects = ['Mathematics', 'English', 'Biology', 'Chemistry', 'Physics', 'Aptitude'];
  final List<String> _socialSubjects = ['Mathematics', 'English', 'Aptitude', 'Economics', 'Geography', 'History'];

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
    _loadData();
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
      final firebaseService = FirebaseService();
      
      // Get user's payments
      final payments = await firebaseService.getUserPayments();

      String requiredPackage;
      if (_userGrade == '11') {
        requiredPackage = _userStream == 'social' ? 'Grade 11 Social Science' : 'Grade 11 Natural Science';
      } else if (_userGrade == '12') {
        requiredPackage = _userStream == 'social' ? 'Grade 12 Social Science' : 'Grade 12 Natural Science';
      } else {
        return;
      }

      final hasValidPurchase = payments.any((payment) {
        final package = payment['package']?.toString() ?? '';
        final status = payment['status']?.toString() ?? '';
        final validUntil = payment['valid_until']?.toString();
        
        // Check if package matches and status is approved
        if (package != requiredPackage || status != 'approved') return false;
        
        // Check if not expired
        if (validUntil != null) {
          try {
            final expiryDate = DateTime.parse(validUntil);
            if (expiryDate.isBefore(DateTime.now())) return false;
          } catch (e) {
            // Invalid date format, ignore expiry check
          }
        }
        
        return true;
      });

      setState(() => _hasPurchased = hasValidPurchase);
    } catch (e) {
      debugPrint('Error checking purchase status: $e');
    }
  }

  // NEW: Fetch entrance content from admin uploads
  Future<void> _fetchEntranceContent() async {
    setState(() => _isContentLoading = true);
    try {
      final firebaseService = FirebaseService();
      
      // Fetch all entrance materials from Firestore
      final entranceMaterials = await firebaseService.getDocuments('entrance_materials', where: {
        'status': 'active', // Only active content
      });
      
      final pastPapers = <String, int>{};
      final entranceExams = <String, int>{};
      
      // Initialize counts for each subject
      final subjects = _userStream == 'natural' ? _naturalSubjects : _socialSubjects;
      for (final subject in subjects) {
        pastPapers[subject] = 0;
        entranceExams[subject] = 0;
      }
      
      // Count materials by subject and type
      for (final material in entranceMaterials) {
        final type = material['type']?.toString() ?? '';
        final subject = material['subject']?.toString() ?? '';
        final stream = material['stream']?.toString() ?? '';
        
        // Only count materials matching user's stream
        if (stream != _userStream) continue;
        
        if (type == 'past_paper') {
          if (pastPapers.containsKey(subject)) {
            pastPapers[subject] = (pastPapers[subject] ?? 0) + 1;
          }
        } else if (type == 'entrance_exam') {
          if (entranceExams.containsKey(subject)) {
            entranceExams[subject] = (entranceExams[subject] ?? 0) + 1;
          }
        }
      }
      
      setState(() {
        _pastPapersCount = pastPapers;
        _entranceExamCount = entranceExams;
        _isContentLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching entrance content: $e');
      setState(() => _isContentLoading = false);
    }
  }

  List<String> get _subjects {
    if (_userStream == 'natural') return _naturalSubjects;
    if (_userStream == 'social') return _socialSubjects;
    return [];
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
                onPressed: () => context.push('/payment'),
                icon: const Icon(Icons.payment),
                label: const Text('Purchase Package'),
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
                          color: Colors.white.withAlpha(((255 * 0.2)).toInt()),
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
                                style: TextStyle(color: Colors.white.withAlpha(((255 * 0.9)).toInt()))),
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
              subtitle: 'Complete national exams from 2014 onwards',
              icon: Icons.description,
              color: Colors.blue,
              count: _pastPapersCount.values.reduce((a, b) => a + b),
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
              count: _entranceExamCount.values.reduce((a, b) => a + b),
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
                  color: color.withAlpha(((255 * 0.1)).toInt()),
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
                          color: color.withAlpha(((255 * 0.1)).toInt()),
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