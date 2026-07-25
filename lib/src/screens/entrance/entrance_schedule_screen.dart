import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:acadia/src/core/constants/colors.dart';

class EntranceScheduleScreen extends StatefulWidget {
  const EntranceScheduleScreen({super.key});

  @override
  State<EntranceScheduleScreen> createState() => _EntranceScheduleScreenState();
}

class _EntranceScheduleScreenState extends State<EntranceScheduleScreen> {
  bool _isLoading = true;

  String _studentName = 'Student';
  String _grade = '11';
  String _stream = 'natural';

  double _overallProgress = 0.0;
  String _focusLevel = 'Balanced';
  String _focusMessage = '';
  String _headerTitle = 'Progress-Based Study Schedule';
  String _headerSubtitle =
      'A personalized entrance preparation plan based on your current learning progress.';

  late List<_ProgressMetric> _progressMetrics;
  late List<_ScheduleSession> _scheduleSessions;
  late List<_WeeklyFocusItem> _weeklyFocus;
  late List<String> _studyTips;
  late List<String> _priorityActions;

  @override
  void initState() {
    super.initState();
    _loadProgressBasedSchedule();
  }

  Future<void> _loadProgressBasedSchedule() async {
    final prefs = await SharedPreferences.getInstance();

    final grade =
        prefs.getString('grade') ?? prefs.getString('selected_grade') ?? '11';
    final stream = prefs.getString('stream') ??
        prefs.getString('selected_stream') ??
        'natural';
    final studentName = prefs.getString('user_name') ?? 'Student';

    final metrics = _buildMetricsForStream(stream);
    final overallProgress = metrics
            .map((metric) => metric.progress)
            .fold<double>(0, (a, b) => a + b) /
        metrics.length;

    final weakestSubjects = [...metrics]
      ..sort((a, b) => a.progress.compareTo(b.progress));

    final strongestSubjects = [...metrics]
      ..sort((a, b) => b.progress.compareTo(a.progress));

    final weakest = weakestSubjects.first;
    final secondWeakest = weakestSubjects[1];
    final strongest = strongestSubjects.first;

    final focusLevel = _deriveFocusLevel(overallProgress);
    final focusMessage = _buildFocusMessage(
      overallProgress: overallProgress,
      weakestSubject: weakest.subject,
      strongestSubject: strongest.subject,
    );

    final scheduleSessions = _buildScheduleSessions(
      weakest: weakest,
      secondWeakest: secondWeakest,
      strongest: strongest,
    );

    final weeklyFocus = _buildWeeklyFocus(
      weakest: weakest,
      secondWeakest: secondWeakest,
      strongest: strongest,
    );

    final studyTips = _buildStudyTips(
      weakest: weakest,
      secondWeakest: secondWeakest,
      strongest: strongest,
    );

    final priorityActions = _buildPriorityActions(
      weakest: weakest,
      secondWeakest: secondWeakest,
      strongest: strongest,
    );

    if (!mounted) return;

    setState(() {
      _studentName = studentName;
      _grade = grade;
      _stream = stream;
      _progressMetrics = metrics;
      _overallProgress = overallProgress;
      _focusLevel = focusLevel;
      _focusMessage = focusMessage;
      _scheduleSessions = scheduleSessions;
      _weeklyFocus = weeklyFocus;
      _studyTips = studyTips;
      _priorityActions = priorityActions;
      _isLoading = false;
    });
  }

  List<_ProgressMetric> _buildMetricsForStream(String stream) {
    final isSocial = stream.toLowerCase() == 'social';

    if (isSocial) {
      return [
        const _ProgressMetric(
          subject: 'Economics',
          progress: 0.38,
          chaptersDone: 3,
          totalChapters: 8,
        ),
        const _ProgressMetric(
          subject: 'Geography',
          progress: 0.44,
          chaptersDone: 4,
          totalChapters: 9,
        ),
        const _ProgressMetric(
          subject: 'History',
          progress: 0.61,
          chaptersDone: 5,
          totalChapters: 8,
        ),
        const _ProgressMetric(
          subject: 'Citizenship',
          progress: 0.55,
          chaptersDone: 5,
          totalChapters: 9,
        ),
        const _ProgressMetric(
          subject: 'Mathematics',
          progress: 0.47,
          chaptersDone: 4,
          totalChapters: 8,
        ),
        const _ProgressMetric(
          subject: 'English',
          progress: 0.67,
          chaptersDone: 6,
          totalChapters: 9,
        ),
      ];
    }

    return [
      const _ProgressMetric(
        subject: 'Mathematics',
        progress: 0.42,
        chaptersDone: 4,
        totalChapters: 10,
      ),
      const _ProgressMetric(
        subject: 'Physics',
        progress: 0.34,
        chaptersDone: 3,
        totalChapters: 9,
      ),
      const _ProgressMetric(
        subject: 'Chemistry',
        progress: 0.51,
        chaptersDone: 5,
        totalChapters: 10,
      ),
      const _ProgressMetric(
        subject: 'Biology',
        progress: 0.63,
        chaptersDone: 6,
        totalChapters: 10,
      ),
      const _ProgressMetric(
        subject: 'English',
        progress: 0.71,
        chaptersDone: 7,
        totalChapters: 10,
      ),
      const _ProgressMetric(
        subject: 'Aptitude',
        progress: 0.46,
        chaptersDone: 4,
        totalChapters: 9,
      ),
    ];
  }

  String _deriveFocusLevel(double progress) {
    if (progress < 0.45) return 'High Priority';
    if (progress < 0.65) return 'Focused Improvement';
    return 'Strong Momentum';
  }

  String _buildFocusMessage({
    required double overallProgress,
    required String weakestSubject,
    required String strongestSubject,
  }) {
    final percent = (overallProgress * 100).round();

    if (overallProgress < 0.45) {
      return 'Your current progress is $percent%. Give extra attention to $weakestSubject while maintaining consistency in $strongestSubject.';
    }

    if (overallProgress < 0.65) {
      return 'Your current progress is $percent%. You are improving well. Prioritize $weakestSubject and reinforce it with regular mixed practice.';
    }

    return 'Your current progress is $percent%. You have strong momentum. Keep $strongestSubject sharp while lifting $weakestSubject to the same level.';
  }

  List<_ScheduleSession> _buildScheduleSessions({
    required _ProgressMetric weakest,
    required _ProgressMetric secondWeakest,
    required _ProgressMetric strongest,
  }) {
    return [
      _ScheduleSession(
        title: 'Morning Deep Focus',
        time: '6:30 AM - 8:30 AM',
        description:
            'Work on ${weakest.subject} when your concentration is highest. Review weak concepts, solve guided questions, and write down key formulas or facts.',
        icon: Icons.auto_graph,
      ),
      _ScheduleSession(
        title: 'Afternoon Practice Block',
        time: '2:00 PM - 4:00 PM',
        description:
            'Practice timed exercises in ${secondWeakest.subject} and combine them with mixed entrance questions from ${weakest.subject}.',
        icon: Icons.quiz_outlined,
      ),
      _ScheduleSession(
        title: 'Evening Revision Session',
        time: '7:00 PM - 8:30 PM',
        description:
            'Use short-note revision, flashcards, and summary recall in ${strongest.subject} to maintain confidence while closing gaps from the day.',
        icon: Icons.menu_book_outlined,
      ),
    ];
  }

  List<_WeeklyFocusItem> _buildWeeklyFocus({
    required _ProgressMetric weakest,
    required _ProgressMetric secondWeakest,
    required _ProgressMetric strongest,
  }) {
    return [
      _WeeklyFocusItem(day: 'Monday', subject: weakest.subject),
      _WeeklyFocusItem(day: 'Tuesday', subject: secondWeakest.subject),
      _WeeklyFocusItem(day: 'Wednesday', subject: 'Past Paper Practice'),
      _WeeklyFocusItem(day: 'Thursday', subject: weakest.subject),
      _WeeklyFocusItem(day: 'Friday', subject: strongest.subject),
      _WeeklyFocusItem(day: 'Saturday', subject: 'Mock Exam + Review'),
      _WeeklyFocusItem(day: 'Sunday', subject: 'Weak-Area Revision'),
    ];
  }

  List<String> _buildStudyTips({
    required _ProgressMetric weakest,
    required _ProgressMetric secondWeakest,
    required _ProgressMetric strongest,
  }) {
    return [
      'Start each day with your weakest subject: ${weakest.subject}.',
      'Use timed drills to improve speed and accuracy in ${secondWeakest.subject}.',
      'Keep ${strongest.subject} active through short daily revision instead of long sessions.',
      'After every practice session, review mistakes before moving to a new topic.',
      'Reserve one weekly block for full entrance-style mixed questions.',
    ];
  }

  List<String> _buildPriorityActions({
    required _ProgressMetric weakest,
    required _ProgressMetric secondWeakest,
    required _ProgressMetric strongest,
  }) {
    return [
      'Complete the next 2 chapters in ${weakest.subject}.',
      'Solve one timed practice set in ${secondWeakest.subject} every day.',
      'Use ${strongest.subject} as your confidence subject before mock exams.',
    ];
  }

  String get _streamLabel {
    return _stream.toLowerCase() == 'social'
        ? 'Social Science'
        : 'Natural Science';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Study Schedule'),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Schedule'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadProgressBasedSchedule,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 20),
              _buildOverviewSection(),
              const SizedBox(height: 20),
              _buildPriorityActionsCard(),
              const SizedBox(height: 20),
              _buildSectionTitle('Subject Progress'),
              const SizedBox(height: 12),
              ..._progressMetrics.map(
                (metric) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildProgressCard(metric),
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Recommended Daily Plan'),
              const SizedBox(height: 12),
              ..._scheduleSessions.map(
                (session) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildScheduleCard(session),
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Weekly Focus'),
              const SizedBox(height: 12),
              _buildWeeklyPlanCard(),
              const SizedBox(height: 20),
              _buildSectionTitle('Study Tips'),
              const SizedBox(height: 12),
              _buildStudyTipsCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha((255 * 0.22).toInt()),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.calendar_month, color: Colors.white, size: 38),
          const SizedBox(height: 14),
          Text(
            _headerTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _headerSubtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildHeaderChip(_studentName),
              _buildHeaderChip('Grade $_grade'),
              _buildHeaderChip(_streamLabel),
              _buildHeaderChip(_focusLevel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((255 * 0.14).toInt()),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    final percent = (_overallProgress * 100).round();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildOverviewCard(
            title: 'Overall Progress',
            value: '$percent%',
            subtitle: 'Across key entrance subjects',
            icon: Icons.trending_up,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            title: 'Current Focus',
            value: _focusLevel,
            subtitle: 'Based on your learning data',
            icon: Icons.track_changes,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withAlpha((255 * 0.10).toInt())),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.04).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey.shade600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityActionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha((255 * 0.06).toInt()),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withAlpha((255 * 0.12).toInt())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Priority Actions',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _focusMessage,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          ..._priorityActions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      action,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildProgressCard(_ProgressMetric metric) {
    final percent = (metric.progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withAlpha((255 * 0.10).toInt())),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.035).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  metric.subject,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha((255 * 0.08).toInt()),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$percent%',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: metric.progress,
            minHeight: 9,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: AppColors.primary.withAlpha((255 * 0.10).toInt()),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${metric.chaptersDone}/${metric.totalChapters} chapters completed',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                _progressLabel(metric.progress),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _progressLabel(double progress) {
    if (progress < 0.4) return 'Needs urgent focus';
    if (progress < 0.65) return 'Improving steadily';
    return 'Strong progress';
  }

  Widget _buildScheduleCard(_ScheduleSession session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withAlpha((255 * 0.10).toInt())),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.035).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha((255 * 0.08).toInt()),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(session.icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session.time,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  session.description,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyPlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withAlpha((255 * 0.10).toInt())),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.035).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: _weeklyFocus
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 86,
                      child: Text(
                        item.day,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.subject,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildStudyTipsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withAlpha((255 * 0.10).toInt())),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.035).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: _studyTips
            .map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ProgressMetric {
  final String subject;
  final double progress;
  final int chaptersDone;
  final int totalChapters;

  const _ProgressMetric({
    required this.subject,
    required this.progress,
    required this.chaptersDone,
    required this.totalChapters,
  });
}

class _ScheduleSession {
  final String title;
  final String time;
  final String description;
  final IconData icon;

  const _ScheduleSession({
    required this.title,
    required this.time,
    required this.description,
    required this.icon,
  });
}

class _WeeklyFocusItem {
  final String day;
  final String subject;

  const _WeeklyFocusItem({
    required this.day,
    required this.subject,
  });
}
