import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart' as ul;
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/constants/academic_structure.dart';
import 'package:acadia/src/models/user_model.dart';
import 'package:acadia/src/widgets/common/subject_icon_widget.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  UserModel? _user;
  List<String> _subjects = [];
  bool _isLoading = true;
  Map<String, dynamic>? _dailyQuote;
  List<Map<String, dynamic>> _examTips = [];

  static const List<Map<String, String>> _defaultQuotes = [
    {
      'text':
          'Education is the most powerful weapon which you can use to change the world.',
      'author': 'Nelson Mandela',
    },
    {
      'text':
          'The mind is not a vessel to be filled, but a fire to be kindled.',
      'author': 'Plutarch',
    },
    {
      'text':
          'Live as if you were to die tomorrow. Learn as if you were to live forever.',
      'author': 'Mahatma Gandhi',
    },
    {
      'text': 'Failure is the opportunity to begin again more intelligently.',
      'author': 'Henry Ford',
    },
    {
      'text':
          'The beautiful thing about learning is that no one can take it away from you.',
      'author': 'B.B. King',
    },
  ];

  static const Map<String, Color> _subjectColors = {
    'Mathematics': Color(0xFF9C27B0),
    'English': Color(0xFF2196F3),
    'Physics': Color(0xFFFF9800),
    'Chemistry': Color(0xFF4CAF50),
    'Biology': Color(0xFFE91E63),
    'ICT': Color(0xFF3F51B5),
    'Geography': Color(0xFF009688),
    'History': Color(0xFF795548),
    'Economics': Color(0xFFFF5722),
    'Aptitude': Color(0xFF708090),
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final firebase = FirebaseService();
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();

      if (user != null) {
        final userData = await firebase.getDocument('users', user.uid);
        if (userData != null) {
          _user = UserModel.fromJson(userData);
        }
      }

      // Fallback user details from local SharedPreferences if not fully loaded from Firebase
      final grade = _user?.grade ??
          prefs.getString('grade') ??
          prefs.getString('selected_grade');
      final stream = _user?.stream ??
          prefs.getString('stream') ??
          prefs.getString('selected_stream');
      final semester = _user?.semester ?? prefs.getString('semester');
      final track = _user?.onboardingSelections?['track'] ??
          prefs.getString('selected_track');

      _subjects = _getSubjectsForPath(grade, stream, semester, track);

      await _loadDailyQuote();
      await _loadExamTips();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading home: $e');
    }
  }

  Future<void> _loadDailyQuote() async {
    final randomIndex = Random().nextInt(_defaultQuotes.length);
    _dailyQuote = _defaultQuotes[randomIndex];
  }

  Future<void> _loadExamTips() async {
    try {
      final firebase = FirebaseService();
      final settings = await firebase.getAppSettings();
      final tipsValue = settings?['exam_tips'];

      if (tipsValue is List) {
        _examTips = tipsValue
            .whereType<Object>()
            .map((tip) => {'tip': tip.toString()})
            .toList();
      } else {
        _examTips = [];
      }
    } catch (e) {
      debugPrint('Error loading exam tips: $e');
      _examTips = [];
    }
  }

  List<String> _getSubjectsForPath(
      String? grade, String? stream, String? semester, String? track) {
    final normalizedStream = (stream ?? 'natural').trim().toLowerCase();
    final streamKey =
        normalizedStream.contains('social') ? 'social' : 'natural';

    final isUniversity = _user?.academicLevel == 'university' ||
        semester != null ||
        (grade?.startsWith('university_') ?? false);
    if (isUniversity) {
      final semesterValue = semester ??
          RegExp(r'sem(\d)').firstMatch(grade ?? '')?.group(1) ??
          '1';
      return AcademicStructure.getUniversitySubjects(
        semesterValue == '2' ? '2' : '1',
        streamKey,
        track,
      );
    }

    final gradeNumber = grade?.replaceFirst('Grade_', '').trim();
    if (gradeNumber == '9' ||
        gradeNumber == '10' ||
        gradeNumber == '11' ||
        gradeNumber == '12') {
      return AcademicStructure.getSubjects(gradeNumber!, streamKey);
    }

    return AcademicStructure.getSubjects('11', streamKey);
  }

  Color _getSubjectColor(String subject) {
    return _subjectColors[subject] ?? Colors.indigo;
  }

  // ============================================
  // FIXED: Student name displayed horizontally
  // ============================================
  Widget _buildUserInfoCard() {
    final academicPath = _getAcademicPathDisplay();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage:
                    _user?.avatarUrl != null && _user!.avatarUrl!.isNotEmpty
                        ? NetworkImage(_user!.avatarUrl!)
                        : null,
                child: _user?.avatarUrl == null || _user!.avatarUrl!.isEmpty
                    ? Text(
                        (_user?.fullName ?? 'S')[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              // ============================================
              // FIXED: Expanded with Row for horizontal display
              // ============================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _user?.fullName ?? 'Student Profile',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _user?.email ?? '',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (_user?.selectedPackage ?? 'free') != 'free'
                      ? Colors.green.withOpacity(0.12)
                      : Colors.grey.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (_user?.selectedPackage ?? 'free') != 'free'
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
                child: Text(
                  (_user?.selectedPackage ?? 'free').toUpperCase(),
                  style: TextStyle(
                    color: (_user?.selectedPackage ?? 'free') != 'free'
                        ? Colors.green[800]
                        : Colors.grey[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Current Academic Path',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            academicPath,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _getAcademicPathDisplay() {
    final rawLevel = _user?.academicLevel ?? '';
    final level = rawLevel.toUpperCase();
    final grade = _user?.grade;
    final stream = (_user?.stream ?? '').toLowerCase();
    final department = _user?.department;
    final semester = _user?.semester;
    final track =
        (_user?.onboardingSelections?['track'] ?? '').toString().toLowerCase();

    if (level == 'UNIVERSITY' || level.contains('UNIVERSITY')) {
      if (department != null && department.isNotEmpty && semester != null) {
        return 'University - $department - Semester $semester';
      }
      if (semester == '2') {
        final trackName = track == 'pre_engineering'
            ? 'Pre-Engineering'
            : 'Other Natural Science';
        return 'University Freshman - Semester 2 ($trackName)';
      }
      if (semester == '1') {
        final streamName =
            stream == 'social' ? 'Social Science' : 'Natural Science';
        return 'University Freshman - Semester 1 ($streamName)';
      }
      return 'University Student';
    }

    if (grade != null && grade.isNotEmpty) {
      if (grade == '11' || grade == '12') {
        final streamName =
            stream == 'social' ? 'Social Science' : 'Natural Science';
        return 'Grade $grade - $streamName';
      }
      return 'Grade $grade - General Program';
    }

    return 'High School';
  }

  Future<void> _launchNextGenWebsite(BuildContext context) async {
    final uri = Uri.parse('https://nextgen-ethiopia.web.app/');
    try {
      final ok = await ul.launchUrl(
        uri,
        mode: ul.LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the link.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the link.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showEnlargedOwnerImage(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Semantics(
            label: 'Enlarged owner image. Tap outside to close.',
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(dialogContext).size.width * 0.85,
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/owner.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      width: 260,
                      height: 260,
                      child: const Icon(
                        Icons.waving_hand,
                        size: 96,
                        color: Color(0xFF00BCD4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFounderWelcomeCard(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 380;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            Colors.white.withOpacity(1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.18),
          width: 1,
        ),
      ),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeOwnerAvatar(context),
                const SizedBox(height: 12),
                _buildWelcomeMessage(context),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeOwnerAvatar(context),
                const SizedBox(width: 14),
                Expanded(child: _buildWelcomeMessage(context)),
              ],
            ),
    );
  }

  Widget _buildWelcomeOwnerAvatar(BuildContext context) {
    return Semantics(
      label: 'Open enlarged owner image',
      button: true,
      child: GestureDetector(
        onTap: () => _showEnlargedOwnerImage(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(56),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Image.asset(
              'assets/images/owner.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(
                  Icons.waving_hand,
                  size: 34,
                  color: Color(0xFF00BCD4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'A Message from the Founder',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.primary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'My name is Firaol Tadesa, CEO and Founder of NextGen Ethiopia and owner of Acadia. Welcome to Acadia!',
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: Color(0xFF242424),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          label: 'Open NextGen Ethiopia website',
          button: true,
          link: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _launchNextGenWebsite(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.primary.withOpacity(0.10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.public,
                      size: 16,
                      color: AppColors.primary.withOpacity(0.85),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'NEXTGEN ETHIOPIA',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final displaySubjects = _subjects;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfoCard(),
            const SizedBox(height: 24),
            _buildFounderWelcomeCard(context),
            const SizedBox(height: 24),

            // Personalized Recommended Learning Content
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recommended Learning',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(
                  '${displaySubjects.length} Subjects',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing:
                    12, // ← FIXED: Changed from 'mainSpacing' to 'mainAxisSpacing'
              ),
              itemCount: displaySubjects.length,
              itemBuilder: (context, index) {
                final subject = displaySubjects[index];
                final color = _getSubjectColor(subject);

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: InkWell(
                    onTap: () => context
                        .push('/subject-portal', extra: {'subject': subject}),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.14),
                            color.withOpacity(0.02)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SubjectIconWidget(
                              subject: subject, size: 28, color: color),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: color),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Explore content',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Daily Quote Rotation
            if (_dailyQuote != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.08),
                      AppColors.secondary.withOpacity(0.05)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColors.primary.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.format_quote,
                            color: AppColors.primary, size: 28),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              size: 18, color: AppColors.primary),
                          onPressed: _loadDailyQuote,
                          tooltip: 'Rotate Quote',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dailyQuote!['text'] ?? '',
                      style: const TextStyle(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          height: 1.45),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '- ${_dailyQuote!['author'] ?? 'Unknown'}',
                      style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Quick Tip
            if (_examTips.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.amber[800], size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Study Tip',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(
                            _examTips.first['tip']?.toString() ?? '',
                            style: const TextStyle(fontSize: 12.5, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
