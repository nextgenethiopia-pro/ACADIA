import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/colors.dart';

class UniversitySelectionScreen extends StatefulWidget {
  const UniversitySelectionScreen({super.key});

  @override
  State<UniversitySelectionScreen> createState() =>
      _UniversitySelectionScreenState();
}

class _UniversitySelectionScreenState extends State<UniversitySelectionScreen> {
  String? _selectedUniversity;
  String? _generation;
  List<String> _universities = [];
  List<String> _filteredUniversities = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isNavigating = false;

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

  @override
  void initState() {
    super.initState();
    _loadGeneration();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadGeneration() async {
    final prefs = await SharedPreferences.getInstance();
    final generation =
        prefs.getString('selected_generation') ?? prefs.getString('generation');

    List<String> universities;
    switch (generation) {
      case '1st Generation':
        universities = List<String>.from(_firstGeneration);
        break;
      case '2nd Generation':
        universities = List<String>.from(_secondGeneration);
        break;
      case '3rd Generation':
        universities = List<String>.from(_thirdGeneration);
        break;
      case '4th Generation':
        universities = List<String>.from(_fourthGeneration);
        break;
      case 'Technology Institutes':
        universities = List<String>.from(_technologyInstitutes);
        break;
      default:
        universities = List<String>.from(_firstGeneration);
    }

    if (!mounted) return;

    setState(() {
      _generation = generation ?? '1st Generation';
      _universities = universities;
      _filteredUniversities = universities;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredUniversities = List<String>.from(_universities);
      } else {
        _filteredUniversities = _universities
            .where((university) => university.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  String _getUniversityAbbreviation(String university) {
    final parts = university.split(' - ');
    return parts.length > 1 ? parts.first.trim() : university.trim();
  }

  String _getUniversityFullName(String university) {
    final parts = university.split(' - ');
    return parts.length > 1 ? parts.sublist(1).join(' - ').trim() : university;
  }

  String _getProgramLabel(String university) {
    return _generation == 'Technology Institutes'
        ? 'Technology Institute'
        : '4-year program';
  }

  Future<void> _saveAndContinue() async {
    if (_selectedUniversity == null || _isNavigating) return;

    setState(() => _isNavigating = true);

    final prefs = await SharedPreferences.getInstance();
    final fullSelection = _selectedUniversity!;
    final fullName = _getUniversityFullName(fullSelection);
    final abbreviation = _getUniversityAbbreviation(fullSelection);

    await prefs.setString('selected_university', fullSelection);
    await prefs.setString('university', fullSelection);
    await prefs.setString('university_name', fullName);
    await prefs.setString('university_abbreviation', abbreviation);

    if (!mounted) return;
    context.pushReplacement('/year-selection');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTechnology = _generation == 'Technology Institutes';

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isNavigating ? null : () => context.pop(),
        ),
        title: Text(_generation ?? 'Select University'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(((255 * 0.06)).toInt()),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(((255 * 0.14)).toInt()),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(((255 * 0.12)).toInt()),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isTechnology
                            ? Icons.precision_manufacturing
                            : Icons.account_balance,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _generation ?? 'University Selection',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose your institution to continue to year selection.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.45,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_universities.length} ${isTechnology ? 'institutes' : 'universities'} available',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search university',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                          },
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${_filteredUniversities.length} result${_filteredUniversities.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedUniversity != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(((255 * 0.08)).toInt()),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '1 selected',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _filteredUniversities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No universities found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try a different keyword.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredUniversities.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final university = _filteredUniversities[index];
                          final isSelected = _selectedUniversity == university;
                          final abbreviation =
                              _getUniversityAbbreviation(university);
                          final fullName = _getUniversityFullName(university);

                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: _isNavigating
                                ? null
                                : () {
                                    setState(() {
                                      _selectedUniversity = university;
                                    });
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withAlpha(((255 * 0.06)).toInt())
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? AppColors.primary.withAlpha(((255 * 0.10)).toInt())
                                        : Colors.black.withAlpha(((255 * 0.03)).toInt()),
                                    blurRadius: isSelected ? 16 : 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: university,
                                    groupValue: _selectedUniversity,
                                    onChanged: _isNavigating
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _selectedUniversity = value;
                                            });
                                          },
                                    activeColor: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fullName,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? AppColors.primary
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          abbreviation,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _getProgramLabel(university),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 180),
                                    opacity: isSelected ? 1 : 0,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _selectedUniversity != null && !_isNavigating
                      ? _saveAndContinue
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isNavigating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'CONTINUE',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
