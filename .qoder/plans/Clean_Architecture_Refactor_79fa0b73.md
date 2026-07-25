# Clean Architecture Refactor (ACADIA)

## Summary
Reorganize all 111 Dart files (~40k lines) into a feature-first clean architecture. Introduce a repository layer (abstract interfaces + implementations) over the existing singleton services, wire dependency injection with `get_it`, standardize naming, extract a shared reusable-widget library, and apply safe performance improvements. Behavior stays identical: services keep their current logic, all public class APIs are preserved, and only imports/locations/wrappers change.

Hard success criterion: `flutter analyze` clean (no new errors) and `flutter build apk --debug` succeeds after the refactor.

## Target Folder Structure
```
lib/
  main.dart, firebase_options.dart
  src/
    app/
      app.dart
      router/app_router.dart
    core/
      constants/        (colors, app_constants, app_icons, subject_icons,
                         payment_methods, universities, academic_structure)
      theme/            (app_theme)
      di/               (injection.dart - registers services + repositories)
      utils/            (helpers, validators, app_logger)
      blocs/theme/      (theme_bloc/event/state)
    data/
      datasources/      (firebase_service, firebase_auth_service, offline_database,
                         content_config_service, notification_service,
                         download_manager, package_service, progress_tracking_service,
                         profile_storage_service, image_upload_service, crashlytics_service)
      models/           (user, subject, chapter, content, payment, notification, quiz + models.dart barrel)
      repositories/     (*_repository_impl.dart)
    domain/
      repositories/     (abstract *_repository.dart interfaces)
    features/
      auth/{screens,widgets,bloc}
      onboarding/{screens,widgets}
      dashboard/{screens,widgets}
      content/{screens,widgets}
      entrance/{screens,widgets}
      admin/{screens,widgets}
      payment/{screens,widgets}
      settings/{screens,widgets}
    shared/
      widgets/          (gradient_button, placeholder_image, subject_icon_widget, auth_gate + new shared widgets)
```

## Naming Conventions
- Files: `snake_case` with role suffix — `*_screen.dart`, `*_repository.dart` (abstract), `*_repository_impl.dart`, `*_model.dart`, `*_service.dart` (datasources), `*_bloc.dart`, `*_widget.dart`.
- Classes: `PascalCase`; abstract repo `XxxRepository`, impl `XxxRepositoryImpl`, datasource keeps `XxxService`.
- Every page class ends in `Screen`; every reusable widget ends in `Widget`/descriptive noun.
- Constants grouped under `AppColors`, `AppConstants`, `AppIcons`, `PaymentMethods`.
- No abbreviations in public identifiers; booleans read as predicates (`isPackageLocked`, `hasActivePackage`).

## Repository Layer (Domain + Data)
Introduce abstract interfaces in `domain/repositories/` and implementations in `data/repositories/`, each delegating to an existing service (no logic rewrite):
- `AuthRepository` -> `FirebaseAuthService`
- `UserRepository` / `ProfileRepository` -> `ProfileStorageService` + `FirebaseService` (users)
- `ContentRepository` -> `FirebaseService` (content) + `ContentConfigService`
- `ChapterRepository` -> `FirebaseService` (chapters)
- `PaymentRepository` -> `FirebaseService` (payments)
- `PackageRepository` -> `PackageService`
- `NotificationRepository` -> `NotificationService`
- `ProgressRepository` -> `ProgressTrackingService`
- `DownloadRepository` -> `DownloadManager` + `OfflineDatabase`

Screens keep `setState` but resolve repositories via `getIt<XxxRepository>()` instead of instantiating services directly.

## DI Wiring (core/di/injection.dart)
Expand `configureDependencies()` to register: `SharedPreferences` (existing), all services as singletons, and every repository bound to its impl. Called once in `main.dart` before `runApp`.

## Shared Reusable Components (shared/widgets/)
Extract recurring UI patterns found across admin/content/dashboard screens:
- `AppScaffold` / `AppAppBar` (consistent app bar + back handling)
- `PrimaryButton` (generalize existing `gradient_button`)
- `AppCard`, `SectionHeader`, `AppDropdownField`, `BreadcrumbTrail`
- `EmptyStateView`, `LoadingView`, `ErrorRetryView`
- `PackageBanner` (the locked/unlocked banner duplicated in subjects_tab and others)
- `ConfirmDialog` helper
Replace duplicated inline implementations with these; keep visuals pixel-identical.

## Performance Improvements (behavior-preserving)
- Add `const` to constructors/widgets wherever possible.
- Replace deprecated `.withOpacity(x)` with `.withValues(alpha: x)` project-wide.
- Convert large `children: list.map(...).toList()` `Column`/`Wrap` blocks that render long content into `ListView.builder` / `GridView.builder`.
- Introduce `cached_network_image` for remote images (Internet Archive/Cloudinary) to cut re-downloads.
- Hoist static lists (speed options, grade lists, subject maps) to `const`/top-level.
- Debounce search `TextField`s (user/content management screens) ~300ms.
- Add `limit`/pagination to unbounded Firestore reads in admin lists; eliminate N+1 fetches inside loops where present.
- Ensure all `TextEditingController`/`AnimationController`/`VideoPlayerController` are disposed.
- Wrap heavy list items in `RepaintBoundary`.

## Execution Order (one pass, verified at end)
1. Create new folders; move `constants/`, `theme/`, `utils/`, `app_logger`, `theme` bloc into `core/`.
2. Move `models/` -> `data/models/`; move all `services/` -> `data/datasources/`.
3. Add `domain/repositories/` interfaces + `data/repositories/` impls; expand DI.
4. Move `screens/*` and `widgets/*` into `features/<feature>/{screens,widgets}` and `shared/widgets/`.
5. Rewrite all `package:acadia/src/...` imports to new paths across the codebase.
6. Extract shared widgets; replace duplicated inline UI.
7. Repoint screens from direct service instantiation to `getIt` repositories.
8. Apply performance fixes.
9. Update `app_router.dart` route imports.

## Test Plan
- `flutter pub get`
- `flutter analyze` — must report no new errors (baseline vs. before).
- `flutter build apk --debug` — must succeed.
- Manual smoke of critical flows unchanged: launch/splash, login/register, onboarding path selection, dashboard tabs, chapter content open (video/quiz/exam/flashcard/pdf), admin content upload (with mandatory-chapter validation intact), payment submit.

## Assumptions
- No use-case/interactor layer (per your choice); presentation calls repositories directly.
- Presentation stays on `setState` (+ existing auth/theme BLoC); no screen is converted to Cubit/BLoC.
- Public class names/method signatures are preserved so functionality is identical; only locations, imports, wrappers, shared widgets, and perf details change.
- `pubspec.yaml` may gain `cached_network_image` (only new dependency).
- Given the size, if analyze/build surfaces errors, fixes are limited to import/wiring corrections — not behavior changes.
