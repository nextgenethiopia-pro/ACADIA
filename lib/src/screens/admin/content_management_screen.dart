import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/constants/academic_structure.dart';

class ContentManagementScreen extends StatefulWidget {
  const ContentManagementScreen({super.key});

  @override
  State<ContentManagementScreen> createState() =>
      _ContentManagementScreenState();
}

class _ContentManagementScreenState extends State<ContentManagementScreen> {
  String _typeFilter = 'All';
  String _subjectFilter = 'All';
  String _chapterFilter = 'All';
  String _statusFilter = 'All';
  String _searchQuery = '';

  List<Map<String, dynamic>> _contentItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  final Set<String> _selectedItems = {};

  int _totalContent = 0;
  int _videoCount = 0;
  int _pdfCount = 0;
  int _jsonCount = 0;

  final List<String> _typeFilters = [
    'All',
    'Video',
    'Short Note',
    'Quiz',
    'Exam',
    'Flashcard',
    'Past Paper',
    'Pending'
  ];

  final List<String> _statusFilters = [
    'All',
    'Approved',
    'Pending',
    'Rejected'
  ];

  List<String> _subjects = ['All'];
  List<String> _chapters = ['All'];

  // Content type colors from ACADIA spec
  final Map<String, Color> _typeColors = {
    'video': const Color(0xFFFF9800), // Orange - Video
    'short_note': const Color(0xFF2196F3), // Blue - PDF/Short Note
    'quiz': const Color(0xFF4CAF50), // Green - Quiz
    'exam': const Color(0xFF9C27B0), // Purple - Exam
    'flashcard': const Color(0xFFE91E63), // Pink - Flashcard
    'past_paper': const Color(0xFF795548), // Brown - Past Paper
  };

  final Map<String, IconData> _typeIcons = {
    'video': Icons.play_circle_outline,
    'short_note': Icons.description_outlined,
    'quiz': Icons.quiz_outlined,
    'exam': Icons.assignment_outlined,
    'flashcard': Icons.style_outlined,
    'past_paper': Icons.folder_open_outlined,
  };

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    try {
      final firebase = FirebaseService();
      final content = await firebase.getDocuments('content',
          orderBy: 'upload_date', descending: true);

      final subjects = <String>{'All'};
      int videos = 0, pdfs = 0, jsons = 0;

      for (final item in content) {
        if (item['subject'] != null) subjects.add(item['subject'].toString());
        final type = item['content_type']?.toString() ?? '';
        if (type == 'video') videos++;
        if (type == 'short_note') pdfs++;
        if (['quiz', 'exam', 'flashcard', 'past_paper'].contains(type)) jsons++;
      }

      setState(() {
        _contentItems = content;
        _filteredItems = List.from(content);
        _totalContent = content.length;
        _videoCount = videos;
        _pdfCount = pdfs;
        _jsonCount = jsons;
        _subjects = subjects.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading content: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error loading content'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _updateChapterOptions(String subject) {
    if (subject == 'All') {
      setState(() => _chapters = ['All']);
      return;
    }

    final chapters = <String>{'All'};

    // Check all high school grade/stream combinations
    for (final grade in ['9', '10', '11', '12']) {
      for (final stream in ['natural', 'social']) {
        final subjectChapters =
            AcademicStructure.getChapters(grade, stream, subject);
        for (final ch in subjectChapters) {
          chapters.add(ch);
        }
      }
    }

    // Also check university subjects
    for (final semester in ['1', '2']) {
      for (final stream in ['natural', 'social']) {
        final uniChapters =
            AcademicStructure.getUniversityChapters(semester, stream, subject);
        for (final ch in uniChapters) {
          chapters.add(ch);
        }
      }
    }

    // If no chapters found from hardcoded data, at least show what's in Firestore
    if (chapters.length == 1) {
      for (final item in _contentItems) {
        if (item['subject']?.toString() == subject && item['chapter'] != null) {
          chapters.add(item['chapter'].toString());
        }
      }
    }

    setState(() => _chapters = chapters.toList()..sort());
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _contentItems.where((item) {
        // Type filter
        if (_typeFilter != 'All') {
          if (_typeFilter == 'Pending') {
            if (item['status']?.toString() != 'pending') return false;
          } else if (_typeFilter == 'Short Note') {
            if (item['content_type']?.toString() != 'short_note') return false;
          } else if (_typeFilter == 'Past Paper') {
            if (item['content_type']?.toString() != 'past_paper') return false;
          } else {
            if (item['content_type']?.toString() != _typeFilter.toLowerCase())
              return false;
          }
        }

        // Status filter
        if (_statusFilter != 'All' &&
            item['status']?.toString().toLowerCase() !=
                _statusFilter.toLowerCase()) {
          return false;
        }

        // Subject filter
        if (_subjectFilter != 'All' &&
            item['subject']?.toString() != _subjectFilter) {
          return false;
        }

        // Chapter filter
        if (_chapterFilter != 'All' &&
            item['chapter']?.toString() != _chapterFilter) {
          return false;
        }

        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final title = item['title']?.toString().toLowerCase() ?? '';
          final subject = item['subject']?.toString().toLowerCase() ?? '';
          final chapter = item['chapter']?.toString().toLowerCase() ?? '';
          final grade = item['grade']?.toString().toLowerCase() ?? '';

          if (!title.contains(query) &&
              !subject.contains(query) &&
              !chapter.contains(query) &&
              !grade.contains(query)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  Future<void> _editContent(Map<String, dynamic> content) async {
    final titleController =
        TextEditingController(text: content['title']?.toString() ?? '');
    final descriptionController =
        TextEditingController(text: content['description']?.toString() ?? '');
    final linkController =
        TextEditingController(text: content['download_url']?.toString() ?? '');
    bool isFree = content['free_content'] == true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Content'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: titleController,
                decoration: const InputDecoration(
                    labelText: 'Title', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Description', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: linkController,
                decoration: const InputDecoration(
                    labelText: 'Internet Archive Link',
                    border: OutlineInputBorder(),
                    helperText: 'https://archive.org/download/...')),
            const SizedBox(height: 12),
            CheckboxListTile(
                value: isFree,
                onChanged: (v) => isFree = v ?? false,
                title: const Text('Free Content'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('SAVE')),
        ],
      ),
    );

    if (result == true) {
      setState(() => _isProcessing = true);
      try {
        final firebase = FirebaseService();
        await firebase.updateDocument('content', content['id'], {
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'download_url': linkController.text.trim(),
          'free_content': isFree,
          'updated_at': DateTime.now().toIso8601String(),
        });
        await _loadContent();
        _applyFilters();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Content updated!'),
              backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) _showError('Error: $e');
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _deleteSingleContent(Map<String, dynamic> content) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: Text(
            'Delete "${content['title']}"? This will permanently remove the content and its metadata from Firebase.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text('DELETE', style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final firebase = FirebaseService();
      await firebase.deleteDocument('content', content['id']);
      await _loadContent();
      _applyFilters();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Content deleted!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _bulkApprove() async {
    if (_selectedItems.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Approve'),
        content: Text(
            'Approve ${_selectedItems.length} content items? This will unlock them for all users.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('APPROVE ALL',
                  style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final firebase = FirebaseService();
      for (final id in _selectedItems) {
        await firebase.updateDocument('content', id, {
          'status': 'approved',
          'approved_at': DateTime.now().toIso8601String()
        });
      }
      setState(() => _selectedItems.clear());
      await _loadContent();
      _applyFilters();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Content approved!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _bulkDelete() async {
    if (_selectedItems.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Delete'),
        content: Text(
            'Permanently delete ${_selectedItems.length} content items? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('DELETE ALL',
                  style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final firebase = FirebaseService();
      for (final id in _selectedItems) {
        await firebase.deleteDocument('content', id);
      }
      setState(() => _selectedItems.clear());
      await _loadContent();
      _applyFilters();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Content deleted!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _addSubject() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Subject'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: controller,
              decoration: const InputDecoration(
                  labelText: 'Subject Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Computer Science')),
          const SizedBox(height: 8),
          const Text(
              'Note: Subjects added here will be available for content organization.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('ADD')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      try {
        final firebase = FirebaseService();
        await firebase.addDocument('subjects',
            {'name': result, 'created_at': DateTime.now().toIso8601String()});
        await _loadContent();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Subject added!'), backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) _showError('Error: $e');
      }
    }
  }

  Future<void> _addChapter() async {
    final subjectController = TextEditingController();
    final chapterController = TextEditingController();
    final gradeController = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Chapter'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Mathematics')),
          const SizedBox(height: 8),
          TextField(
              controller: chapterController,
              decoration: const InputDecoration(
                  labelText: 'Chapter Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Unit 8: Calculus')),
          const SizedBox(height: 8),
          TextField(
              controller: gradeController,
              decoration: const InputDecoration(
                  labelText: 'Grade (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 11 or freshman')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                    'subject': subjectController.text.trim(),
                    'chapter': chapterController.text.trim(),
                    'grade': gradeController.text.trim()
                  }),
              child: const Text('ADD')),
        ],
      ),
    );
    if (result != null &&
        result['subject']!.isNotEmpty &&
        result['chapter']!.isNotEmpty) {
      try {
        final firebase = FirebaseService();
        final chapterData = {
          'subject': result['subject'],
          'name': result['chapter'],
          'created_at': DateTime.now().toIso8601String(),
        };
        if (result['grade']!.isNotEmpty) chapterData['grade'] = result['grade'];
        await firebase.addDocument('chapters', chapterData);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Chapter added!'), backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) _showError('Error: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  String _getFileFormat(String? contentType) {
    switch (contentType?.toLowerCase()) {
      case 'video':
        return 'MP4';
      case 'short_note':
        return 'PDF';
      case 'quiz':
      case 'exam':
      case 'flashcard':
      case 'past_paper':
        return 'JSON';
      default:
        return 'Unknown';
    }
  }

  IconData _getTypeIcon(String? type) =>
      _typeIcons[type?.toLowerCase()] ?? Icons.article;

  Color _getTypeColor(String? type) =>
      _typeColors[type?.toLowerCase()] ?? Colors.grey;

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      DateTime d = date is DateTime ? date : DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Management'),
        leading: IconButton(
            onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        actions: [
          if (_isProcessing)
            const Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))),
          PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'add_subject') _addSubject();
              if (action == 'add_chapter') _addChapter();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'add_subject',
                  child: Row(children: [
                    Icon(Icons.add, size: 18),
                    SizedBox(width: 8),
                    Text('Add Subject')
                  ])),
              const PopupMenuItem(
                  value: 'add_chapter',
                  child: Row(children: [
                    Icon(Icons.add, size: 18),
                    SizedBox(width: 8),
                    Text('Add Chapter')
                  ])),
            ],
            icon: const Icon(Icons.edit_note),
            tooltip: 'Edit Structure',
          ),
        ],
      ),
      body: Column(children: [
        // Stats bar
        Container(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              _buildStatCard('Total', _totalContent, AppColors.primary),
              const SizedBox(width: 8),
              _buildStatCard('Videos', _videoCount, _typeColors['video']!),
              const SizedBox(width: 8),
              _buildStatCard('PDFs', _pdfCount, _typeColors['short_note']!),
              const SizedBox(width: 8),
              _buildStatCard('JSON', _jsonCount, _typeColors['quiz']!),
            ])),

        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by title, subject, or chapter...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => _searchQuery = '');
                        _applyFilters();
                      })
                  : null,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) {
              _searchQuery = v;
              _applyFilters();
            },
          ),
        ),

        // Type filter chips
        SizedBox(
            height: 50,
            child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _typeFilters.length,
                itemBuilder: (context, index) {
                  final filter = _typeFilters[index];
                  final isSelected = _typeFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (v) {
                        setState(() => _typeFilter = filter);
                        _applyFilters();
                      },
                      selectedColor: AppColors.primary.withAlpha((255 * 0.2).toInt()),
                    ),
                  );
                })),

        // Subject, Chapter & Status dropdowns
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(
                  child: DropdownButtonFormField<String>(
                      value: _subjectFilter,
                      decoration: InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8)),
                      style: const TextStyle(fontSize: 13),
                      items: _subjects
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _subjectFilter = v ?? 'All';
                          _chapterFilter = 'All';
                        });
                        _updateChapterOptions(_subjectFilter);
                        _applyFilters();
                      })),
              const SizedBox(width: 8),
              Expanded(
                  child: DropdownButtonFormField<String>(
                      value: _chapterFilter,
                      decoration: InputDecoration(
                          labelText: 'Chapter',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8)),
                      style: const TextStyle(fontSize: 13),
                      items: _chapters
                          .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) {
                        _chapterFilter = v ?? 'All';
                        _applyFilters();
                      })),
              const SizedBox(width: 8),
              Expanded(
                  child: DropdownButtonFormField<String>(
                      value: _statusFilter,
                      decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8)),
                      style: const TextStyle(fontSize: 13),
                      items: _statusFilters
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        _statusFilter = v ?? 'All';
                        _applyFilters();
                      })),
            ])),

        // Select All & count
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              InkWell(
                  onTap: () {
                    setState(() {
                      if (_selectedItems.length == _filteredItems.length &&
                          _filteredItems.isNotEmpty) {
                        _selectedItems.clear();
                      } else {
                        _selectedItems.clear();
                        for (final item in _filteredItems) {
                          _selectedItems.add(item['id'].toString());
                        }
                      }
                    });
                  },
                  child: Row(children: [
                    Icon(
                        _selectedItems.length == _filteredItems.length &&
                                _filteredItems.isNotEmpty
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 20,
                        color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('Select All',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13))
                  ])),
              const Spacer(),
              Text('${_filteredItems.length} items',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ])),

        // Bulk actions
        if (_selectedItems.isNotEmpty)
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primary.withAlpha(((255 * 0.05)).toInt()),
              child: Row(children: [
                Text('${_selectedItems.length} selected',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                    onPressed: _bulkApprove,
                    icon: const Icon(Icons.check_circle,
                        color: Colors.green, size: 18),
                    label: const Text('Approve',
                        style: TextStyle(color: Colors.green))),
                const SizedBox(width: 8),
                TextButton.icon(
                    onPressed: _bulkDelete,
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    label: const Text('Delete',
                        style: TextStyle(color: Colors.red)))
              ])),

        // Content list
        Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            Icon(Icons.folder_open,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('No content found',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 16))
                          ]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final itemId = item['id']?.toString() ?? '';
                          final isSelected = _selectedItems.contains(itemId);
                          final contentType =
                              item['content_type']?.toString() ?? '';
                          final status = item['status']?.toString() ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    width: isSelected ? 2 : 0)),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedItems.remove(itemId);
                                  } else {
                                    _selectedItems.add(itemId);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Row(children: [
                                      Checkbox(
                                          value: isSelected,
                                          onChanged: (v) {
                                            setState(() {
                                              if (v == true) {
                                                _selectedItems.add(itemId);
                                              } else {
                                                _selectedItems.remove(itemId);
                                              }
                                            });
                                          },
                                          activeColor: AppColors.primary),
                                      Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                              color: _getTypeColor(contentType)
                                                  .withAlpha(((255 * 0.1)).toInt()),
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: Icon(_getTypeIcon(contentType),
                                              color: _getTypeColor(contentType),
                                              size: 22)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                item['title']?.toString() ??
                                                    'Untitled',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            const SizedBox(height: 2),
                                            Text(
                                                '${item['subject']?.toString() ?? ''} • ${item['chapter']?.toString() ?? ''}',
                                                style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            const SizedBox(height: 4),
                                            Row(children: [
                                              Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2),
                                                  decoration: BoxDecoration(
                                                      color: _getStatusColor(status)
                                                          .withAlpha(((255 * 0.1)).toInt()),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      border: Border.all(
                                                          color: _getStatusColor(status)
                                                              .withOpacity(
                                                                  0.3))),
                                                  child: Text(status.toUpperCase(),
                                                      style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: _getStatusColor(status)))),
                                              const SizedBox(width: 4),
                                              Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                      color: _getTypeColor(
                                                              contentType)
                                                          .withAlpha(((255 * 0.1)).toInt()),
                                                      borderRadius: BorderRadius
                                                          .circular(8)),
                                                  child: Text(
                                                      _getFileFormat(
                                                          contentType),
                                                      style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: _getTypeColor(
                                                              contentType)))),
                                              if (item['free_content'] ==
                                                  true) ...[
                                                const SizedBox(width: 4),
                                                Container(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 6,
                                                            vertical: 2),
                                                    decoration:
                                                        BoxDecoration(
                                                            color: Colors.blue
                                                                .withOpacity(
                                                                    0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8)),
                                                    child: const Text('FREE',
                                                        style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Colors.blue)))
                                              ],
                                              const SizedBox(width: 8),
                                              Icon(Icons.calendar_today,
                                                  size: 10,
                                                  color: Colors.grey[500]),
                                              const SizedBox(width: 2),
                                              Text(
                                                  _formatDate(
                                                      item['upload_date']),
                                                  style: TextStyle(
                                                      color: Colors.grey[500],
                                                      fontSize: 10)),
                                              const SizedBox(width: 8),
                                              Icon(Icons.download,
                                                  size: 10,
                                                  color: Colors.grey[500]),
                                              const SizedBox(width: 2),
                                              Text(
                                                  '${item['download_count'] ?? 0}',
                                                  style: TextStyle(
                                                      color: Colors.grey[500],
                                                      fontSize: 10)),
                                            ]),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (action) {
                                          if (action == 'edit')
                                            _editContent(item);
                                          if (action == 'approve') {
                                            FirebaseService().updateDocument(
                                                'content', itemId, {
                                              'status': 'approved'
                                            }).then((_) {
                                              _loadContent();
                                              _applyFilters();
                                            });
                                          }
                                          if (action == 'delete')
                                            _deleteSingleContent(item);
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(children: [
                                                Icon(Icons.edit, size: 18),
                                                SizedBox(width: 8),
                                                Text('Edit')
                                              ])),
                                          if (status == 'pending')
                                            const PopupMenuItem(
                                                value: 'approve',
                                                child: Row(children: [
                                                  Icon(Icons.check_circle,
                                                      size: 18,
                                                      color: Colors.green),
                                                  SizedBox(width: 8),
                                                  Text('Approve',
                                                      style: TextStyle(
                                                          color: Colors.green))
                                                ])),
                                          const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(children: [
                                                Icon(Icons.delete,
                                                    size: 18,
                                                    color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Delete',
                                                    style: TextStyle(
                                                        color: Colors.red))
                                              ])),
                                        ],
                                      ),
                                    ]),
                                    // Show Internet Archive link when expanded (optional)
                                    if (item['download_url'] != null &&
                                        item['download_url']
                                            .toString()
                                            .contains('archive.org'))
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 8, left: 48),
                                        child: Row(
                                          children: [
                                            Icon(Icons.archive,
                                                size: 12,
                                                color: Colors.grey[400]),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                item['download_url'].toString(),
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey[500]),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        })),
      ]),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                color: color.withAlpha(((255 * 0.1)).toInt()),
                borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Text(count.toString(),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18, color: color)),
              Text(label, style: TextStyle(fontSize: 10, color: color))
            ])));
  }
}
