/// Centralized access to build-time secrets.
///
/// Secrets MUST be supplied via `--dart-define`, never committed in source.
/// The fallback values below are read ONLY so existing builds keep working
/// until each key is rotated and supplied via dart-define; treat them as
/// legacy placeholders to be removed.
///
/// Supply at build/run time, e.g.:
///   flutter run \
///     --dart-define=IMGBB_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
///
/// Then remove the default here and rotate the exposed key.
class Secrets {
  const Secrets._();

  /// ImgBB upload API key used by [ImgbbService] for payment-proof uploads.
  ///
  /// ⚠️ LEGACY: the default below is the previously-committed key. It is
  /// exposed in git history and SHOULD be rotated. Override it with
  /// `--dart-define=IMGBB_API_KEY=...` and remove the default once rotated.
  static const String imgbbApiKey =
      String.fromEnvironment('IMGBB_API_KEY', defaultValue: 'dd99798a85c18c52282c4d2dfd128146');
}
