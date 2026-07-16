import 'package:flutter/material.dart';

/// Centralized icon and color definitions for the ACADIA app.
/// Uses custom JPG icons from assets/icons/subjects_icon/ primarily,
/// with Material icon fallbacks.
class AppIcons {
  // Navigation Tab Icons
  static const IconData home = Icons.home_outlined;
  static const IconData homeFilled = Icons.home;
  static const IconData subjects = Icons.menu_book_outlined;
  static const IconData subjectsFilled = Icons.menu_book;
  static const IconData progress = Icons.trending_up_outlined;
  static const IconData progressFilled = Icons.trending_up;
  static const IconData entrance = Icons.school_outlined;
  static const IconData entranceFilled = Icons.school;
  static const IconData notifications = Icons.notifications_outlined;
  static const IconData notificationsFilled = Icons.notifications;
  static const IconData profile = Icons.person_outline;
  static const IconData profileFilled = Icons.person;

  // Subject Icon Asset Paths (custom JPG files)
  static const Map<String, String> subjectIconAssets = {
    'Mathematics': 'assets/icons/subjects_icon/Math_icon.jpg',
    'English': 'assets/icons/subjects_icon/English_icon.jpg',
    'English I': 'assets/icons/subjects_icon/English_icon.jpg',
    'English II': 'assets/icons/subjects_icon/English_icon.jpg',
    'Physics': 'assets/icons/subjects_icon/Physics_icon.jpg',
    'Chemistry': 'assets/icons/subjects_icon/Chemistry_icon.jpg',
    'Biology': 'assets/icons/subjects_icon/Biology_icon.jpg',
    'Aptitude': 'assets/icons/subjects_icon/Aptitude_icon.jpg',
    'Geography': 'assets/icons/subjects_icon/Geography_icon.jpg',
    'History': 'assets/icons/subjects_icon/History_icon.jpg',
    'Economics': 'assets/icons/subjects_icon/Economics_icon.jpg',
    'IT': 'assets/icons/subjects_icon/It_icon.jpg',
    'Agriculture': 'assets/icons/subjects_icon/Agriculture_icon.jpg',
    'Citizenship': 'assets/icons/subjects_icon/Citizenship_icon.jpg',
    'Logic': 'assets/icons/subjects_icon/Logic_icon.jpg',
    'Psychology': 'assets/icons/subjects_icon/Psychology_icon.jpg',
    'Anthropology': 'assets/icons/subjects_icon/Anthropology_icon.jpg',
    'Applied Mathematics': 'assets/icons/subjects_icon/Applied_math_icon.jpg',
    'C++ Programming': 'assets/icons/subjects_icon/C++_icon.jpg',
    'Emerging Technologies': 'assets/icons/subjects_icon/Emerging_icon.jpg',
    'Entrepreneurship': 'assets/icons/subjects_icon/Economics_icon.jpg',
    'Moral and Citizenship Education': 'assets/icons/subjects_icon/Civic_icon.jpg',
  };

  // Subject Colors (matching blueprint hex values)
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

  // Content Type Icons
  static const IconData video = Icons.play_circle_outline;
  static const IconData pdf = Icons.picture_as_pdf;
  static const IconData quiz = Icons.quiz;
  static const IconData flashcard = Icons.flip;
  static const IconData exam = Icons.assignment;
  static const IconData pastPaper = Icons.folder_open;
  static const IconData shortNote = Icons.description;

  // Action Icons
  static const IconData search = Icons.search;
  static const IconData download = Icons.download;
  static const IconData settings = Icons.settings_outlined;
  static const IconData logout = Icons.logout;
  static const IconData edit = Icons.edit;
  static const IconData delete = Icons.delete_outline;
  static const IconData add = Icons.add;
  static const IconData close = Icons.close;
  static const IconData back = Icons.arrow_back;
  static const IconData forward = Icons.arrow_forward;
  static const IconData more = Icons.more_vert;
  static const IconData check = Icons.check;
  static const IconData checkCircle = Icons.check_circle;
  static const IconData error = Icons.error_outline;
  static const IconData warning = Icons.warning_amber;
  static const IconData info = Icons.info_outline;

  // State Icons
  static const IconData empty = Icons.inbox_outlined;
  static const IconData noResults = Icons.search_off;
  static const IconData loading = Icons.hourglass_empty;
  static const IconData locked = Icons.lock_outline;
  static const IconData unlocked = Icons.lock_open;

  // Feature Icons
  static const IconData darkMode = Icons.dark_mode;
  static const IconData lightMode = Icons.light_mode;
  static const IconData language = Icons.language;
  static const IconData help = Icons.help_outline;
  static const IconData about = Icons.info_outline;
  static const IconData email = Icons.email_outlined;
  static const IconData phone = Icons.phone_outlined;

  // Payment Icons
  static const IconData payment = Icons.payment;
  static const IconData wallet = Icons.account_balance_wallet;
  static const IconData transaction = Icons.receipt_long;

  // Admin Icons
  static const IconData admin = Icons.admin_panel_settings;
  static const IconData users = Icons.people_outline;
  static const IconData content = Icons.folder_outlined;
  static const IconData analytics = Icons.analytics_outlined;
  static const IconData upload = Icons.cloud_upload;
  static const IconData reports = Icons.assessment;

  /// Get the custom JPG asset path for a subject
  static String? getSubjectIconAsset(String subject) {
    return subjectIconAssets[subject];
  }

  /// Get color for a subject (matching blueprint)
  static Color getSubjectColor(String subject) {
    return subjectColors[subject] ?? Colors.grey;
  }

  /// Get fallback Material icon for a subject (if custom JPG fails to load)
  static IconData getSubjectFallbackIcon(String subject) {
    switch (subject) {
      case 'Mathematics': return Icons.functions;
      case 'English':
      case 'English I':
      case 'English II': return Icons.menu_book;
      case 'Physics': return Icons.science;
      case 'Chemistry': return Icons.biotech;
      case 'Biology': return Icons.eco;
      case 'Aptitude': return Icons.psychology;
      case 'Geography': return Icons.public;
      case 'History': return Icons.history_edu;
      case 'Economics': return Icons.trending_up;
      case 'IT': return Icons.computer;
      case 'Agriculture': return Icons.agriculture;
      case 'Citizenship': return Icons.account_balance;
      case 'Logic': return Icons.lightbulb;
      case 'Psychology': return Icons.psychology_alt;
      case 'Anthropology': return Icons.groups;
      case 'Applied Mathematics': return Icons.calculate;
      case 'C++ Programming': return Icons.code;
      case 'Emerging Technologies': return Icons.devices;
      case 'Entrepreneurship': return Icons.business_center;
      case 'Moral and Citizenship Education': return Icons.gavel;
      default: return Icons.book;
    }
  }
}