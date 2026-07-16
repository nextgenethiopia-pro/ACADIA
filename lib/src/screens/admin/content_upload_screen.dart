import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/widgets/common/gradient_button.dart';
import 'package:acadia/src/utils/academic_structure.dart';

class ContentUploadScreen extends StatefulWidget {
  const ContentUploadScreen({super.key});

  @override
  State<ContentUploadScreen> createState() => _ContentUploadScreenState();
}

class _ContentUploadScreenState extends State<ContentUploadScreen> {
  // Path selection
  String? _selectedCategory;
  String? _selectedEntranceType;

  // High School
  String? _selectedGrade;
  String? _selectedStream;

  // University
  String? _selectedYear;
  String? _selectedSemester;
  String? _selectedTrack;

  // Common
  String? _selectedSubject;
  String? _selectedChapter;
  String? _selectedContentType;

  // Entrance specific
  String? _selectedEntranceGrade;
  String? _selectedEntranceChapter;

  // Internet Archive Link
  final _internetArchiveLinkController = TextEditingController();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _yearController = TextEditingController();
  final _questionCountController = TextEditingController();
  final _timeLimitController = TextEditingController();
  final _pageCountController = TextEditingController();
  final _cardCountController = TextEditingController();

  bool _isFree = false;
  bool _isUploading = false;

  List<String> _subjects = [];
  List<String> _chapters = [];

  final List<String> _contentTypes = AcademicStructure.contentTypes;

  final Map<String, String> _contentTypeIcons = {
    'video': '🎬',
    'short_note': '📝',
    'quiz': '❓',
    'exam': '📋',
    'flashcard': '🃏',
    'past_paper': '📄',
  };

  @override
  void dispose() {
    _internetArchiveLinkController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _yearController.dispose();
    _questionCountController.dispose();
    _timeLimitController.dispose();
    _pageCountController.dispose();
    _cardCountController.dispose();
    super.dispose();
  }

  void _updateSubjects() {
    setState(() {
      _subjects = [];
      _selectedSubject = null;
      _chapters = [];
      _selectedChapter = null;

      if (_selectedCategory == 'high_school' && _selectedGrade != null) {
        _subjects = AcademicStructure.getSubjects(
          _selectedGrade!,
          _selectedStream,
        );
      } else if (_selectedCategory == 'university' &&
          _selectedYear == 'freshman' &&
          _selectedSemester != null) {
        _subjects = AcademicStructure.getUniversitySubjects(
          _selectedSemester!,
          _selectedStream ?? 'natural',
          _selectedTrack,
        );
      }
    });
  }

  void _updateChapters() {
    if (_selectedSubject == null) return;
    
    setState(() {
      _chapters = [];
      _selectedChapter = null;
    });

    if (_selectedCategory == 'high_school' && _selectedGrade != null) {
      _chapters = AcademicStructure.getChapters(
        _selectedGrade!,
        _selectedStream ?? 'natural',
        _selectedSubject!,
      );
    } else if (_selectedCategory == 'university' &&
        _selectedYear == 'freshman' &&
        _selectedSemester != null) {
      _chapters = AcademicStructure.getUniversityChapters(
        _selectedSemester!,
        _selectedStream ?? 'natural',
        _selectedSubject!,
        _selectedTrack,
      );
    }
  }

  void _resetSelections() {
    setState(() {
      _selectedGrade = null;
      _selectedStream = null;
      _selectedYear = null;
      _selectedSemester = null;
      _selectedTrack = null;
      _selectedSubject = null;
      _selectedChapter = null;
      _selectedContentType = null;
      _selectedEntranceType = null;
      _selectedEntranceGrade = null;
      _selectedEntranceChapter = null;
      _subjects = [];
      _chapters = [];
    });
  }

  String _buildBreadcrumbPath() {
    final parts = <String>[];
    if (_selectedCategory == 'high_school') {
      parts.add('High School');
      if (_selectedGrade != null) parts.add('Grade $_selectedGrade');
      if (_selectedStream != null)
        parts.add(_selectedStream == 'natural' ? 'Natural Science' : 'Social Science');
    } else if (_selectedCategory == 'university') {
      parts.add('University');
      parts.add('Freshman');
      if (_selectedSemester != null) parts.add('Semester $_selectedSemester');
      if (_selectedTrack != null)
        parts.add(_selectedTrack == 'pre-engineering_courses'
            ? 'Pre-Engineering'
            : 'Other Natural Science');
    }
    if (_selectedSubject != null) parts.add(_selectedSubject!);
    if (_selectedChapter != null) parts.add(_selectedChapter!);
    if (_selectedContentType != null)
      parts.add(AcademicStructure.contentTypeDisplayNames[_selectedContentType] ?? _selectedContentType!);
    return parts.join(' › ');
  }

  Future<void> _uploadContent() async {
    if (!_validateForm()) return;
    
    setState(() => _isUploading = true);
    
    try {
      final firebase = FirebaseService();
      
      final contentData = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'download_url': _internetArchiveLinkController.text.trim(),
        'storage_provider': 'internet_archive',
        'content_type': _selectedContentType,
        'category': _selectedCategory,
        'free_content': _isFree,
        'upload_date': DateTime.now().toIso8601String(),
        'uploaded_by': FirebaseAuth.instance.currentUser?.email ?? 'admin',
        'status': 'approved',
        'download_count': 0,
        'version': 1,
      };

      // Add academic path metadata
      if (_selectedCategory == 'high_school') {
        contentData['school_level'] = 'high-school';
        contentData['grade'] = _selectedGrade;
        if (_selectedStream != null) contentData['stream'] = _selectedStream;
        contentData['subject'] = _selectedSubject;
        contentData['chapter'] = _selectedChapter;
      } else if (_selectedCategory == 'university') {
        contentData['school_level'] = 'university';
        contentData['university_year'] = 'freshman';
        contentData['semester'] = _selectedSemester;
        if (_selectedTrack != null) contentData['track'] = _selectedTrack;
        contentData['subject'] = _selectedSubject;
        contentData['chapter'] = _selectedChapter;
      }

      // Add content-type specific metadata
      switch (_selectedContentType) {
        case 'video':
          contentData['file_format'] = 'mp4';
          break;
        case 'short_note':
          contentData['file_format'] = 'pdf';
          contentData['page_count'] = int.tryParse(_pageCountController.text.trim()) ?? 0;
          break;
        case 'quiz':
        case 'exam':
          contentData['file_format'] = 'json';
          contentData['total_questions'] = int.tryParse(_questionCountController.text.trim()) ?? 0;
          contentData['time_limit_minutes'] = int.tryParse(_timeLimitController.text.trim()) ?? 0;
          break;
        case 'flashcard':
          contentData['file_format'] = 'json';
          contentData['total_cards'] = int.tryParse(_cardCountController.text.trim()) ?? 0;
          break;
        case 'past_paper':
          contentData['file_format'] = 'json';
          contentData['total_questions'] = int.tryParse(_questionCountController.text.trim()) ?? 0;
          break;
      }

      await firebase.addDocument('content', contentData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content uploaded successfully to Internet Archive!'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        _showError('Error uploading content: $e');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  bool _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a title');
      return false;
    }
    
    if (_internetArchiveLinkController.text.trim().isEmpty) {
      _showError('Please enter the Internet Archive link');
      return false;
    }
    
    // Validate Internet Archive URL format
    final url = _internetArchiveLinkController.text.trim();
    if (!url.contains('archive.org')) {
      _showError('Please enter a valid Internet Archive URL (should contain archive.org)');
      return false;
    }
    
    if (_selectedCategory == null) {
      _showError('Please select a content category');
      return false;
    }
    
    if (_selectedContentType == null) {
      _showError('Please select a content type');
      return false;
    }

    if (_selectedCategory == 'high_school' && _selectedGrade == null) {
      _showError('Please select a grade');
      return false;
    }

    if (_selectedCategory == 'high_school' && _selectedSubject == null) {
      _showError('Please select a subject');
      return false;
    }

    if (_selectedCategory == 'high_school' && _selectedChapter == null) {
      _showError('Please select a chapter');
      return false;
    }

    if (_selectedCategory == 'university' && _selectedSemester == null) {
      _showError('Please select a semester');
      return false;
    }

    if (_selectedCategory == 'university' && _selectedSubject == null) {
      _showError('Please select a subject');
      return false;
    }

    if (_selectedCategory == 'university' && _selectedChapter == null) {
      _showError('Please select a chapter');
      return false;
    }

    // Validate numeric fields
    if (_selectedContentType == 'quiz' || _selectedContentType == 'exam') {
      if (_questionCountController.text.trim().isEmpty) {
        _showError('Please enter number of questions');
        return false;
      }
      if (_timeLimitController.text.trim().isEmpty) {
        _showError('Please enter time limit');
        return false;
      }
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red)
    );
  }

  void _clearForm() {
    _internetArchiveLinkController.clear();
    _titleController.clear();
    _descriptionController.clear();
    _yearController.clear();
    _questionCountController.clear();
    _timeLimitController.clear();
    _pageCountController.clear();
    _cardCountController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedEntranceType = null;
      _selectedGrade = null;
      _selectedStream = null;
      _selectedYear = null;
      _selectedSemester = null;
      _selectedTrack = null;
      _selectedSubject = null;
      _selectedChapter = null;
      _selectedContentType = null;
      _selectedEntranceGrade = null;
      _selectedEntranceChapter = null;
      _isFree = false;
      _subjects = [];
      _chapters = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Content to Internet Archive'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (_selectedCategory != null && _selectedSubject != null)
            IconButton(
              onPressed: _clearForm,
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset all selections',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Internet Archive Info Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.archive, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Internet Archive Hosting',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '1. Upload your file to archive.org\n2. Copy the download link\n3. Paste the link below',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Select Category'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _buildCategoryCard(
                  'High School',
                  'Grades 9-12',
                  Icons.school,
                  'high_school'
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCategoryCard(
                  'University',
                  'Freshman',
                  Icons.account_balance,
                  'university'
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // Breadcrumb navigation
            if (_selectedCategory != null && _selectedSubject != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.navigation, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _buildBreadcrumbPath(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // HIGH SCHOOL PATH
            if (_selectedCategory == 'high_school') ...[
              _buildSectionTitle('Select Grade'),
              _buildGradeSelector(),
              const SizedBox(height: 16),
              
              if (_selectedGrade != null && 
                  (_selectedGrade == '11' || _selectedGrade == '12')) ...[
                _buildSectionTitle('Select Stream'),
                Row(children: [
                  Expanded(
                    child: _buildStreamCard(
                      'Natural Science',
                      Icons.science,
                      _selectedStream == 'natural',
                      () {
                        setState(() {
                          _selectedStream = 'natural';
                          _selectedSubject = null;
                          _selectedChapter = null;
                        });
                        _updateSubjects();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStreamCard(
                      'Social Science',
                      Icons.menu_book,
                      _selectedStream == 'social',
                      () {
                        setState(() {
                          _selectedStream = 'social';
                          _selectedSubject = null;
                          _selectedChapter = null;
                        });
                        _updateSubjects();
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
              ],
              
              if (_subjects.isNotEmpty) ...[
                _buildSectionTitle('Select Subject'),
                _buildSubjectGrid(),
                const SizedBox(height: 16),
              ],
              
              if (_selectedSubject != null && _chapters.isNotEmpty) ...[
                _buildSectionTitle('Select Chapter'),
                _buildChapterGrid(),
                const SizedBox(height: 16),
              ],
            ],

            // UNIVERSITY PATH
            if (_selectedCategory == 'university') ...[
              _buildSectionTitle('Select Semester'),
              Row(children: [
                Expanded(
                  child: _buildSemesterCard(
                    'Semester 1',
                    Icons.looks_one,
                    _selectedSemester == '1',
                    () {
                      setState(() {
                        _selectedSemester = '1';
                        _selectedStream = null;
                        _selectedTrack = null;
                        _selectedSubject = null;
                        _selectedChapter = null;
                      });
                      _updateSubjects();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSemesterCard(
                    'Semester 2',
                    Icons.looks_two,
                    _selectedSemester == '2',
                    () {
                      setState(() {
                        _selectedSemester = '2';
                        _selectedStream = null;
                        _selectedTrack = null;
                        _selectedSubject = null;
                        _selectedChapter = null;
                      });
                      _updateSubjects();
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              
              if (_selectedSemester == '1') ...[
                _buildSectionTitle('Select Stream'),
                Row(children: [
                  Expanded(
                    child: _buildStreamCard(
                      'Natural Science',
                      Icons.science,
                      _selectedStream == 'natural',
                      () {
                        setState(() {
                          _selectedStream = 'natural';
                          _selectedSubject = null;
                          _selectedChapter = null;
                        });
                        _updateSubjects();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStreamCard(
                      'Social Science',
                      Icons.menu_book,
                      _selectedStream == 'social',
                      () {
                        setState(() {
                          _selectedStream = 'social';
                          _selectedSubject = null;
                          _selectedChapter = null;
                        });
                        _updateSubjects();
                      },
                    ),
                  ),
                ]),
              ] else if (_selectedSemester == '2' && _selectedStream != 'social') ...[
                _buildSectionTitle('Select Track'),
                Row(children: [
                  Expanded(
                    child: _buildTrackCard(
                      'Pre-Engineering',
                      Icons.engineering,
                      _selectedTrack == 'pre-engineering_courses',
                      () {
                        setState(() {
                          _selectedTrack = 'pre-engineering_courses';
                          _selectedSubject = null;
                          _selectedChapter = null;
                        });
                        _updateSubjects();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTrackCard(
                      'Other Natural Science',
                      Icons.biotech,
                      _selectedTrack == 'other_natural_science',
                      () {
                        setState(() {
                          _selectedTrack = 'other_natural_science';
                          _selectedSubject = null;
                          _selectedChapter = null;
                        });
                        _updateSubjects();
                      },
                    ),
                  ),
                ]),
              ],
              
              if (_subjects.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Select Subject'),
                _buildSubjectGrid(),
                const SizedBox(height: 16),
              ],
              
              if (_selectedSubject != null && _chapters.isNotEmpty) ...[
                _buildSectionTitle('Select Chapter'),
                _buildChapterGrid(),
                const SizedBox(height: 16),
              ],
            ],

            // CONTENT TYPE SELECTION
            if (_selectedSubject != null && _selectedChapter != null) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Select Content Type'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _contentTypes.map((type) => _buildContentTypeChip(type)).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // UPLOAD DETAILS
            if (_selectedContentType != null) ...[
              _buildSectionTitle('Internet Archive Link'),
              const SizedBox(height: 8),
              TextField(
                controller: _internetArchiveLinkController,
                decoration: const InputDecoration(
                  labelText: 'Internet Archive URL',
                  hintText: 'https://archive.org/download/.../file.mp4',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                  helperText: 'Paste the direct download link from Internet Archive',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              
              _buildSectionTitle('Content Details'),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter content title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 12),
              
              // Conditional fields based on content type
              if (_selectedContentType == 'short_note') ...[
                TextField(
                  controller: _pageCountController,
                  decoration: const InputDecoration(
                    labelText: 'Page Count',
                    hintText: 'Number of pages in the PDF',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.menu_book),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
              ],
              
              if (_selectedContentType == 'quiz' || _selectedContentType == 'exam') ...[
                TextField(
                  controller: _questionCountController,
                  decoration: const InputDecoration(
                    labelText: 'Number of Questions',
                    hintText: 'Total questions in this quiz/exam',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.quiz),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _timeLimitController,
                  decoration: const InputDecoration(
                    labelText: 'Time Limit (minutes)',
                    hintText: 'Duration for completion',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.timer),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
              ],
              
              if (_selectedContentType == 'flashcard') ...[
                TextField(
                  controller: _cardCountController,
                  decoration: const InputDecoration(
                    labelText: 'Number of Cards',
                    hintText: 'Total flashcards in this set',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.style),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
              ],
              
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter content description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                color: _isFree ? AppColors.primary.withOpacity(0.05) : null,
                child: CheckboxListTile(
                  value: _isFree,
                  onChanged: (v) => setState(() => _isFree = v ?? false),
                  title: const Text(
                    'Mark as Free Content',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Accessible without purchase or authentication',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  secondary: Icon(
                    _isFree ? Icons.lock_open : Icons.lock,
                    color: _isFree ? Colors.green : Colors.grey,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              GradientButton(
                text: 'UPLOAD TO FIREBASE',
                onPressed: _isUploading ? () {} : _uploadContent,
                isLoading: _isUploading,
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Make sure your file is already uploaded to Internet Archive. '
                        'The link should be the direct download URL.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
  );

  Widget _buildCategoryCard(String title, String subtitle, IconData icon, String value) {
    final isSelected = _selectedCategory == value;
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = value;
            _resetSelections();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 36),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : Colors.black87,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AcademicStructure.grades.map((grade) {
        final isSelected = _selectedGrade == grade;
        return FilterChip(
          label: Text('Grade $grade'),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedGrade = selected ? grade : null;
              _selectedStream = null;
              _selectedSubject = null;
              _selectedChapter = null;
            });
            _updateSubjects();
          },
          selectedColor: AppColors.primary.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStreamCard(String title, IconData icon, bool isSelected, VoidCallback onTap) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 28),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : Colors.black87,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSemesterCard(String title, IconData icon, bool isSelected, VoidCallback onTap) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackCard(String title, IconData icon, bool isSelected, VoidCallback onTap) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 28),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : Colors.black87,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        final subject = _subjects[index];
        final isSelected = _selectedSubject == subject;
        final colorHex = AcademicStructure.subjectColors[subject] ?? '#9C27B0';
        final color = Color(int.parse(colorHex.substring(1, 7), radix: 16) + 0xFF000000);
        
        return Card(
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedSubject = subject;
                _selectedChapter = null;
              });
              _updateChapters();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isSelected ? color.withOpacity(0.1) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      subject,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : Colors.black87,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChapterGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 4,
        mainAxisSpacing: 8,
      ),
      itemCount: _chapters.length,
      itemBuilder: (context, index) {
        final chapter = _chapters[index];
        final isSelected = _selectedChapter == chapter;
        
        return Card(
          elevation: isSelected ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            onTap: () {
              setState(() {
                _selectedChapter = chapter;
              });
            },
            leading: Icon(
              Icons.folder,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
            title: Text(
              chapter,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.black87,
                fontSize: 13,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildContentTypeChip(String type) {
    final isSelected = _selectedContentType == type;
    final displayName = AcademicStructure.contentTypeDisplayNames[type] ?? type;
    final icon = _contentTypeIcons[type] ?? '📄';
    
    return FilterChip(
      avatar: Text(icon, style: const TextStyle(fontSize: 16)),
      label: Text(displayName),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedContentType = selected ? type : null;
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primary : Colors.black87,
      ),
    );
  }
}