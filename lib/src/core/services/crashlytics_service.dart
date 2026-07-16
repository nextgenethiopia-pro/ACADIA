import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashlyticsService {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  static Future<void> initialize() async {
    // Pass all uncaught errors to Crashlytics
    FlutterError.onError = (errorDetails) {
      _crashlytics.recordFlutterFatalError(errorDetails);
    };

    // Pass async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    await _crashlytics.setCrashlyticsCollectionEnabled(true);
  }

  static Future<void> setUserIdentifier(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  static Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  static Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  static Future<void> recordError(dynamic error, StackTrace? stack, {bool fatal = false}) async {
    await _crashlytics.recordError(error, stack, fatal: fatal);
  }
}