/// AppConfig
///
/// Central place for build-time configuration and credentials. Values are
/// supplied at build time with `--dart-define` (or a `--dart-define-from-file`
/// JSON) so that no secret is hardcoded in source control.
///
/// Example:
/// ```
/// flutter build apk \
///   --dart-define=IMGBB_API_KEY=xxxx \
///   --dart-define=TELEGRAM_BOT_TOKEN=xxxx \
///   --dart-define=TELEGRAM_ADMIN_CHAT_ID=xxxx \
///   --dart-define=CONTENT_REPO=nextgenethiopia-pro/content
/// ```
///
/// Anything sensitive (bot tokens) has no default and simply disables the
/// related feature when missing. Non-sensitive defaults (public content repo,
/// content branch) are provided for convenience.
class AppConfig {
  const AppConfig._();

  // ---- Image hosting (ImgBB) ----
  static const String imgbbApiKey = String.fromEnvironment('IMGBB_API_KEY');

  static bool get imgbbConfigured => imgbbApiKey.isNotEmpty;

  // ---- Telegram payment notifications (should move fully server-side) ----
  static const String telegramBotToken =
      String.fromEnvironment('TELEGRAM_BOT_TOKEN');
  static const String telegramAdminChatId =
      String.fromEnvironment('TELEGRAM_ADMIN_CHAT_ID');

  static bool get telegramConfigured =>
      telegramBotToken.isNotEmpty && telegramAdminChatId.isNotEmpty;

  // ---- GitHub content delivery ----
  /// owner/repo holding the educational content (metadata.json, units, etc.).
  static const String contentRepo = String.fromEnvironment(
    'CONTENT_REPO',
    defaultValue: 'nextgenethiopia-pro/content',
  );

  static const String contentBranch = String.fromEnvironment(
    'CONTENT_BRANCH',
    defaultValue: 'main',
  );

  /// Base URL for raw content files served from the content repo.
  static String get contentRawBaseUrl =>
      'https://raw.githubusercontent.com/$contentRepo/$contentBranch';

  /// Base URL for the content repo's GitHub API (used to list releases, etc.).
  static String get contentApiBaseUrl =>
      'https://api.github.com/repos/$contentRepo';
}
