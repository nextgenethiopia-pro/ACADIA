import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/academic_structure.dart';
import '../../widgets/common/subject_icon_widget.dart';

/// Curriculum-driven subject browser.
///
/// Subjects come exclusively from [AcademicStructure], never from GitHub
/// metadata or directory listings, so navigation works fully offline.
class SubjectsTab extends StatefulWidget {
  const SubjectsTab({super.key});

  @override
  State<SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<SubjectsTab> {
  bool _isLoading = true;
  String _contextLabel = '';
  List<String> _subjects = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final academicLevel = prefs.getString('academic_level');
    final academicPath = prefs.getString('academic_path');
    final grade = prefs.getString('grade') ?? prefs.getString('selected_grade');
    final semester = prefs.getString('semester');
    final stream =
        (prefs.getString('stream') ?? prefs.getString('selected_stream') ?? '')
            .toLowerCase();
    final streamKey = stream.contains('social') ? 'social' : 'natural';
    final track = prefs.getString('selected_track') ?? prefs.getString('track');

    final isUniversity = academicLevel == 'university' ||
        academicPath == 'UNIVERSITY' ||
        semester != null ||
        (grade?.startsWith('university_') ?? false);

    List<String> subjects;
    String label;
    if (isUniversity) {
      final semesterValue = semester ?? '1';
      if (semesterValue == '2') {
        final isPreEngineering = track == 'pre_engineering';
        subjects = AcademicStructure.getUniversitySubjects(
            '2', streamKey, track);
        label = isPreEngineering
            ? 'Freshman • Semester 2 • Pre-Engineering'
            : 'Freshman • Semester 2 • Other Natural Science';
      } else {
        subjects = AcademicStructure.getUniversitySubjects('1', streamKey);
        label = 'Freshman • Semester 1 • '
            '${streamKey == 'social' ? 'Social Science' : 'Natural Science'}';
      }
    } else {
      final gradeNumber =
          RegExp(r'(\d+)').firstMatch(grade ?? '')?.group(1) ?? '9';
      subjects = AcademicStructure.getSubjects(gradeNumber, streamKey);
      label = 'Grade $gradeNumber • '
          '${streamKey == 'social' ? 'Social Science' : 'Natural Science'}';
    }

    if (!mounted) return;
    setState(() {
      _subjects = subjects;
      _contextLabel = label;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    _contextLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: _subjects.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No subjects are defined for this programme.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.15,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: _subjects.length,
                          itemBuilder: (context, index) {
                            final subject = _subjects[index];
                            final color = _subjectColor(subject);
                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => context.push(
                                  '/subject-portal',
                                  extra: {'subject': subject},
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SubjectIconWidget(
                                        subject: subject,
                                        size: 54,
                                        color: color,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        subject,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Color _subjectColor(String subject) {
    final value = AcademicStructure.subjectColors[subject] ?? '#607D8B';
    return Color(int.parse(value.replaceFirst('#', '0xFF')));
  }

}
