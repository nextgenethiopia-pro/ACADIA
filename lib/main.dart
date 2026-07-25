import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'src/app.dart';
import 'src/core/blocs/app_bloc_observer.dart';
import 'src/core/di/injection.dart';
import 'src/core/services/cached_settings_service.dart';
import 'src/core/services/content_manager.dart';
import 'src/domain/repositories/github_content_repository.dart';
import 'firebase_options.dart';

void main() async {
  // Catch all errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    print('❌ Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    print('🚀 Starting ACADIA app...');

    try {
      // Set preferred orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      print('✅ Orientations set');

      // Set system UI overlay style
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
      print('✅ UI style set');

      // Initialize Firebase (for Auth & Database)
      print('🔥 Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully');

      // Initialize dependencies
      print('📦 Initializing dependencies...');
      await configureDependencies();
      print('✅ Dependencies configured');

      // Best-effort, offline-first bootstrap of the content source:
      //  * `settings/content_config` is read through [CachedSettingsService],
      //    which is TTL-cached in Isar — so a typical cold start hits ZERO
      //    Firestore reads (only a re-check every 12h). It tells the GitHub
      //    service which repo/branch to read.
      //  * a `version.json` probe invalidates stale catalog rows on a bump.
      // Non-blocking — startup stays cache-first and fast, and never crashes
      // when offline.
      unawaited(() async {
        try {
          final config = await getIt<CachedSettingsService>().load();
          final baseUrl = config['github_base_url']?.toString();
          getIt<GithubContentRepository>().configureBaseUrl(baseUrl);
          await getIt<ContentManager>().ensureContentVersion();
        } catch (e) {
          print('⚠️ Content bootstrap failed (continuing offline): $e');
        }
      }());

      // Set bloc observer
      Bloc.observer = AppBlocObserver();
      print('✅ Bloc observer set');

      print('🎉 Running app...');
      runApp(const ProviderScope(child: AcadiaApp()));
    } catch (e, stackTrace) {
      print('❌ Error during initialization: $e');
      print('Stack trace: $stackTrace');
      // Run app anyway with error state
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Initialization Error',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          print('🔄 Retrying initialization...');
                          main();
                        },
                        child: const Text('Retry'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Stack trace:\n$stackTrace',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }, (error, stackTrace) {
    print('❌ Unhandled error: $error');
    print('Stack trace: $stackTrace');
  });
}
