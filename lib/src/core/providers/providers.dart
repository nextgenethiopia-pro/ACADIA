import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/injection.dart';
import '../services/cached_settings_service.dart';
import '../services/content_manager.dart';
import '../services/github_content_service.dart';
import '../../local_database/isar_service.dart';

/// Riverpod provider foundation for the ACADIA app.
///
/// During the bloc -> riverpod migration these providers mostly *bridge* the
/// existing get_it singletons (`getIt<T>()`), so new riverpod code and legacy
/// bloc / get_it code share ONE instance. New offline-first services that have
/// no bloc equivalent are constructed directly here.
///
/// The app is wrapped in a `ProviderScope` in `main.dart`.

/// Isar primary store singleton (offline-first local database + cache).
final isarServiceProvider =
    Provider<IsarService>((ref) => IsarService.instance);

/// GitHub content fetcher (network + Isar cache). Bridges get_it.
final githubContentServiceProvider = Provider<GithubContentService>(
  (ref) => getIt<GithubContentService>(),
);

/// TTL-cached Firestore `settings/content_config` reader. Bridges get_it.
final cachedSettingsServiceProvider = Provider<CachedSettingsService>(
  (ref) => getIt<CachedSettingsService>(),
);

/// Offline-first content orchestration entry point for presentation code.
/// Wraps [GithubContentService] with a typed `Result` API + retry.
final contentManagerProvider = Provider<ContentManager>(
  (ref) => ContentManager(github: ref.read(githubContentServiceProvider)),
);
