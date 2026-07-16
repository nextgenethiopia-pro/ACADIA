import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'firebase_service.dart';

/// The action the app should take based on Firestore `settings/app`.
enum AppUpdateAction {
  /// App is up to date and usable.
  none,

  /// A newer version exists but the current one is still allowed (optional).
  optionalUpdate,

  /// Current version is below `minimumVersion`; usage must be blocked.
  forceUpdate,

  /// `maintenance` is true; usage must be blocked.
  maintenance,
}

/// Result of an update/maintenance check.
class AppUpdateStatus {
  const AppUpdateStatus({
    required this.action,
    this.latestVersion,
    this.minimumVersion,
    this.updateUrl,
    this.message,
  });

  final AppUpdateAction action;
  final String? latestVersion;
  final String? minimumVersion;
  final String? updateUrl;
  final String? message;

  bool get blocks =>
      action == AppUpdateAction.forceUpdate ||
      action == AppUpdateAction.maintenance;
}

/// AppUpdateService
///
/// Reads `settings/app` from Firestore and decides whether the running build
/// must be updated (force update), is optionally out of date, or the app is in
/// maintenance mode. This lets configuration change without shipping a new APK.
///
/// Expected `settings/app` fields:
/// - `latestVersion`  (string, e.g. "2.0.1")
/// - `minimumVersion` (string, e.g. "1.8.0")
/// - `maintenance`    (bool)
/// - `maintenanceMessage` (string, optional)
/// - `updateUrl` / `android_update_url` (string, optional store link)
class AppUpdateService {
  AppUpdateService({FirebaseService? firebaseService})
      : _firebaseService = firebaseService ?? FirebaseService();

  final FirebaseService _firebaseService;

  Future<AppUpdateStatus> checkStatus() async {
    Map<String, dynamic>? settings;
    try {
      settings = await _firebaseService.getAppSettings();
    } catch (e) {
      debugPrint('AppUpdateService: failed to read settings/app: $e');
      // Fail open: never block the user because config could not be read.
      return const AppUpdateStatus(action: AppUpdateAction.none);
    }

    if (settings == null) {
      return const AppUpdateStatus(action: AppUpdateAction.none);
    }

    final latestVersion = settings['latestVersion']?.toString();
    final minimumVersion = settings['minimumVersion']?.toString();
    final maintenance = settings['maintenance'] == true;
    final updateUrl = (settings['updateUrl'] ?? settings['android_update_url'])
        ?.toString();
    final message = settings['maintenanceMessage']?.toString();

    if (maintenance) {
      return AppUpdateStatus(
        action: AppUpdateAction.maintenance,
        latestVersion: latestVersion,
        minimumVersion: minimumVersion,
        updateUrl: updateUrl,
        message: message,
      );
    }

    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    if (minimumVersion != null &&
        compareVersions(currentVersion, minimumVersion) < 0) {
      return AppUpdateStatus(
        action: AppUpdateAction.forceUpdate,
        latestVersion: latestVersion,
        minimumVersion: minimumVersion,
        updateUrl: updateUrl,
        message: message,
      );
    }

    if (latestVersion != null &&
        compareVersions(currentVersion, latestVersion) < 0) {
      return AppUpdateStatus(
        action: AppUpdateAction.optionalUpdate,
        latestVersion: latestVersion,
        minimumVersion: minimumVersion,
        updateUrl: updateUrl,
        message: message,
      );
    }

    return AppUpdateStatus(
      action: AppUpdateAction.none,
      latestVersion: latestVersion,
      minimumVersion: minimumVersion,
      updateUrl: updateUrl,
    );
  }

  /// Compares two dotted numeric version strings.
  ///
  /// Returns a negative number if [a] < [b], zero if equal, positive if
  /// [a] > [b]. Non-numeric or missing segments are treated as 0.
  static int compareVersions(String a, String b) {
    final aParts = _segments(a);
    final bParts = _segments(b);
    final length = aParts.length > bParts.length ? aParts.length : bParts.length;
    for (var i = 0; i < length; i++) {
      final aVal = i < aParts.length ? aParts[i] : 0;
      final bVal = i < bParts.length ? bParts[i] : 0;
      if (aVal != bVal) return aVal - bVal;
    }
    return 0;
  }

  static List<int> _segments(String version) {
    // Drop any build/suffix such as "1.2.3+4" or "1.2.3-beta".
    final core = version.split(RegExp(r'[+-]')).first;
    return core
        .split('.')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .toList();
  }
}
