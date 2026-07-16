import 'package:go_router/go_router.dart';

// ============================================================
// ONBOARDING (12 screens)
// ============================================================
import '../screens/onboarding/splash_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/onboarding/academic_path_screen.dart';
import '../screens/onboarding/grade_selection_screen.dart';
import '../screens/onboarding/stream_selection_screen.dart';
import '../screens/onboarding/generation_selection_screen.dart';
import '../screens/onboarding/university_selection_screen.dart';
import '../screens/onboarding/year_selection_screen.dart';
import '../screens/onboarding/senior_year_screen.dart';
import '../screens/onboarding/semester_selection_screen.dart';
import '../screens/onboarding/university_stream_selection_screen.dart';
import '../screens/onboarding/university_track_selection_screen.dart';

// ============================================================
// AUTH (5 screens)
// ============================================================
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/profile_setup_complete_screen.dart';

// ============================================================
// DASHBOARD (1 main + 6 tabs)
// ============================================================
import '../screens/dashboard/dashboard_screen.dart';

// ============================================================
// SUBJECT PORTAL
// ============================================================
import '../screens/subject/subject_portal_screen.dart';

// ============================================================
// CONTENT (8 screens)
// ============================================================
import '../screens/content/chapter_content_screen.dart';
import '../screens/content/video_player_screen.dart';
import '../screens/content/pdf_viewer_screen.dart';
import '../screens/content/quiz_screen.dart';
import '../screens/content/quiz_result_screen.dart';
import '../screens/content/exam_screen.dart';
import '../screens/content/exam_result_screen.dart';
import '../screens/content/flashcard_screen.dart';

// ============================================================
// ENTRANCE (5 screens)
// ============================================================
import '../screens/entrance/entrance_past_papers_screen.dart';
import '../screens/entrance/entrance_exam_screen.dart';
import '../screens/entrance/entrance_subject_screen.dart';
import '../screens/entrance/entrance_schedule_screen.dart';
import '../screens/entrance/entrance_tips_screen.dart';

// ============================================================
// PAYMENT (2 screens)
// ============================================================
import '../screens/payment/payment_screen.dart';
import '../screens/payment/payment_history_screen.dart';

// ============================================================
// SETTINGS (9 screens)
// ============================================================
import '../screens/settings/edit_profile_screen.dart';
import '../screens/settings/change_password_screen.dart';
import '../screens/settings/app_settings_screen.dart';
import '../screens/settings/downloads_manager_screen.dart';
import '../screens/settings/help_center_screen.dart';
import '../screens/settings/tutorial_video_screen.dart';
import '../screens/settings/about_screen.dart';
import '../screens/settings/privacy_policy_screen.dart';
import '../screens/settings/terms_of_service_screen.dart';

// ============================================================
// ADMIN (11 screens)
// ============================================================
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/content_upload_screen.dart';
import '../screens/admin/content_management_screen.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/admin/payment_approval_screen.dart';
import '../screens/admin/notification_creation_screen.dart';
import '../screens/admin/analytics_dashboard_screen.dart';
import '../screens/admin/app_settings_screen.dart' as admin_settings;
import '../screens/admin/entrance_management_screen.dart';
import '../screens/admin/about_management_screen.dart';
import '../screens/admin/image_management_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // ============================================================
      // ONBOARDING (13 screens)
      // ============================================================
      GoRoute(path: '/splash', name: 'splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/welcome', name: 'welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/academic-path', name: 'academic-path', builder: (context, state) => const AcademicPathScreen()),
      GoRoute(path: '/grade-selection', name: 'grade-selection', builder: (context, state) => const GradeSelectionScreen()),
      GoRoute(path: '/stream-selection', name: 'stream-selection', builder: (context, state) => const StreamSelectionScreen()),
      GoRoute(path: '/generation-selection', name: 'generation-selection', builder: (context, state) => const GenerationSelectionScreen()),
      GoRoute(path: '/university-selection', name: 'university-selection', builder: (context, state) => const UniversitySelectionScreen()),
      GoRoute(path: '/year-selection', name: 'year-selection', builder: (context, state) => const YearSelectionScreen()),
      GoRoute(path: '/senior-year', name: 'senior-year', builder: (context, state) => const SeniorYearScreen()),
      GoRoute(path: '/semester-selection', name: 'semester-selection', builder: (context, state) => const SemesterSelectionScreen()),
      GoRoute(path: '/university-stream-selection', name: 'university-stream-selection', builder: (context, state) => const UniversityStreamSelectionScreen()),
      GoRoute(path: '/university-track-selection', name: 'university-track-selection', builder: (context, state) => const UniversityTrackSelectionScreen()),

      // ============================================================
      // AUTH (5 screens)
      // ============================================================
      GoRoute(path: '/login', name: 'login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', name: 'register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', name: 'forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/verify-email', name: 'verify-email', builder: (context, state) => const EmailVerificationScreen()),
      GoRoute(path: '/profile-setup-complete', name: 'profile-setup-complete', builder: (context, state) => const ProfileSetupCompleteScreen()),

      // ============================================================
      // DASHBOARD
      // ============================================================
      GoRoute(path: '/dashboard', name: 'dashboard', builder: (context, state) => const DashboardScreen()),

      // ============================================================
      // SUBJECT PORTAL
      // ============================================================
      GoRoute(
        path: '/subject-portal',
        name: 'subject-portal',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SubjectPortalScreen(
            subjectId: extra?['subject'] ?? '',
          );
        },
      ),

      // ============================================================
      // CONTENT (8 screens)
      // ============================================================
      GoRoute(
        path: '/chapter-content',
        name: 'chapter-content',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChapterContentScreen(
            chapterId: extra?['chapterId'] ?? '',
            subjectName: extra?['subjectName'] ?? '',
            chapterName: extra?['chapterName'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/video-player',
        name: 'video-player',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VideoPlayerScreen(
            contentId: extra?['contentId'] ?? '',
            title: extra?['title'] ?? 'Video',
          );
        },
      ),
      GoRoute(
        path: '/pdf-viewer',
        name: 'pdf-viewer',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PdfViewerScreen(
            contentId: extra?['contentId'] ?? '',
            title: extra?['title'] ?? 'Document',
          );
        },
      ),
      GoRoute(
        path: '/quiz',
        name: 'quiz',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return QuizScreen(
            contentId: extra?['contentId'] ?? '',
            title: extra?['title'] ?? 'Quiz',
          );
        },
      ),
      GoRoute(
        path: '/quiz-result',
        name: 'quiz-result',
        builder: (context, state) => QuizResultScreen(resultData: state.extra as Map<String, dynamic>?),
      ),
      GoRoute(
        path: '/exam',
        name: 'exam',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ExamScreen(
            contentId: extra?['contentId'] ?? '',
            title: extra?['title'] ?? 'Exam',
          );
        },
      ),
      GoRoute(
        path: '/exam-result',
        name: 'exam-result',
        builder: (context, state) => ExamResultScreen(resultData: state.extra as Map<String, dynamic>?),
      ),
      GoRoute(
        path: '/flashcard',
        name: 'flashcard',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return FlashcardScreen(
            contentId: extra?['contentId'] ?? '',
            title: extra?['title'] ?? 'Flashcards',
          );
        },
      ),

      // ============================================================
      // ENTRANCE (5 screens)
      // ============================================================
      GoRoute(path: '/entrance/past-papers', name: 'entrance-past-papers', builder: (context, state) => const EntrancePastPapersScreen()),
      GoRoute(
        path: '/entrance/exam',
        name: 'entrance-exam',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return EntranceExamScreen(
            subject: extra?['subject']?.toString(),
            stream: extra?['stream']?.toString(),
            grade: extra?['grade']?.toString(),
          );
        },
      ),
      GoRoute(
        path: '/entrance/subject',
        name: 'entrance-subject',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return EntranceSubjectScreen(
            subject: extra?['subject'] ?? '',
            stream: extra?['stream'] ?? '',
          );
        },
      ),
      GoRoute(path: '/entrance/schedule', name: 'entrance-schedule', builder: (context, state) => const EntranceScheduleScreen()),
      GoRoute(path: '/entrance/tips', name: 'entrance-tips', builder: (context, state) => const EntranceTipsScreen()),

      // ============================================================
      // PAYMENT (2 screens)
      // ============================================================
      GoRoute(path: '/payment', name: 'payment', builder: (context, state) => const PaymentScreen()),
      GoRoute(path: '/payment-history', name: 'payment-history', builder: (context, state) => const PaymentHistoryScreen()),

      // ============================================================
      // SETTINGS (9 screens)
      // ============================================================
      GoRoute(path: '/settings', name: 'settings', builder: (context, state) => const AppSettingsScreen()),
      GoRoute(path: '/settings/edit-profile', name: 'edit-profile', builder: (context, state) => const EditProfileScreen()),
      GoRoute(path: '/settings/change-password', name: 'change-password', builder: (context, state) => const ChangePasswordScreen()),
      GoRoute(path: '/settings/downloads', name: 'downloads', builder: (context, state) => const DownloadsManagerScreen()),
      GoRoute(path: '/settings/help', name: 'help', builder: (context, state) => const HelpCenterScreen()),
      GoRoute(path: '/tutorial-video', name: 'tutorial-video', builder: (context, state) => const TutorialVideoScreen()),
      GoRoute(path: '/settings/about', name: 'about', builder: (context, state) => const AboutScreen()),
      GoRoute(path: '/settings/privacy', name: 'privacy', builder: (context, state) => const PrivacyPolicyScreen()),
      GoRoute(path: '/settings/terms', name: 'terms', builder: (context, state) => const TermsOfServiceScreen()),

      // ============================================================
      // ADMIN (11 screens)
      // ============================================================
      GoRoute(path: '/admin/dashboard', name: 'admin-dashboard', builder: (context, state) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/content-upload', name: 'content-upload', builder: (context, state) => const ContentUploadScreen()),
      GoRoute(path: '/admin/content-management', name: 'content-management', builder: (context, state) => const ContentManagementScreen()),
      GoRoute(path: '/admin/user-management', name: 'user-management', builder: (context, state) => const UserManagementScreen()),
      GoRoute(path: '/admin/payment-approval', name: 'payment-approval', builder: (context, state) => const PaymentApprovalScreen()),
      GoRoute(path: '/admin/create-notification', name: 'create-notification', builder: (context, state) => const NotificationCreationScreen()),
      GoRoute(path: '/admin/analytics', name: 'analytics', builder: (context, state) => const AnalyticsDashboardScreen()),
      GoRoute(path: '/admin/app-settings', name: 'admin-app-settings', builder: (context, state) => const admin_settings.AdminAppSettingsScreen()),
      GoRoute(path: '/admin/entrance-management', name: 'entrance-management', builder: (context, state) => const EntranceManagementScreen()),
      GoRoute(path: '/admin/about-management', name: 'about-management', builder: (context, state) => const AboutManagementScreen()),
      GoRoute(path: '/admin/image-management', name: 'image-management', builder: (context, state) => const ImageManagementScreen()),
    ],
  );
}