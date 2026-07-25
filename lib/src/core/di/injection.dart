import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/local_database/isar_service.dart';

import '../services/crashlytics_service.dart';
import '../services/cached_settings_service.dart';
import '../services/content_config_service.dart';
import '../services/content_manager.dart';
import '../services/download_manager.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_service.dart';
import '../services/github_content_service.dart';
import '../services/notification_service.dart';
import '../services/offline_database.dart';
import '../services/package_service.dart';
import '../services/profile_storage_service.dart';
import '../services/progress_tracking_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/content_repository_impl.dart';
import '../../data/repositories/download_repository_impl.dart';
import '../../data/repositories/github_content_repository_impl.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/repositories/package_repository_impl.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/progress_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/repositories/download_repository.dart';
import '../../domain/repositories/github_content_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/package_repository.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/repositories/user_repository.dart';

final GetIt getIt = GetIt.instance;

/// Registers external dependencies, data-source services, and repositories.
///
/// Called once from `main.dart` before `runApp`. Repositories are bound to
/// their contracts so the presentation layer resolves abstractions only.
///
/// New offline-first services ([CachedSettingsService], [ContentManager]) are
/// registered here and also exposed via riverpod providers
/// (see `core/providers/providers.dart`) so presentation code can migrate to
/// riverpod incrementally while sharing the same singletons with legacy
/// get_it / bloc code.
Future<void> configureDependencies() async {
  // ---- External ----
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // ---- Data-source services (singletons) ----
  getIt.registerLazySingleton<IsarService>(() => IsarService.instance);
  getIt.registerLazySingleton<OfflineDatabase>(() => OfflineDatabase.instance);
  getIt.registerLazySingleton<FirebaseService>(() => FirebaseService());
  getIt.registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService());
  getIt.registerLazySingleton<PackageService>(() => PackageService());

  // GitHub content reads are cached offline-first in Isar by the service, so it
  // needs the Isar primary store.
  getIt.registerLazySingleton<GithubContentService>(
      () => GithubContentService(isar: getIt<IsarService>()));

  // Offline-first services added during the Firestore-reduction pass.
  getIt.registerLazySingleton<CachedSettingsService>(
      () => CachedSettingsService(isar: getIt<IsarService>()));
  getIt.registerLazySingleton<ContentManager>(
      () => ContentManager(github: getIt<GithubContentService>()));

  getIt.registerLazySingleton<DownloadManager>(() => DownloadManager());
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<ProfileStorageService>(
      () => ProfileStorageService());
  // ImgbbService exposes only static methods (used directly in payment_screen),
  // so it is intentionally NOT registered here.
  getIt.registerLazySingleton<ContentConfigService>(() => ContentConfigService());
  getIt.registerLazySingleton<ProgressTrackingService>(
      () => ProgressTrackingService());
  getIt.registerLazySingleton<CrashlyticsService>(() => CrashlyticsService());

  // ---- Repositories (contract -> implementation) ----
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<FirebaseAuthService>()),
  );
  getIt.registerLazySingleton<PackageRepository>(
    () => PackageRepositoryImpl(getIt<PackageService>()),
  );
  getIt.registerLazySingleton<ContentRepository>(
    () => ContentRepositoryImpl(getIt<FirebaseService>()),
  );
  getIt.registerLazySingleton<GithubContentRepository>(
    () => GithubContentRepositoryImpl(getIt<GithubContentService>()),
  );
  getIt.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(getIt<FirebaseService>()),
  );
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(getIt<FirebaseService>()),
  );
  getIt.registerLazySingleton<ProgressRepository>(
    () => ProgressRepositoryImpl(getIt<FirebaseService>()),
  );
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(getIt<FirebaseService>()),
  );
  getIt.registerLazySingleton<DownloadRepository>(
    () => DownloadRepositoryImpl(
      getIt<DownloadManager>(),
      getIt<OfflineDatabase>(),
    ),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(getIt<ProfileStorageService>()),
  );
}
