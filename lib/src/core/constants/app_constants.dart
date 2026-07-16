class AppConstants {
  // App Info
  static const String appName = 'ACADIA';
  static const String appVersion = '1.0.0';
  static const String tagline = 'Empowering Ethiopian Students';
  
  // Storage Keys
  static const String keyFirstTime = 'first_time';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyAcademicPath = 'academic_path';
  static const String keyUserToken = 'user_token';
  static const String keyDarkMode = 'dark_mode';
  static const String keyNotifications = 'notifications_enabled';
  static const String keyLanguage = 'language';
  
  // Payment Methods
  static const List<String> paymentMethods = [
    'telebirr',
    'mpesa', 
    'cbe',
    'cbo',
    'awash',
  ];
  
  // Payment Account Details
  static const Map<String, PaymentDetails> paymentAccounts = {
    'telebirr': PaymentDetails(
      name: 'Telebirr',
      number: '0967870090',
      holder: 'FIRAOL TADESA',
      icon: 'assets/icons/telebirr_icon.png',
    ),
    'mpesa': PaymentDetails(
      name: 'M-PESA',
      number: '0705578277',
      holder: 'BONA BAYU',
      icon: 'assets/icons/m-pesa_icon.png',
    ),
    'cbe': PaymentDetails(
      name: 'CBE Birr',
      number: '1000720789985',
      holder: 'FIRAOL TADESA',
      icon: 'assets/icons/cbe_birr_icon.png',
    ),
    'cbo': PaymentDetails(
      name: 'CBO Bank',
      number: '1016100072577',
      holder: 'FIRAOL TADESA',
      icon: 'assets/icons/cbo_bank_icon.png',
    ),
    'awash': PaymentDetails(
      name: 'Awash Bank',
      number: '01320500140900',
      holder: 'FIRAOL TADESA',
      icon: 'assets/icons/awash_bank_icon.png',
    ),
  };
  
  // Package Prices (Admin editable via admin_dashboard/settings)
  static const Map<String, int> packagePrices = {
    'grade_9': 300,
    'grade_10': 300,
    'grade_11_natural': 300,
    'grade_11_social': 300,
    'grade_12_natural': 300,
    'grade_12_social': 300,
    'university_freshman_natural_sem1': 300,
    'university_freshman_social_sem1': 300,
    'university_freshman_other': 300,
    'university_freshman_pre_eng': 300,
  };

  // Subject Colors for UI (matching blueprint)
  static const Map<String, String> subjectColors = {
    'Mathematics': '#9C27B0',
    'English': '#2196F3',
    'English I': '#2196F3',
    'English II': '#2196F3',
    'Physics': '#FF9800',
    'Chemistry': '#4CAF50',
    'Biology': '#E91E63',
    'Aptitude': '#708090',
    'Geography': '#009688',
    'History': '#795548',
    'Economics': '#FF5722',
    'IT': '#3F51B5',
    'Agriculture': '#8BC34A',
    'Citizenship': '#00BCD4',
    'Logic': '#1A237E',
    'Psychology': '#CE93D8',
    'Anthropology': '#FFD54F',
    'Applied Mathematics': '#7E57C2',
    'C++ Programming': '#424242',
    'Emerging Technologies': '#B0BEC5',
    'Entrepreneurship': '#FFD700',
    'Moral and Citizenship Education': '#808000',
  };

  // Validity Period (days)
  static const int packageValidityDays = 365;
  
  // Content Types
  static const List<String> contentTypes = [
    'Video', 'Short Note', 'Quiz', 'Exam', 'Flashcard', 'Past Paper'
  ];
  
  // High School Subjects
  static const List<String> grade9Subjects = [
    'Biology', 'Chemistry', 'Citizenship', 'Economics',
    'English', 'Geography', 'History', 'IT', 'Mathematics', 'Physics'
  ];
  
  static const List<String> grade10Subjects = [
    'Biology', 'Chemistry', 'Citizenship', 'Economics',
    'English', 'Geography', 'History', 'IT', 'Mathematics', 'Physics'
  ];
  
  static const List<String> grade11NaturalSubjects = [
    'Agriculture', 'Aptitude', 'Biology', 'Chemistry',
    'English', 'IT', 'Mathematics', 'Physics'
  ];
  
  static const List<String> grade11SocialSubjects = [
    'Aptitude', 'Citizenship', 'Economics', 'English',
    'Geography', 'History', 'IT', 'Mathematics'
  ];
  
  static const List<String> grade12NaturalSubjects = [
    'Agriculture', 'Aptitude', 'Biology', 'Chemistry',
    'English', 'IT', 'Mathematics', 'Physics'
  ];
  
  static const List<String> grade12SocialSubjects = [
    'Aptitude', 'Citizenship', 'Economics', 'English',
    'Geography', 'History', 'IT', 'Mathematics'
  ];
  
  // University Subjects
  static const List<String> freshmanNaturalSem1 = [
    'English I', 'Geography', 'Logic', 'Mathematics', 'Physics', 'Psychology'
  ];
  
  static const List<String> freshmanSocialSem1 = [
    'Economics', 'English I', 'Geography', 'Logic', 'Mathematics', 'Psychology'
  ];
  
  static const List<String> freshmanPreEngSem2 = [
    'Anthropology', 'Applied Mathematics', 'C++ Programming', 'Emerging Technologies',
    'English II', 'Entrepreneurship', 'History', 'Moral and Citizenship Education'
  ];
  
  static const List<String> freshmanOtherNaturalSem2 = [
    'Anthropology', 'Biology', 'Chemistry', 'Economics',
    'Emerging Technologies', 'English II', 'History', 'Moral and Citizenship Education'
  ];
  
  // University Generations
  static const List<String> firstGeneration = [
    'AAU - Addis Ababa University',
    'JU - Jimma University',
    'HU - Hawassa University',
    'Haramaya University',
    'AASTU - Addis Ababa Science & Technology University',
    'AMU - Arba Minch University',
    'BDU - Bahir Dar University',
    'MU - Mekelle University',
  ];
  
  static const List<String> secondGeneration = [
    'Wollega University',
    'Wollo University',
    'Dilla University',
    'Debre Berhan University',
    'Wachamo University',
    'Jigjiga University',
    'Woldia University',
    'Debre Markos University',
  ];
  
  static const List<String> thirdGeneration = [
    'Mizan-Tepi University',
    'Bule Hora University',
    'Wolaita Sodo University',
    'Ambo University',
    'Assosa University',
    'Samara University',
    'Dire Dawa University',
    'Gambella University',
  ];
  
  static const List<String> fourthGeneration = [
    'Raya University',
    'Debre Tabor University',
    'Wachemo University',
    'Jinka University',
    'Aksum University',
    'Werabe University',
    'Kebri Dehar University',
    'Borana University',
  ];
  
  static const List<String> technologyInstitutes = [
    'AASTU - Addis Ababa Science & Technology University',
    'ASTU - Adama Science & Technology University',
    'JIT - Jimma Institute of Technology',
    'Mekelle Technology University',
  ];
  
  // Notification Type Colors
  static const Map<String, int> notificationTypeColors = {
    'payment': 0xFF4CAF50,
    'content': 0xFF2196F3,
    'quiz': 0xFFFFA726,
    'exam': 0xFF9C27B0,
    'achievement': 0xFFFFEB3B,
    'system': 0xFF795548,
  };
}

class PaymentDetails {
  final String name;
  final String number;
  final String holder;
  final String? icon;

  const PaymentDetails({
    required this.name,
    required this.number,
    required this.holder,
    this.icon,
  });
}