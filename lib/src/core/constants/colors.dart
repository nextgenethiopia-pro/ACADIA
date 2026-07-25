import 'package:flutter/material.dart';

class AppColors {
  // Primary - Navy Blue
  static const Color primary = Color(0xFF093C5D);
  static const Color primaryLight = Color(0xFF1E5B7A);
  static const Color primaryDark = Color(0xFF05253A);
  static const Color secondary = Color(0xFF1E5B7A);

  // Accent
  static const Color accent = Color(0xFF1E5B7A);
  static const Color accent1 = Color(0xFF093C5D);
  static const Color accent2 = Color(0xFF1E5B7A);

  // Subject Color Constants - Uniform Navy Blue
  static const Color subjectMath = Color(0xFF093C5D);
  static const Color subjectPhysics = Color(0xFF093C5D);
  static const Color subjectEnglish = Color(0xFF093C5D);
  static const Color subjectHistory = Color(0xFF093C5D);
  static const Color subjectBiology = Color(0xFF093C5D);
  static const Color subjectChemistry = Color(0xFF093C5D);
  static const Color subjectGeography = Color(0xFF093C5D);
  static const Color subjectEconomics = Color(0xFF093C5D);
  static const Color subjectIT = Color(0xFF093C5D);
  static const Color subjectAgriculture = Color(0xFF093C5D);
  static const Color subjectAptitude = Color(0xFF093C5D);
  static const Color subjectCitizenship = Color(0xFF093C5D);
  static const Color subjectLogic = Color(0xFF093C5D);
  static const Color subjectPsychology = Color(0xFF093C5D);
  static const Color subjectAnthropology = Color(0xFF093C5D);
  static const Color subjectAppliedMath = Color(0xFF093C5D);
  static const Color subjectCppProgramming = Color(0xFF093C5D);
  static const Color subjectEmergingTech = Color(0xFF093C5D);
  static const Color subjectEntrepreneurship = Color(0xFF093C5D);
  static const Color subjectMoralCitizenship = Color(0xFF093C5D);
  static const Color subjectEnglishI = Color(0xFF093C5D);
  static const Color subjectEnglishII = Color(0xFF093C5D);

  // Subject Colors Map - Uniform Navy Blue
  static const Map<String, Color> subjectColors = {
    'Mathematics': Color(0xFF093C5D),
    'English': Color(0xFF093C5D),
    'English I': Color(0xFF093C5D),
    'English II': Color(0xFF093C5D),
    'Physics': Color(0xFF093C5D),
    'Chemistry': Color(0xFF093C5D),
    'Biology': Color(0xFF093C5D),
    'Aptitude': Color(0xFF093C5D),
    'Geography': Color(0xFF093C5D),
    'History': Color(0xFF093C5D),
    'Economics': Color(0xFF093C5D),
    'IT': Color(0xFF093C5D),
    'Agriculture': Color(0xFF093C5D),
    'Citizenship': Color(0xFF093C5D),
    'Logic': Color(0xFF093C5D),
    'Psychology': Color(0xFF093C5D),
    'Anthropology': Color(0xFF093C5D),
    'Applied Mathematics': Color(0xFF093C5D),
    'C++ Programming': Color(0xFF093C5D),
    'Emerging Technologies': Color(0xFF093C5D),
    'Entrepreneurship': Color(0xFF093C5D),
    'Moral and Citizenship Education': Color(0xFF093C5D),
  };

  // Semantic
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF2196F3);

  // Background
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Colors.white;

  // Text
  static const Color textDarkPrimary = Color(0xFF212121);
  static const Color textDarkSecondary = Color(0xFF757575);
  static const Color textLightPrimary = Colors.white;
  static const Color textLightSecondary = Color(0xB3FFFFFF);

  // Other
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x40000000);
  static const Color overlay = Color(0x99000000);

  // Get subject color by name
  static Color getSubjectColor(String subject) {
    return subjectColors[subject] ?? primary;
  }
}