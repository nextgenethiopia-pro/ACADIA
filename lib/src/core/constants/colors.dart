import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF111844); // Deep navy blue
  static const Color primaryLight = Color(0xFF1A2656);
  static const Color primaryDark = Color(0xFF0A102E);
  static const Color secondary = Color(0xFF1A2656);

  // Accent
  static const Color accent = Color(0xFF1A2656);
  static const Color accent1 = Color(0xFF111844);
  static const Color accent2 = Color(0xFF1A2656);

  // Subject Color Constants (for direct reference)
  static const Color subjectMath = Color(0xFF9C27B0);
  static const Color subjectPhysics = Color(0xFFFF9800);
  static const Color subjectEnglish = Color(0xFF2196F3);
  static const Color subjectHistory = Color(0xFF795548);
  static const Color subjectBiology = Color(0xFFE91E63);
  static const Color subjectChemistry = Color(0xFF4CAF50);
  static const Color subjectGeography = Color(0xFF009688);
  static const Color subjectEconomics = Color(0xFFFF5722);
  static const Color subjectIT = Color(0xFF3F51B5);
  static const Color subjectAgriculture = Color(0xFF8BC34A);
  static const Color subjectAptitude = Color(0xFF708090);
  static const Color subjectCitizenship = Color(0xFF00BCD4);
  static const Color subjectLogic = Color(0xFF1A237E);
  static const Color subjectPsychology = Color(0xFFCE93D8);
  static const Color subjectAnthropology = Color(0xFFFFD54F);
  static const Color subjectAppliedMath = Color(0xFF7E57C2);
  static const Color subjectCppProgramming = Color(0xFF424242);
  static const Color subjectEmergingTech = Color(0xFFB0BEC5);
  static const Color subjectEntrepreneurship = Color(0xFFFFD700);
  static const Color subjectMoralCitizenship = Color(0xFF808000);
  static const Color subjectEnglishI = Color(0xFF2196F3);
  static const Color subjectEnglishII = Color(0xFF2196F3);

  // Subject Colors Map (complete — matching blueprint)
  static const Map<String, Color> subjectColors = {
    'Mathematics': Color(0xFF9C27B0),
    'English': Color(0xFF2196F3),
    'English I': Color(0xFF2196F3),
    'English II': Color(0xFF2196F3),
    'Physics': Color(0xFFFF9800),
    'Chemistry': Color(0xFF4CAF50),
    'Biology': Color(0xFFE91E63),
    'Aptitude': Color(0xFF708090),
    'Geography': Color(0xFF009688),
    'History': Color(0xFF795548),
    'Economics': Color(0xFFFF5722),
    'IT': Color(0xFF3F51B5),
    'Agriculture': Color(0xFF8BC34A),
    'Citizenship': Color(0xFF00BCD4),
    'Logic': Color(0xFF1A237E),
    'Psychology': Color(0xFFCE93D8),
    'Anthropology': Color(0xFFFFD54F),
    'Applied Mathematics': Color(0xFF7E57C2),
    'C++ Programming': Color(0xFF424242),
    'Emerging Technologies': Color(0xFFB0BEC5),
    'Entrepreneurship': Color(0xFFFFD700),
    'Moral and Citizenship Education': Color(0xFF808000),
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