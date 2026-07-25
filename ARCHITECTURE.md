also add this                                 # ACADIA - Final System Architecture (Production Version)

## Project Philosophy

ACADIA is designed to be:

* Cost-efficient to operate.
* Easy to maintain and update.
* Offline-friendly for students with limited internet access.
* Highly scalable without increasing Firebase costs.
* Modular and future-proof.
* Admin-controlled without requiring frequent APK updates.
* Simple enough for long-term maintenance while supporting future expansion.

The architecture follows an offline-first and content-delivery approach rather than using Firebase as the primary backend for everything.

---

# Core Architecture

The system is divided into six major components:

1. Flutter Application
2. Firebase Authentication
3. Firestore Database
4. GitHub Content Delivery System
5. Local Storage System
6. External Media Services

---

# System Overview

```
                      ACADIA

                    Flutter App
                          |
        ------------------------------------------
        |                |                       |
 Firebase Auth       Firestore              Content System
(Login Only)      (Users & Settings)       (GitHub + Cache)
        |                |                       |
        |                |                       |
        ------------------------------------------
                          |
                    Content Manager
                          |
                -------------------------
                |                       |
            Local Cache               GitHub
             (Isar DB)              (Metadata)
                |                       |
                |                       |
         Download Manager         GitHub Releases
                |
                |
            Progress Storage
                |
        --------------------------
        |                        |
      ImgBB                   YouTube
     (Images)               (Videos)
```

---

# Firebase Authentication

Firebase Authentication is used ONLY for user authentication.

Responsibilities:

* Login
* Registration
* Email Verification
* Forgot Password
* Password Reset
* Session Management

Nothing else should be stored in Firebase Authentication.

Example:

```
Email
Password
UID
```

No educational content or application data should be stored here.

---

# Firestore Database

Firestore should be used only for:

* User information
* Subscription information
* Application settings
* Admin configurations
* Dynamic content that changes frequently

The goal is to minimize Firestore reads and costs.

---

# User Collection

```
users

uid
    email
    fullName
    profilePicture
    academicPath
    grade
    stream

    subscriptionType
    premiumPackage
    purchaseDate
    expiresAt

    status
    joinedDate
```

Subscription Types:

```
FREE
PREMIUM
LIFETIME
EXPIRED
```

Examples:

```
FREE
PREMIUM
LIFETIME
EXPIRED
```

---

# Settings Collection

The settings collection allows administrators to modify application behavior without redeploying the APK.

Example:

```
settings

latest_version
minimum_supported_version

maintenance_mode

welcome_message

home_banners

featured_subjects

featured_courses

telegram_group

telegram_channel

youtube_channel

premium_price

contact_email

contact_phone

social_links

popup_messages

enable_dark_mode

enable_ai_assistant

enable_new_dashboard
```

Benefits:

* Real-time updates.
* No APK updates.
* Centralized application configuration.

---

# Admin Dashboard Features

The admin dashboard should contain the following modules.

### Dashboard

```
Overview
System Information
User Statistics
```

### Content Management

```
Add Subject
Add Unit
Manage Chapters
Upload PDFs
Manage Flashcards
Manage MCQs
Manage Exams
Manage Metadata
```

### User Management

```
View Users
Ban User
Reset Account
Manage Subscription
View User Information
```

### Subscription Management

```
Premium Pricing
Package Management
Subscription Status
```

### Media Management

```
Manage Images
Manage Banners
Manage Videos
```

### App Management

```
Maintenance Mode
Force Update
Minimum Supported Version
Popup Announcements
Contact Information
```

### Developer Settings

```
Feature Flags

Enable AI Assistant

Enable Dark Mode

Enable New Dashboard

API URLs

GitHub Version

Debug Options
```

---

# GitHub Content Delivery System

GitHub will serve educational content instead of Firestore.

GitHub stores:

```
metadata.json

subjects.json

units.json

chapters.json

flashcards.json

mcqs.json

practice_exams.json

past_papers.json
```

Educational content is completely separated from Firebase.

Benefits:

* Free hosting.
* Version control.
* Low operational cost.
* Easy content updates.

---

# GitHub Releases

Large files should not be stored directly inside the repository.

Examples:

```
PDF Notes

Past Papers

ZIP Downloads

Resource Packs

Question Banks
```

GitHub Releases provides:

* Faster downloads
* CDN support
* File versioning
* Better organization

---

# Content Versioning System

Every metadata file should contain version information.

Example:

```
Version 1.0
Version 1.1
Version 1.2
```

The application should automatically check:

```
Current Version

↓

Latest Version

↓

Update Required?

↓

Download New Metadata
```

This significantly reduces bandwidth usage.

---

# Local Storage System

ACADIA should follow an offline-first design.

Recommended Database:

```
Isar Database
```

Responsibilities:

```
Bookmarks

Favorites

Completed Lessons

Quiz Scores

Reading Progress

Recent Activity

Offline Metadata

Downloaded Files

Download History

Downloaded PDFs

Downloaded Flashcards

Downloaded Exams

Last Opened Pages
```

Benefits:

* Extremely fast.
* No Firestore costs.
* Excellent Flutter support.
* Full offline functionality.

---

# Metadata Cache System

The application should never request metadata from GitHub every time it launches.

Instead:

```
App Opens

↓

Check Local Cache

↓

Cache Expired?

↓

NO

↓

Use Local Cache

-------------------------

YES

↓

Fetch Latest Metadata

↓

Update Cache
```

Recommended Cache Duration:

```
6 Hours

or

24 Hours
```

Benefits:

* Faster startup.
* Reduced internet usage.
* Improved user experience.

---

# Content Manager

The Content Manager acts as an abstraction layer between the application and external content providers.

Responsibilities:

```
Fetch Metadata

Cache Metadata

Handle Downloads

Manage Content Versions

Validate Files

Provide Offline Support
```

Advantages:

* Future migration becomes easy.
* UI is completely independent of GitHub.
* Centralized content handling.

---

# Download Manager

Responsibilities:

```
Download PDFs

Download Metadata

Download Resource Packs

Download Images

Track Download Progress

Resume Downloads

Delete Downloads
```

All downloaded files should be accessible offline.

---

# YouTube Integration

Videos are not stored inside the application.

Only the following information is stored:

```
Title

Description

YouTube URL

Grade

Subject

Unit
```

Benefits:

* No storage costs.
* Unlimited video hosting.
* Better streaming performance.

---

# ImgBB Integration

Used exclusively for images.

Stores:

```
Profile Pictures

Subject Covers

Unit Covers

Banner Images

Teacher Images

News Images
```

Firestore stores only image URLs.

Benefits:

* Very low operational cost.
* Simplifies media management.
* Reduces Firebase Storage dependency.

---

# Repository Layer

The application should follow Clean Architecture principles.

```
Presentation Layer

↓

Repository Layer

↓

Content Manager

↓

Data Sources

↓

External Services
```

Repositories include:

```
AuthRepository

UserRepository

ProfileRepository

ContentRepository

ChapterRepository

PaymentRepository

PackageRepository

NotificationRepository

ProgressRepository

DownloadRepository
```

---

# Dependency Injection

Dependency Injection should use:

```
get_it
```

All services and repositories should be registered during application startup.

Benefits:

* Cleaner architecture.
* Easier testing.
* Improved maintainability.

---

# Shared Widget System

Reusable widgets should be centralized.

Examples:

```
AppScaffold

PrimaryButton

AppCard

SectionHeader

AppDropdownField

LoadingView

ErrorRetryView

EmptyStateView

PackageBanner

ConfirmDialog

SubjectCard

ContentCard

VideoCard
```

Benefits:

* Less duplicated code.
* Consistent UI.
* Easier maintenance.

---

# Performance Optimizations

The project should include:

```
Const Constructors

Widget Optimization

Metadata Caching

Offline Storage

Pagination

Debounced Search

Lazy Loading

Image Caching

RepaintBoundary Usage

Builder Widgets

Controller Disposal
```

The following should be minimized:

```
Firestore Reads

Repeated Network Requests

Unnecessary Rebuilds

Large Memory Usage
```

---

# Application Startup Flow

```
App Opens

↓

Initialize Services

↓

Initialize Dependency Injection

↓

Check Login Status

↓

Load Firestore Settings

↓

Load Cached Metadata

↓

Check Metadata Version

↓

Download Updates If Necessary

↓

Initialize Local Database

↓

Load User Information

↓

Show Dashboard
```

---

# Folder Structure

```
lib/

main.dart

src/

app/

core/

constants/
theme/
utils/
di/
blocs/

data/

datasources/
repositories/
models/

domain/

repositories/

features/

auth/
dashboard/
content/
entrance/
payment/
admin/
settings/
onboarding/

shared/

widgets/

assets/
```

---

# Development Principles

The following rules should always be followed:

* Never change business logic unless required.
* Preserve existing functionality during refactoring.
* Minimize Firebase usage whenever possible.
* Prefer offline storage over cloud storage.
* Prefer GitHub over Firestore for educational content.
* Prefer reusable components over duplicated code.
* Use version-controlled content delivery.
* Keep educational content independent of application updates.
* Maintain backward compatibility whenever possible.

---

# Final Design Goals

The final version of ACADIA should provide:

* Low operational cost.
* Offline-first learning experience.
* Real-time admin configuration.
* Modular and scalable architecture.
* Easy content management.
* Minimal Firebase dependency.
* No unnecessary APK updates.
* Fast application performance.
* Clean Architecture implementation.
* Future-proof content delivery.
* Easy maintenance for developers.
* Excellent user experience for students.

This architecture is optimized specifically for educational platforms and is designed to scale efficiently while keeping hosting and infrastructure costs extremely low.

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
