import 'package:flutter/material.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/constants/colors.dart';

class EntranceManagementScreen extends StatefulWidget {
  const EntranceManagementScreen({super.key});

  @override
  State<EntranceManagementScreen> createState() =>
      _EntranceManagementScreenState();
}

class _EntranceManagementScreenState extends State<EntranceManagementScreen> {
  List<Map<String, dynamic>> _allMaterials = [];
  List<Map<String, dynamic>> _filteredMaterials = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filters
  String _selectedType = 'All';
  String _selectedStream = 'All';
  String _selectedSubject = 'All';
  String _selectedYear = 'All';
  String _selectedGrade = 'All';
  String _selectedChapter = 'All';

  // Available years (dynamically populated from uploaded content)
  Set<String> _availableYears = {};
  Set<String> _availableGrades = {};

  final List<String> _types = ['All', 'past_paper', 'entrance_exam'];
  final List<String> _streams = ['All', 'natural_science', 'social_science'];
  List<String> _subjects = ['All'];
  List<String> _years = ['All'];
  List<String> _grades = ['All'];
  List<String> _chapters = ['All'];

  // Subject mapping by stream (from ACADIA spec)
  final Map<String, List<String>> _subjectsByStream = {
    'natural_science': [
      'Mathematics', 
      'English', 
      'Biology', 
      'Chemistry', 
      'Physics', 
      'Aptitude'
    ],
    'social_science': [
      'Mathematics', 
      'English', 
      'Aptitude', 
      'Economics', 
      'Geography', 
      'History'
    ],
  };

  // Subject colors from ACADIA spec
  final Map<String, Color> _subjectColors = {
    'Mathematics': const Color(0xFF9C27B0), // Purple
    'English': const Color(0xFF2196F3),     // Blue
    'Physics': const Color(0xFFFF9800),     // Orange
    'Chemistry': const Color(0xFF4CAF50),   // Green
    'Biology': const Color(0xFFE91E63),     // Pink
    'Aptitude': const Color(0xFF708090),    // Slate Grey
    'Geography': const Color(0xFF009688),   // Teal
    'History': const Color(0xFF795548),     // Brown
    'Economics': const Color(0xFFFF5722),   // Deep Orange
  };

  @override
  void initState() {
    super.initState();
    _updateSubjectOptions();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final firebaseService = FirebaseService();

      final allMaterials = await firebaseService.getDocuments(
        'entrance_materials',
        orderBy: 'created_at',
        descending: true,
      );

      // Extract available years and grades from the data
      final years = <String>{};
      final grades = <String>{};
      for (final material in allMaterials) {
        final year = material['year']?.toString();
        if (year != null && year.isNotEmpty) {
          years.add(year);
        }
        final grade = material['grade']?.toString();
        if (grade != null && grade.isNotEmpty) {
          grades.add(grade);
        }
      }

      setState(() {
        _allMaterials = allMaterials;
        _filteredMaterials = List.from(allMaterials);
        _availableYears = years;
        _availableGrades = grades;
        _years = ['All', ...years.toList()..sort((a, b) => b.compareTo(a))];
        _grades = ['All', ...grades.toList()..sort()];
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading entrance data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading entrance materials'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredMaterials = _allMaterials.where((material) {
        // Type filter
        if (_selectedType != 'All' && material['type']?.toString() != _selectedType) {
          return false;
        }

        // Stream filter
        if (_selectedStream != 'All' && material['stream']?.toString() != _selectedStream) {
          return false;
        }

        // Subject filter
        if (_selectedSubject != 'All' && material['subject']?.toString() != _selectedSubject) {
          return false;
        }

        // Year filter
        if (_selectedYear != 'All' && material['year']?.toString() != _selectedYear) {
          return false;
        }

        // Grade filter
        if (_selectedGrade != 'All' && material['grade']?.toString() != _selectedGrade) {
          return false;
        }

        // Chapter filter
        if (_selectedChapter != 'All' && material['chapter']?.toString() != _selectedChapter) {
          return false;
        }

        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final title = material['title']?.toString().toLowerCase() ?? '';
          final subject = material['subject']?.toString().toLowerCase() ?? '';
          final description = material['description']?.toString().toLowerCase() ?? '';
          final year = material['year']?.toString().toLowerCase() ?? '';
          final grade = material['grade']?.toString().toLowerCase() ?? '';
          final chapter = material['chapter']?.toString().toLowerCase() ?? '';

          if (!title.contains(query) &&
              !subject.contains(query) &&
              !description.contains(query) &&
              !year.contains(query) &&
              !grade.contains(query) &&
              !chapter.contains(query)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _updateSubjectOptions() {
    if (_selectedStream == 'All') {
      setState(() {
        _subjects = [
          'All',
          ..._subjectsByStream.values.expand((s) => s).toSet().toList()
        ]..sort();
      });
    } else {
      final streamSubjects = _subjectsByStream[_selectedStream] ?? [];
      setState(() {
        _subjects = ['All', ...streamSubjects];
        if (!_subjects.contains(_selectedSubject)) {
          _selectedSubject = 'All';
        }
      });
    }
    _applyFilters();
  }

  bool _validateInternetArchiveUrl(String url) {
    return url.contains('archive.org') && 
           (url.contains('/download/') || url.contains('/details/'));
  }

  Future<void> _addMaterial() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final urlController = TextEditingController();
    final yearController = TextEditingController();
    final questionCountController = TextEditingController();
    final timeLimitController = TextEditingController();

    String selectedType = 'past_paper';
    String selectedStream = 'natural_science';
    String selectedSubject = 'Mathematics';
    String selectedGrade = '9';
    String selectedChapter = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Entrance Material'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.archive, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Files must be uploaded to Internet Archive first. Paste the download link below.',
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Type
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _types.where((t) => t != 'All').map((type) {
                    String label = type == 'past_paper' ? 'Past Paper' : 'Entrance Exam';
                    return DropdownMenuItem(value: type, child: Text(label));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedType = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Stream
                DropdownButtonFormField<String>(
                  value: selectedStream,
                  decoration: const InputDecoration(
                    labelText: 'Stream',
                    border: OutlineInputBorder(),
                  ),
                  items: _streams.where((s) => s != 'All').map((stream) {
                    final displayName = stream == 'natural_science' ? 'Natural Science' : 'Social Science';
                    return DropdownMenuItem(value: stream, child: Text(displayName));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedStream = value!;
                      final streamSubjects = _subjectsByStream[selectedStream] ?? [];
                      selectedSubject = streamSubjects.isNotEmpty ? streamSubjects.first : 'Mathematics';
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Subject
                DropdownButtonFormField<String>(
                  value: selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  items: (_subjectsByStream[selectedStream] ?? []).map((subject) {
                    final color = _subjectColors[subject] ?? Colors.grey;
                    return DropdownMenuItem(
                      value: subject, 
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(subject),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedSubject = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Year - FREE TEXT INPUT (Past Paper only)
                if (selectedType == 'past_paper') ...[
                  TextField(
                    controller: yearController,
                    decoration: const InputDecoration(
                      labelText: 'Year (e.g., 2024)',
                      hintText: 'Enter the exam year',
                      border: OutlineInputBorder(),
                      helperText: 'Free text - can be any year',
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),
                ],

                // Grade (Entrance Exam only)
                if (selectedType == 'entrance_exam') ...[
                  DropdownButtonFormField<String>(
                    value: selectedGrade,
                    decoration: const InputDecoration(
                      labelText: 'Grade',
                      border: OutlineInputBorder(),
                    ),
                    items: ['9', '10', '11', '12'].map((grade) {
                      return DropdownMenuItem(value: grade, child: Text('Grade $grade'));
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedGrade = value!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Chapter - FREE TEXT INPUT
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Chapter',
                      hintText: 'e.g., Unit 1: Introduction to Biology',
                      border: OutlineInputBorder(),
                      helperText: 'Free text - describe the chapter',
                    ),
                    onChanged: (value) => selectedChapter = value,
                  ),
                  const SizedBox(height: 16),
                ],

                // Number of Questions
                TextField(
                  controller: questionCountController,
                  decoration: const InputDecoration(
                    labelText: 'Number of Questions',
                    hintText: 'e.g., 65',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Time Limit (Past Paper only)
                if (selectedType == 'past_paper') ...[
                  TextField(
                    controller: timeLimitController,
                    decoration: const InputDecoration(
                      labelText: 'Time Limit (minutes)',
                      hintText: 'e.g., 120',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                ],

                // Internet Archive URL
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'Internet Archive URL',
                    hintText: 'https://archive.org/download/...',
                    border: OutlineInputBorder(),
                    helperText: 'Paste the direct download link from Internet Archive',
                    prefixIcon: Icon(Icons.archive),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a title'), backgroundColor: Colors.red),
                  );
                  return;
                }
                if (urlController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter Internet Archive URL'), backgroundColor: Colors.red),
                  );
                  return;
                }
                if (!_validateInternetArchiveUrl(urlController.text.trim())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid Internet Archive URL'), backgroundColor: Colors.red),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        setState(() => _isProcessing = true);
        final firebaseService = FirebaseService();

        final materialData = {
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'type': selectedType,
          'stream': selectedStream,
          'subject': selectedSubject,
          'year': selectedType == 'past_paper' ? yearController.text.trim() : null,
          'grade': selectedType == 'entrance_exam' ? selectedGrade : null,
          'chapter': selectedType == 'entrance_exam' ? selectedChapter : null,
          'total_questions': int.tryParse(questionCountController.text.trim()) ?? 0,
          'time_limit_minutes': selectedType == 'past_paper' ? int.tryParse(timeLimitController.text.trim()) ?? 0 : null,
          'url': urlController.text.trim(),
          'storage_provider': 'internet_archive', // Changed from cloudinary
          'created_at': DateTime.now().toIso8601String(),
          'created_by': 'admin',
          'status': 'active',
          'download_count': 0,
        };

        await firebaseService.addDocument('entrance_materials', materialData);
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Material added successfully to Internet Archive!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding material: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  Future<void> _editMaterial(Map<String, dynamic> material) async {
    final titleController = TextEditingController(text: material['title']?.toString() ?? '');
    final descriptionController = TextEditingController(text: material['description']?.toString() ?? '');
    final urlController = TextEditingController(text: material['url']?.toString() ?? '');
    final yearController = TextEditingController(text: material['year']?.toString() ?? '');
    final questionCountController = TextEditingController(text: material['total_questions']?.toString() ?? '');
    final timeLimitController = TextEditingController(text: material['time_limit_minutes']?.toString() ?? '');

    String selectedType = material['type']?.toString() ?? 'past_paper';
    String selectedStream = material['stream']?.toString() ?? 'natural_science';
    String selectedSubject = material['subject']?.toString() ?? 'Mathematics';
    String selectedGrade = material['grade']?.toString() ?? '9';
    String selectedChapter = material['chapter']?.toString() ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Entrance Material'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Type (Disabled for edit to prevent inconsistencies)
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                    helperText: 'Type cannot be changed after creation',
                  ),
                  items: _types.where((t) => t != 'All').map((type) {
                    String label = type == 'past_paper' ? 'Past Paper' : 'Entrance Exam';
                    return DropdownMenuItem(value: type, child: Text(label));
                  }).toList(),
                  onChanged: null, // Disabled
                ),
                const SizedBox(height: 16),

                // Stream
                DropdownButtonFormField<String>(
                  value: selectedStream,
                  decoration: const InputDecoration(
                    labelText: 'Stream',
                    border: OutlineInputBorder(),
                  ),
                  items: _streams.where((s) => s != 'All').map((stream) {
                    final displayName = stream == 'natural_science' ? 'Natural Science' : 'Social Science';
                    return DropdownMenuItem(value: stream, child: Text(displayName));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedStream = value!;
                      final streamSubjects = _subjectsByStream[selectedStream] ?? [];
                      selectedSubject = streamSubjects.isNotEmpty ? streamSubjects.first : 'Mathematics';
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Subject
                DropdownButtonFormField<String>(
                  value: selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  items: (_subjectsByStream[selectedStream] ?? []).map((subject) {
                    return DropdownMenuItem(value: subject, child: Text(subject));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedSubject = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Year (Past Paper only)
                if (selectedType == 'past_paper') ...[
                  TextField(
                    controller: yearController,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),
                ],

                // Grade (Entrance Exam only)
                if (selectedType == 'entrance_exam') ...[
                  DropdownButtonFormField<String>(
                    value: selectedGrade,
                    decoration: const InputDecoration(
                      labelText: 'Grade',
                      border: OutlineInputBorder(),
                    ),
                    items: ['9', '10', '11', '12'].map((grade) {
                      return DropdownMenuItem(value: grade, child: Text('Grade $grade'));
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedGrade = value!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Chapter
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Chapter',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: selectedChapter),
                    onChanged: (value) => selectedChapter = value,
                  ),
                  const SizedBox(height: 16),
                ],

                // Number of Questions
                TextField(
                  controller: questionCountController,
                  decoration: const InputDecoration(
                    labelText: 'Number of Questions',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Time Limit (Past Paper only)
                if (selectedType == 'past_paper') ...[
                  TextField(
                    controller: timeLimitController,
                    decoration: const InputDecoration(
                      labelText: 'Time Limit (minutes)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                ],

                // Internet Archive URL
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'Internet Archive URL',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.archive),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty &&
                    urlController.text.trim().isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        setState(() => _isProcessing = true);
        final firebaseService = FirebaseService();

        final updatedData = {
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'stream': selectedStream,
          'subject': selectedSubject,
          'year': selectedType == 'past_paper' ? yearController.text.trim() : null,
          'grade': selectedType == 'entrance_exam' ? selectedGrade : null,
          'chapter': selectedType == 'entrance_exam' ? selectedChapter : null,
          'total_questions': int.tryParse(questionCountController.text.trim()) ?? 0,
          'time_limit_minutes': selectedType == 'past_paper' ? int.tryParse(timeLimitController.text.trim()) ?? 0 : null,
          'url': urlController.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': 'admin',
        };

        await firebaseService.updateDocument('entrance_materials', material['id'], updatedData);
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Material updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating material: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  Future<void> _deleteMaterial(Map<String, dynamic> material) async {
    final materialId = material['id']?.toString() ?? '';
    final title = material['title']?.toString() ?? 'this material';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete "$title"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && materialId.isNotEmpty) {
      try {
        setState(() => _isProcessing = true);
        final firebaseService = FirebaseService();

        await firebaseService.deleteDocument('entrance_materials', materialId);
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Material deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting material: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  Widget _buildMaterialCard(Map<String, dynamic> material) {
    final type = material['type']?.toString() ?? '';
    final title = material['title']?.toString() ?? 'Untitled';
    final subject = material['subject']?.toString() ?? '';
    final stream = material['stream']?.toString() ?? '';
    final year = material['year']?.toString() ?? '';
    final grade = material['grade']?.toString() ?? '';
    final chapter = material['chapter']?.toString() ?? '';
    final totalQuestions = material['total_questions']?.toString() ?? '0';
    final timeLimit = material['time_limit_minutes']?.toString() ?? '';
    final downloadCount = material['download_count']?.toString() ?? '0';
    final url = material['url']?.toString() ?? '';

    IconData icon;
    Color color;
    String subtitle;

    if (type == 'past_paper') {
      icon = Icons.description;
      color = Colors.blue;
      subtitle = '$subject${year.isNotEmpty ? ' - $year' : ''}';
      if (totalQuestions != '0') subtitle += ' • $totalQuestions questions';
      if (timeLimit.isNotEmpty) subtitle += ' • $timeLimit min';
    } else {
      icon = Icons.quiz;
      color = Colors.orange;
      subtitle = '$subject${grade.isNotEmpty ? ' - Grade $grade' : ''}';
      if (chapter.isNotEmpty) subtitle += ' - $chapter';
      if (totalQuestions != '0') subtitle += ' • $totalQuestions questions';
    }

    final subjectColor = _subjectColors[subject] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: subjectColor.withAlpha((255 * 0.1).toInt()),
          child: Icon(icon, color: subjectColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (url.contains('archive.org'))
              const SizedBox(height: 4),
            if (url.contains('archive.org'))
              Row(
                children: [
                  Icon(Icons.archive, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      url,
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 2),
                  Text(
                    downloadCount,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'edit') {
                  _editMaterial(material);
                } else if (action == 'delete') {
                  _deleteMaterial(material);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _editMaterial(material),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrance Management'),
        actions: [
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title, subject, year...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _applyFilters();
              },
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredMaterials.length} materials',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const Spacer(),
                // Internet Archive badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.archive, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Internet Archive',
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMaterials.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No entrance materials found',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to add materials from Internet Archive',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredMaterials.length,
                        itemBuilder: (context, index) {
                          return _buildMaterialCard(_filteredMaterials[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMaterial,
        icon: const Icon(Icons.add),
        label: const Text('Add Material'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}