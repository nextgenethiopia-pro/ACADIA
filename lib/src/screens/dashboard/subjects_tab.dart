import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:acadia/src/core/constants/academic_structure.dart';
import 'package:acadia/src/core/content/structure_service.dart';
import 'package:acadia/src/widgets/common/subject_icon_widget.dart';

/// SubjectsTab
///
/// Lists the subjects available for the signed-in user's academic path and
/// opens the subject portal for the selected subject. Subjects are derived
/// from [AcademicStructure] (the canonical academic structure), so no subject
/// data is hardcoded in this widget.
class SubjectsTab extends StatefulWidget {
  const SubjectsTab({super.key});

  @override
  State<SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<SubjectsTab> {
  bool _isLoading = true;
  List<String> _subjects = [];
  String? _userGrade;
  String? _userStream;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final grade =
        prefs.getString('grade') ?? prefs.getString('selected_grade');
    final stream =
        prefs.getString('stream') ?? prefs.getString('selected_stream');
    final path = prefs.getString('academic_path');

    // Prefer the dynamic structure (structure.txt from the content repo), fall
    // back to the bundled AcademicStructure when it has no data.
    await StructureService.instance.init();
    final structure = StructureService.instance;

    List<String> subjects = [];
    if (path == 'university' || path == 'UNIVERSITY') {
      final semester = prefs.getString('semester') ?? '1';
      final track = prefs.getString('selected_track');
      subjects = structure.universitySubjects(semester, stream, track);
      if (subjects.isEmpty) {
        subjects = AcademicStructure.getUniversitySubjects(
          semester,
          stream ?? 'natural',
          track,
        );
      }
    } else if (grade != null) {
      subjects = structure.highSchoolSubjects(grade, stream);
      if (subjects.isEmpty) {
        subjects = AcademicStructure.getSubjects(grade, stream);
      }
    }

    if (!mounted) return;
    setState(() {
      _userGrade = grade;
      _userStream = stream;
      _subjects = subjects;
      _isLoading = false;
    });
  }

  void _openSubject(String subject) {
    context.push('/subject-portal', extra: {'subject': subject});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadSubjects,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.05,
                    ),
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      final subject = _subjects[index];
                      return _buildSubjectCard(subject);
                    },
                  ),
                ),
    );
  }

  Widget _buildSubjectCard(String subject) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openSubject(subject),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SubjectIconWidget(subject: subject, size: 56),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                subject,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _userGrade == null
                ? 'Complete your academic path to see subjects'
                : 'No subjects available for your path yet',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
