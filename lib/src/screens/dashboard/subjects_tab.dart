import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/services/package_service.dart';

/// SUBJECTS TAB
///
/// Shows the user's subjects for their academic path (grade/stream or
/// university semester/track), along with the current package lock status.
///
/// Per ACADIA spec:
/// - When locked: orange banner + "UNLOCK - XXX ETB" button. All subjects
///   are visible (not hidden), each showing a lock icon overlay.
/// - When unlocked: navy blue "Package Unlocked" banner with validity info,
///   and progress indicators instead of lock icons.
/// - Tapping a subject always navigates to the Subject Portal screen, which
///   itself renders the appropriate locked/unlocked chapter list.
class SubjectsTab extends StatefulWidget {
  const SubjectsTab({super.key});

  @override
  State<SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<SubjectsTab> {
  bool _isLoading = true;
  bool _isPackageLocked = true;
  int _daysRemaining = 0;
  String _packageName = '';
  int _packagePrice = 300;

  String? _userGrade;
  String? _userStream;
  String? _userPath;
  String? _userSemester;
  String? _userTrack;

  List<String> _subjects = [];

  final PackageService _packageService = PackageService();

  // Subjects per academic path (from ACADIA spec)
  static const Map<String, List<String>> _subjectsByPath = {
    'grade_9': [
      'Biology',
      'Chemistry',
      'Citizenship',
      'Economics',
      'English',
      'Geography',
      'History',
      'IT',
      'Mathematics',
      'Physics',
    ],
    'grade_10': [
      'Biology',
      'Chemistry',
      'Citizenship',
      'Economics',
      'English',
      'Geography',
      'History',
      'IT',
      'Mathematics',
      'Physics',
    ],
    'grade_11_natural': [
      'Agriculture',
      'Aptitude',
      'Biology',
      'Chemistry',
      'English',
      'IT',
      'Mathematics',
      'Physics',
    ],
    'grade_11_social': [
      'Aptitude',
      'Citizenship',
      'Economics',
      'English',
      'Geography',
      'History',
      'IT',
      'Mathematics',
    ],
    'grade_12_natural': [
      'Agriculture',
      'Aptitude',
      'Biology',
      'Chemistry',
      'English',
      'IT',
      'Mathematics',
      'Physics',
    ],
    'grade_12_social': [
      'Aptitude',
      'Citizenship',
      'Economics',
      'English',
      'Geography',
      'History',
      'IT',
      'Mathematics',
    ],
    'freshman_sem1_natural': [
      'English',
      'Geography',
      'Logic',
      'Mathematics',
      'Physics',
      'Psychology',
    ],
    'freshman_sem1_social': [
      'Economics',
      'English',
      'Geography',
      'Logic',
      'Mathematics',
      'Psychology',
    ],
    'freshman_sem2_pre_eng': [
      'Anthropology',
      'Applied Mathematics',
      'C++ Programming',
      'Emerging Technologies',
      'English Skill 2',
      'Entrepreneurship',
      'History',
      'Moral and Citizenship Education',
    ],
    'freshman_sem2_other': [
      'Anthropology',
      'Biology',
      'Chemistry',
      'Economics',
      'Emerging Technologies',
      'English Skill II',
      'History',
      'Moral and Citizenship Education',
    ],
  };

  // Chapter counts per subject (used as a lightweight "X chapters" label)
  static const Map<String, int> _chapterCounts = {
    'Biology': 6,
    'Chemistry': 5,
    'Citizenship': 8,
    'Economics': 8,
    'English': 8,
    'Geography': 6,
    'History': 9,
    'IT': 6,
    'Mathematics': 9,
    'Physics': 7,
    'Agriculture': 6,
    'Aptitude': 5,
    'Logic': 6,
    'Psychology': 11,
    'Anthropology': 7,
    'Applied Mathematics': 12,
    'C++ Programming': 8,
    'Emerging Technologies': 7,
    'English Skill 2': 5,
    'English Skill II': 5,
    'Entrepreneurship': 7,
    'Moral and Citizenship Education': 5,
  };

  // Custom subject icon assets (from ACADIA spec — 19 JPGs)
  static const Map<String, String> _subjectIconAssets = {
    'Mathematics': 'assets/icons/subjects_icon/Math_icon.jpg',
    'English': 'assets/icons/subjects_icon/English_icon.jpg',
    'English Skill 2': 'assets/icons/subjects_icon/English_icon.jpg',
    'English Skill II': 'assets/icons/subjects_icon/English_icon.jpg',
    'Physics': 'assets/icons/subjects_icon/Physics_icon.jpg',
    'Chemistry': 'assets/icons/subjects_icon/Chemistry_icon.jpg',
    'Biology': 'assets/icons/subjects_icon/Biology_icon.jpg',
    'Aptitude': 'assets/icons/subjects_icon/Aptitude_icon.jpg',
    'Geography': 'assets/icons/subjects_icon/Geography_icon.jpg',
    'History': 'assets/icons/subjects_icon/History_icon.jpg',
    'Economics': 'assets/icons/subjects_icon/Economics_icon.jpg',
    'IT': 'assets/icons/subjects_icon/It_icon.jpg',
    'Agriculture': 'assets/icons/subjects_icon/Agriculture_icon.jpg',
    'Citizenship': 'assets/icons/subjects_icon/Citizenship_icon.jpg',
    'Logic': 'assets/icons/subjects_icon/Logic_icon.jpg',
    'Psychology': 'assets/icons/subjects_icon/Psychology_icon.jpg',
    'Anthropology': 'assets/icons/subjects_icon/Anthropology_icon.jpg',
    'Applied Mathematics': 'assets/icons/subjects_icon/Applied_math_icon.jpg',
    'C++ Programming': 'assets/icons/subjects_icon/C++_icon.jpg',
    'Emerging Technologies': 'assets/icons/subjects_icon/Emerging_icon.jpg',
    'Entrepreneurship': 'assets/icons/subjects_icon/Economics_icon.jpg',
    'Moral and Citizenship Education':
        'assets/icons/subjects_icon/Civic_icon.jpg',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      _userPath = prefs.getString('academic_path');
      _userGrade =
          prefs.getString('grade') ?? prefs.getString('selected_grade');
      _userStream =
          prefs.getString('stream') ?? prefs.getString('selected_stream');
      _userSemester = prefs.getString('semester') ?? '1';
      _userTrack = prefs.getString('selected_track');

      _subjects = _getSubjectsForPath(
        _userGrade,
        _userStream,
        _userSemester,
        _userTrack,
      );

      // Check package status
      final hasActivePackage = await _packageService.hasActivePackage();
      _isPackageLocked = !hasActivePackage;

      if (!hasActivePackage) {
        _packageName = await _packageService.getPackageName();
        _packagePrice = await _packageService.getPackagePrice();
      } else {
        _daysRemaining = await _packageService.getDaysRemaining();
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading subjects tab: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> _getSubjectsForPath(
    String? grade,
    String? stream,
    String? semester,
    String? track,
  ) {
    final normalizedPath = (_userPath ?? '').toUpperCase();

    if (normalizedPath == 'UNIVERSITY') {
      if (semester == '2') {
        final key = track == 'pre_engineering'
            ? 'freshman_sem2_pre_eng'
            : 'freshman_sem2_other';
        return _subjectsByPath[key] ?? [];
      }
      final key =
          stream == 'social' ? 'freshman_sem1_social' : 'freshman_sem1_natural';
      return _subjectsByPath[key] ?? [];
    }

    if (grade == null) return [];

    switch (grade) {
      case '9':
        return _subjectsByPath['grade_9'] ?? [];
      case '10':
        return _subjectsByPath['grade_10'] ?? [];
      case '11':
        return _subjectsByPath[
                stream == 'social' ? 'grade_11_social' : 'grade_11_natural'] ??
            [];
      case '12':
        return _subjectsByPath[
                stream == 'social' ? 'grade_12_social' : 'grade_12_natural'] ??
            [];
      default:
        return [];
    }
  }

  Color _getSubjectColor(String subject) {
    // Uniform navy blue design (ACADIA V1.0.0)
    return AppColors.primary;
  }

  Widget _getSubjectIconWidget(String subject, {double size = 28}) {
    final assetPath = _subjectIconAssets[subject];
    final color = _getSubjectColor(subject);

    if (assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(_getSubjectFallbackIcon(subject),
                color: color, size: size);
          },
        ),
      );
    }
    return Icon(_getSubjectFallbackIcon(subject), color: color, size: size);
  }

  IconData _getSubjectFallbackIcon(String subject) {
    switch (subject) {
      case 'Mathematics':
        return Icons.functions;
      case 'English':
      case 'English Skill 2':
      case 'English Skill II':
        return Icons.menu_book;
      case 'Physics':
        return Icons.science;
      case 'Chemistry':
        return Icons.biotech;
      case 'Biology':
        return Icons.eco;
      case 'Aptitude':
        return Icons.psychology;
      case 'Geography':
        return Icons.public;
      case 'History':
        return Icons.history_edu;
      case 'Economics':
        return Icons.trending_up;
      case 'IT':
        return Icons.computer;
      case 'Agriculture':
        return Icons.agriculture;
      case 'Citizenship':
        return Icons.account_balance;
      case 'Logic':
        return Icons.lightbulb;
      case 'Psychology':
        return Icons.psychology_alt;
      case 'Anthropology':
        return Icons.groups;
      case 'Applied Mathematics':
        return Icons.calculate;
      case 'C++ Programming':
        return Icons.code;
      case 'Emerging Technologies':
        return Icons.devices;
      case 'Entrepreneurship':
        return Icons.business_center;
      case 'Moral and Citizenship Education':
        return Icons.gavel;
      default:
        return Icons.book;
    }
  }

  void _openSubject(String subject) {
    context.push('/subject-portal', extra: {'subject': subject});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(),
            const SizedBox(height: 20),
            Text(
              'Your Subjects',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${_subjects.length} subjects available for your path',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            _subjects.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.95,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      return _buildSubjectCard(_subjects[index]);
                    },
                  ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    if (_isPackageLocked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(((255 * 0.1)).toInt()),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.withAlpha(((255 * 0.3)).toInt())),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.orange[700], size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _packageName.isNotEmpty
                            ? '$_packageName - Locked'
                            : 'Package Locked',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Purchase once to unlock all chapters for 1 year',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/payment'),
                icon: const Icon(Icons.lock_open),
                label: Text('UNLOCK - $_packagePrice ETB'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(((255 * 0.08)).toInt()),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withAlpha(((255 * 0.2)).toInt())),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Package Unlocked',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _daysRemaining > 0
                      ? 'Valid for $_daysRemaining more days'
                      : 'All chapters unlocked',
                  style: TextStyle(
                    color: AppColors.primary.withAlpha(((255 * 0.8)).toInt()),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(String subject) {
    final color = _getSubjectColor(subject);
    final chapterCount = _chapterCounts[subject] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => _openSubject(subject),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [color.withAlpha(((255 * 0.12)).toInt()), color.withAlpha(((255 * 0.02)).toInt())],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withAlpha(((255 * 0.12)).toInt()),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _getSubjectIconWidget(subject, size: 26),
                  ),
                  if (_isPackageLocked)
                    Icon(Icons.lock, color: Colors.orange[600], size: 18)
                  else
                    Icon(Icons.chevron_right, color: color, size: 20),
                ],
              ),
              const Spacer(),
              Text(
                subject,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                chapterCount > 0 ? '$chapterCount chapters' : 'Tap to explore',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
              if (!_isPackageLocked) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.0,
                    minHeight: 5,
                    backgroundColor: color.withAlpha(((255 * 0.1)).toInt()),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No subjects found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your academic path setup to see subjects here',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
