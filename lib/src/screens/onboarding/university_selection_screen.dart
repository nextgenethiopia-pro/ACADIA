import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';

class UniversitySelectionScreen extends StatefulWidget {
  const UniversitySelectionScreen({super.key});

  @override
  State<UniversitySelectionScreen> createState() => _UniversitySelectionScreenState();
}

class _UniversitySelectionScreenState extends State<UniversitySelectionScreen> {
  String? _selectedUniversity;
  String? _generation;
  List<String> _universities = [];
  List<String> _filteredUniversities = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isNavigating = false;

  // Ethiopian universities by generation (from ACADIA spec)
  static const List<String> _firstGeneration = [
    'AAU - Addis Ababa University',
    'JU - Jimma University',
    'HU - Hawassa University',
    'Haramaya University',
    'AASTU - Addis Ababa Science & Technology University',
    'AMU - Arba Minch University',
    'BDU - Bahir Dar University',
    'MU - Mekelle University',
  ];

  static const List<String> _secondGeneration = [
    'Wollega University',
    'Wollo University',
    'Dilla University',
    'Debre Berhan University',
    'Wachamo University',
    'Jigjiga University',
    'Woldia University',
    'Debre Markos University',
  ];

  static const List<String> _thirdGeneration = [
    'Mizan-Tepi University',
    'Bule Hora University',
    'Wolaita Sodo University',
    'Ambo University',
    'Assosa University',
    'Samara University',
    'Dire Dawa University',
    'Gambella University',
  ];

  static const List<String> _fourthGeneration = [
    'Raya University',
    'Debre Tabor University',
    'Wachemo University',
    'Jinka University',
    'Aksum University',
    'Werabe University',
    'Kebri Dehar University',
    'Borana University',
  ];

  static const List<String> _technologyInstitutes = [
    'AASTU - Addis Ababa Science & Technology University',
    'ASTU - Adama Science & Technology University',
    'JIT - Jimma Institute of Technology',
    'Mekelle Technology University',
  ];

  // Map generation to its color
  final Map<String, Color> _generationColors = {
    '1st Generation': Colors.blue,
    '2nd Generation': Colors.green,
    '3rd Generation': Colors.orange,
    '4th Generation': Colors.purple,
    'Technology Institutes': Colors.teal,
  };

  @override
  void initState() {
    super.initState();
    _loadGeneration();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGeneration() async {
    final prefs = await SharedPreferences.getInstance();
    final generation = prefs.getString('selected_generation') ?? prefs.getString('generation');

    List<String> universities;
    switch (generation) {
      case '1st Generation':
        universities = List.from(_firstGeneration);
        break;
      case '2nd Generation':
        universities = List.from(_secondGeneration);
        break;
      case '3rd Generation':
        universities = List.from(_thirdGeneration);
        break;
      case '4th Generation':
        universities = List.from(_fourthGeneration);
        break;
      case 'Technology Institutes':
        universities = List.from(_technologyInstitutes);
        break;
      default:
        universities = List.from(_firstGeneration);
    }

    setState(() {
      _generation = generation;
      _universities = universities;
      _filteredUniversities = universities;
    });
  }

  void _filterUniversities(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUniversities = List.from(_universities);
      } else {
        _filteredUniversities = _universities
            .where((uni) => uni.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  String _getUniversityAbbreviation(String fullName) {
    final parts = fullName.split(' - ');
    return parts.length > 1 ? parts[0] : fullName;
  }

  String _getUniversityFullName(String fullName) {
    final parts = fullName.split(' - ');
    return parts.length > 1 ? parts[1] : fullName;
  }

  Future<void> _saveAndContinue() async {
    if (_selectedUniversity == null || _isNavigating) return;

    setState(() => _isNavigating = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('university', _selectedUniversity!);
    await prefs.setString('university_name', _getUniversityFullName(_selectedUniversity!));
    await prefs.setString('university_abbreviation', _getUniversityAbbreviation(_selectedUniversity!));

    if (!mounted) return;
    context.pushReplacement('/year-selection');
  }

  Color _getGenerationColor() {
    return _generationColors[_generation] ?? AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final generationColor = _getGenerationColor();
    final isTechnology = _generation == 'Technology Institutes';
    final totalUniversities = _universities.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Select Your University'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Generation info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: generationColor.withOpacity(0.1),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: generationColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isTechnology ? Icons.precision_manufacturing : Icons.account_balance,
                    color: generationColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _generation ?? 'Universities',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: generationColor,
                        ),
                      ),
                      Text(
                        '$totalUniversities ${isTechnology ? "Institutes" : "Universities"}',
                        style: TextStyle(
                          color: generationColor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterUniversities,
              decoration: InputDecoration(
                hintText: 'Search by university name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterUniversities('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredUniversities.length} of $totalUniversities universities',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                if (_selectedUniversity != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '1 selected',
                      style: TextStyle(color: Colors.green[700], fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // University list
          Expanded(
            child: _filteredUniversities.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('No universities found', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(
                          'Try a different search term',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredUniversities.length,
                    itemBuilder: (context, index) {
                      final uni = _filteredUniversities[index];
                      final isSelected = _selectedUniversity == uni;
                      final abbreviation = _getUniversityAbbreviation(uni);
                      final fullName = _getUniversityFullName(uni);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: isSelected ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? generationColor : Colors.grey[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => setState(() => _selectedUniversity = uni),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                // Radio button
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? generationColor : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                    color: isSelected ? generationColor : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                                      : null,
                                ),
                                const SizedBox(width: 14),

                                // University info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fullName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isSelected ? generationColor : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.school,
                                            size: 12,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            abbreviation,
                                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.business,
                                            size: 12,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isTechnology ? 'Technology Institute' : '4-year University',
                                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ],
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

          // Continue button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedUniversity != null && !_isNavigating ? _saveAndContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedUniversity != null ? generationColor : Colors.grey[300],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isNavigating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('CONTINUE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}