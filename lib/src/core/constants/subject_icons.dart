/// Subject icon asset paths mapping
class SubjectIcons {
  static const String basePath = 'assets/icons/subjects_icon/';

  static String? getIconPath(String subject) {
    final normalized = subject.toLowerCase().trim();

    switch (normalized) {
      // High School
      case 'agriculture':
        return '${basePath}Agriculture_icon.jpg';
      case 'aptitude':
        return '${basePath}Aptitude_icon.jpg';
      case 'biology':
        return '${basePath}Biology_icon.jpg';
      case 'chemistry':
        return '${basePath}Chemistry_icon.jpg';
      case 'civics':
      case 'citizenship':
        return '${basePath}Citizenship_icon.jpg';
      case 'economics':
        return '${basePath}Economics_icon.jpg';
      case 'english':
      case 'english i':
      case 'english ii':
      case 'english skill 2':
      case 'english skill ii':
        return '${basePath}English_icon.jpg';
      case 'geography':
        return '${basePath}Geography_icon.jpg';
      case 'history':
        return '${basePath}History_icon.jpg';
      case 'it':
      case 'information technology':
        return '${basePath}It_icon.jpg';
      case 'mathematics':
      case 'math':
        return '${basePath}Math_icon.jpg';
      case 'physics':
        return '${basePath}Physics_icon.jpg';

      // University
      case 'anthropology':
        return '${basePath}Anthropology_icon.jpg';
      case 'applied mathematics':
      case 'applied_math':
        return '${basePath}Applied_math_icon.jpg';
      case 'c++':
      case 'c++ programming':
        return '${basePath}C++_icon.jpg';
      case 'emerging technologies':
      case 'emerging':
        return '${basePath}Emerging_icon.jpg';
      case 'entrepreneurship':
        return '${basePath}Economics_icon.jpg'; // Fallback
      case 'logic':
        return '${basePath}Logic_icon.jpg';
      case 'moral and citizenship education':
      case 'moral':
        return '${basePath}Civic_icon.jpg';
      case 'psychology':
        return '${basePath}Psychology_icon.jpg';

      default:
        return null;
    }
  }

  /// Check if icon exists for subject
  static bool hasIcon(String subject) {
    return getIconPath(subject) != null;
  }
}