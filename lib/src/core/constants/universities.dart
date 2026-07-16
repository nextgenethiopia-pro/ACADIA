/// University Database - All Ethiopian universities organized by generation
///
/// Based on ACADIA V1.0.0 specification:
/// - 1st Generation: 8 universities
/// - 2nd Generation: 8 universities
/// - 3rd Generation: 8 universities
/// - 4th Generation: 8 universities
/// - Technology Institutes: 4 universities
/// Total: 44 universities
class UniversityDatabase {
  /// 1st Generation Universities (8)
  static const List<Map<String, String>> firstGeneration = [
    {'id': 'aau', 'name': 'AAU - Addis Ababa University', 'short': 'AAU'},
    {'id': 'ju', 'name': 'Jimma University', 'short': 'JU'},
    {'id': 'hu', 'name': 'Hawassa University', 'short': 'HU'},
    {'id': 'haramaya', 'name': 'Haramaya University', 'short': 'Haramaya'},
    {
      'id': 'aastu',
      'name': 'AASTU - Addis Ababa Science & Technology University',
      'short': 'AASTU'
    },
    {'id': 'amu', 'name': 'Arba Minch University', 'short': 'AMU'},
    {'id': 'bdu', 'name': 'Bahir Dar University', 'short': 'BDU'},
    {'id': 'mu', 'name': 'Mekelle University', 'short': 'MU'},
  ];

  /// 2nd Generation Universities (8)
  static const List<Map<String, String>> secondGeneration = [
    {'id': 'wollega', 'name': 'Wollega University', 'short': 'Wollega'},
    {'id': 'wollo', 'name': 'Wollo University', 'short': 'Wollo'},
    {'id': 'dilla', 'name': 'Dilla University', 'short': 'Dilla'},
    {'id': 'debre_berhan', 'name': 'Debre Berhan University', 'short': 'DBU'},
    {'id': 'wachamo', 'name': 'Wachamo University', 'short': 'Wachamo'},
    {'id': 'jigjiga', 'name': 'Jigjiga University', 'short': 'Jigjiga'},
    {'id': 'woldia', 'name': 'Woldia University', 'short': 'Woldia'},
    {'id': 'debre_markos', 'name': 'Debre Markos University', 'short': 'DMU'},
  ];

  /// 3rd Generation Universities (8)
  static const List<Map<String, String>> thirdGeneration = [
    {'id': 'mizan_tepi', 'name': 'Mizan-Tepi University', 'short': 'MTU'},
    {'id': 'bule_hora', 'name': 'Bule Hora University', 'short': 'Bule Hora'},
    {'id': 'wolaita_sodo', 'name': 'Wolaita Sodo University', 'short': 'WSU'},
    {'id': 'ambo', 'name': 'Ambo University', 'short': 'Ambo'},
    {'id': 'assosa', 'name': 'Assosa University', 'short': 'Assosa'},
    {'id': 'samara', 'name': 'Samara University', 'short': 'Samara'},
    {'id': 'dire_dawa', 'name': 'Dire Dawa University', 'short': 'DDU'},
    {'id': 'gambella', 'name': 'Gambella University', 'short': 'Gambella'},
  ];

  /// 4th Generation Universities (8)
  static const List<Map<String, String>> fourthGeneration = [
    {'id': 'raya', 'name': 'Raya University', 'short': 'Raya'},
    {'id': 'debre_tabor', 'name': 'Debre Tabor University', 'short': 'DTU'},
    {'id': 'wachemo', 'name': 'Wachemo University', 'short': 'Wachemo'},
    {'id': 'jinka', 'name': 'Jinka University', 'short': 'Jinka'},
    {'id': 'aksum', 'name': 'Aksum University', 'short': 'Aksum'},
    {'id': 'werabe', 'name': 'Werabe University', 'short': 'Werabe'},
    {'id': 'kebri_dehar', 'name': 'Kebri Dehar University', 'short': 'KDU'},
    {'id': 'borana', 'name': 'Borana University', 'short': 'Borana'},
  ];

  /// Technology Institutes (4)
  static const List<Map<String, String>> technologyInstitutes = [
    {
      'id': 'aastu',
      'name': 'AASTU - Addis Ababa Science & Technology University',
      'short': 'AASTU'
    },
    {
      'id': 'astu',
      'name': 'ASTU - Adama Science & Technology University',
      'short': 'ASTU'
    },
    {'id': 'jit', 'name': 'Jimma Institute of Technology', 'short': 'JIT'},
    {
      'id': 'mekelle_tech',
      'name': 'Mekelle Institute of Technology',
      'short': 'MIT'
    },
  ];

  /// Get universities by generation
  static List<Map<String, String>> getUniversitiesByGeneration(
      String generation) {
    switch (generation.toLowerCase()) {
      case '1st generation':
      case '1':
        return firstGeneration;
      case '2nd generation':
      case '2':
        return secondGeneration;
      case '3rd generation':
      case '3':
        return thirdGeneration;
      case '4th generation':
      case '4':
        return fourthGeneration;
      case 'technology institutes':
      case 'technology':
        return technologyInstitutes;
      default:
        return [];
    }
  }

  /// Get all universities (44 total)
  static List<Map<String, String>> getAllUniversities() {
    return [
      ...firstGeneration,
      ...secondGeneration,
      ...thirdGeneration,
      ...fourthGeneration,
      ...technologyInstitutes,
    ];
  }

  /// Get university name by ID
  static String? getUniversityName(String id) {
    final allUnis = getAllUniversities();
    final uni = allUnis.firstWhere(
      (u) => u['id'] == id,
      orElse: () => {'name': ''},
    );
    return uni['name']?.isNotEmpty == true ? uni['name'] : null;
  }

  /// Search universities by name
  static List<Map<String, String>> searchUniversities(String query) {
    if (query.isEmpty) return getAllUniversities();

    final allUnis = getAllUniversities();
    return allUnis.where((uni) {
      final name = uni['name']?.toLowerCase() ?? '';
      final short = uni['short']?.toLowerCase() ?? '';
      return name.contains(query.toLowerCase()) ||
          short.contains(query.toLowerCase());
    }).toList();
  }

  /// Get generation count
  static const int totalGenerations = 5;

  /// Get total university count
  static const int totalUniversities = 44;
}
