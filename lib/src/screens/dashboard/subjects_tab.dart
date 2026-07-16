import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/services/package_service.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/services/offline_database.dart';

class SubjectPortalScreen extends StatefulWidget {
  final String subject;
  final String? grade;
  final String? stream;

  const SubjectPortalScreen({
    super.key,
    required this.subject,
    this.grade,
    this.stream,
  });

  @override
  State<SubjectPortalScreen> createState() => _SubjectPortalScreenState();
}

class _SubjectPortalScreenState extends State<SubjectPortalScreen> {
  List<Map<String, dynamic>> _chapters = [];
  bool _isLoading = true;
  bool _isPackageLocked = true;
  int _daysRemaining = 0;
  String _packageName = '';
  int _packagePrice = 300;
  final _packageService = PackageService();

  // Chapter counts per subject (from ACADIA spec)
  static const Map<String, Map<String, List<String>>> _chaptersBySubject = {
    // Grade 9
    'Biology': [
      'Unit 1: Introduction to Biology',
      'Unit 2: Characteristics and Classification of Organisms',
      'Unit 3: Cells',
      'Unit 4: Reproduction',
      'Unit 5: Human Health, Nutrition, and Disease',
      'Unit 6: Ecology',
    ],
    'Chemistry': [
      'Unit 1: Chemistry and Its Importance',
      'Unit 2: Measurements and Scientific Methods',
      'Unit 3: Structure of the Atom',
      'Unit 4: Periodic Classification of Elements',
      'Unit 5: Chemical Bonding',
    ],
    'Citizenship': [
      'Unit 1: Ethical Values',
      'Unit 2: The Culture of Using Digital Technology',
      'Unit 3: Constitution and Constitutionalism',
      'Unit 4: Understanding Indigenous Knowledge',
      'Unit 5: Multiculturalism in Ethiopia',
      'Unit 6: National Unity Through Diversity',
      'Unit 7: Problem Solving Skills',
      'Unit 8: Ethiopia\'s Foreign Relations in East Africa',
    ],
    'Economics': [
      'Unit 1: Introducing Economics',
      'Unit 2: The Basic Economic Problems and Economic Systems',
      'Unit 3: Economic Resources and Markets',
      'Unit 4: Introduction to Demand and Supply',
      'Unit 5: Introduction to Production and Cost',
      'Unit 6: Introduction to Money',
      'Unit 7: Introduction to Macroeconomics',
      'Unit 8: Basic Entrepreneurship',
    ],
    'English': [
      'Unit 1: Living in Urban Areas',
      'Unit 2: Study Skills',
      'Unit 3: Traffic Accident',
      'Unit 4: National Parks',
      'Unit 5: Horticulture',
      'Unit 6: Poverty in Ethiopia',
      'Unit 7: Community Services',
      'Unit 8: Communicable Diseases',
    ],
    'Geography': [
      'Unit 1: Introduction to Geography',
      'Unit 2: The Earth',
      'Unit 3: Map Reading and Interpretation',
      'Unit 4: The Physical Environment of Ethiopia',
      'Unit 5: Population of Ethiopia',
      'Unit 6: Economic Activities in Ethiopia',
    ],
    'History': [
      'Unit 1: The Discipline of History and Human Evolution',
      'Unit 2: Ancient World Civilizations up to c. 500 AD',
      'Unit 3: Peoples and States in Ethiopia and the Horn to the End of 13th C',
      'Unit 4: The Middle Ages and Early Modern World, c. 500 to 1750s',
      'Unit 5: Peoples and States of Africa to 1500',
      'Unit 6: Africa and the Outside World 1500-1880s',
      'Unit 7: States, Principalities, Population Movements & Interactions in Ethiopia 13th to Mid-16th C',
      'Unit 8: Political, Social and Economic Processes in Ethiopia Mid-16th to Mid-19th C',
      'Unit 9: The Age of Revolutions 1750s to 1815',
    ],
    'IT': [
      'Unit 1: Organization of Files',
      'Unit 2: Computer Network',
      'Unit 3: Application Software',
      'Unit 4: Image Processing and Multimedia',
      'Unit 5: Information and Computer Security',
      'Unit 6: Fundamentals of Programming',
    ],
    'Mathematics': [
      'Unit 1: Further on Sets',
      'Unit 2: The Number System',
      'Unit 3: Solving Equations',
      'Unit 4: Solving Inequalities',
      'Unit 5: Introduction to Trigonometry',
      'Unit 6: Regular Polygons',
      'Unit 7: Congruency and Similarity',
      'Unit 8: Vectors in Two Dimensions',
      'Unit 9: Statistics and Probability',
    ],
    'Physics': [
      'Unit 1: Physics and Human Society',
      'Unit 2: Physical Quantities',
      'Unit 3: Motion in a Straight Line',
      'Unit 4: Force, Work, Energy and Power',
      'Unit 5: Simple Machines',
      'Unit 6: Mechanical Oscillation and Sound Wave',
      'Unit 7: Temperature and Thermometry',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Check package status
      final hasActivePackage = await _packageService.hasActivePackage();
      _isPackageLocked = !hasActivePackage;

      if (!hasActivePackage) {
        _packageName = await _packageService.getPackageName();
        _packagePrice = await _packageService.getPackagePrice();
      } else {
        _daysRemaining = await _packageService.getDaysRemaining();
      }

      // Load chapters from local database or hardcoded
      await _loadChapters();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading subject portal: $e');
    }
  }

  Future<void> _loadChapters() async {
    try {
      final offlineDb = OfflineDatabase.instance;
      final db = await offlineDb.database;

      // Try to load chapters from local database
      final result = await db.query(
        'chapters',
        where: 'subject = ?',
        whereArgs: [widget.subject],
      );

      if (result.isNotEmpty) {
        _chapters = result;
      } else {
        // Fallback to hardcoded chapters
        final chaptersList = _chaptersBySubject[widget.subject] ?? [];
        _chapters = chaptersList.map((name) => {
          'name': name,
          'subject': widget.subject,
          'id': name.hashCode.toString(),
        }).toList();
      }
    } catch (e) {
      // Fallback to hardcoded chapters
      final chaptersList = _chaptersBySubject[widget.subject] ?? [];
      _chapters = chaptersList.map((name) => ({
        'name': name,
        'subject': widget.subject,
        'id': name.hashCode.toString(),
      })).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.subject)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _isPackageLocked
          ? _buildLockedView()
          : _buildUnlockedView(),
    );
  }

  Widget _buildLockedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock, size: 64, color: Colors.orange),
            ),
            const SizedBox(height: 24),
            Text(
              'Content Locked',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _packageName.isNotEmpty ? _packageName : 'Grade Package',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              '$_packagePrice ETB - Purchase to unlock all chapters',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/payment'),
              icon: const Icon(Icons.lock_open),
              label: const Text('UNLOCK NOW'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedView() {
    if (_chapters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chapter, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No chapters available yet',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Content will be uploaded soon by admin',
                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _chapters.length,
        itemBuilder: (context, index) {
          final chapter = _chapters[index];
          final chapterName = chapter['name']?.toString() ?? 'Chapter ${index + 1}';
          
          return _buildChapterCard(chapterName, index + 1);
        },
      ),
    );
  }

  Widget _buildChapterCard(String chapterName, int unitNumber) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // All chapters are accessible immediately after purchase
          context.push('/chapter-content', extra: {
            'subject': widget.subject,
            'chapterName': chapterName,
            'chapterId': chapterName.hashCode.toString(),
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Unit number badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$unitNumber',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Chapter name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unit $unitNumber',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chapterName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Content items preview
                    Row(
                      children: [
                        _buildContentTypeIcon(Icons.play_circle, 'Video'),
                        const SizedBox(width: 8),
                        _buildContentTypeIcon(Icons.description, 'Note'),
                        const SizedBox(width: 8),
                        _buildContentTypeIcon(Icons.quiz, 'Quiz'),
                        const SizedBox(width: 8),
                        _buildContentTypeIcon(Icons.assignment, 'Exam'),
                        const SizedBox(width: 8),
                        _buildContentTypeIcon(Icons.style, 'Flashcard'),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentTypeIcon(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 2),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey[600])),
        ],
      ),
    );
  }
}