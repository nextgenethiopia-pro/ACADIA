# ACADIA V1.0.0 — Full Clean Architecture Refactor Plan

## Current State Summary
- **143 Dart files**, ~40k+ lines
- Repository layer (domain interfaces + data implementations) **already exists** but is **unused** — ALL 50+ screens directly instantiate `FirebaseService()`, `OfflineDatabase.instance`, `PackageService()`, `DownloadManager()`
- `AuthBloc` directly creates `FirebaseAuthService()` instead of using `AuthRepository`
- 5 obsolete admin screens need deletion
- 413 uses of deprecated `.withOpacity()` across codebase
- Significant data duplication across constants files (subject colors defined in 3 places, subject icons in 2, universities in 2, payments in 3)

---

## Phase 1: Delete Obsolete Screens & Fix Routes

**Delete these 5 files:**
1. `lib/src/screens/admin/content_upload_screen.dart` (1185 lines)
2. `lib/src/screens/admin/image_management_screen.dart` (546 lines)
3. `lib/src/screens/admin/report_management_screen.dart` (265 lines)
4. `lib/src/screens/admin/support_tickets_screen.dart` (447 lines)
5. `lib/src/screens/admin/content_review_screen.dart` (343 lines)

**Fix `app_router.dart`:**
- Remove the 5 corresponding imports and `GoRoute` entries
- Remove `content-upload` and `image-management` routes (the other 3 may not have routes, verify)
- Update admin screen count comment from 11 to 6

---

## Phase 2: Expand DI Registration

**Update `injection.dart`** to register currently unregistered services:
- `OfflineDatabase` (singleton)
- `DownloadManager` (singleton)
- `NotificationService` (singleton)
- `ProfileStorageService` (singleton)
- `ImgbbService` (singleton)
- `ContentConfigService` (singleton)
- `ProgressTrackingService` (singleton)
- `CrashlyticsService` (singleton)

**Add 2 new repository interfaces + implementations:**
- `DownloadRepository` → wraps `DownloadManager` + `OfflineDatabase`
- `ProfileRepository` → wraps `ProfileStorageService` + `UserRepository`

---

## Phase 3: Migrate AuthBloc to Use Repository

**Update `auth_bloc.dart`:**
- Accept `AuthRepository` via constructor parameter instead of directly creating `FirebaseAuthService`
- Update all `_authService.signIn()` calls to use `Result<T>` return pattern from the repository
- Update `app.dart` to inject `getIt<AuthRepository>()` into `AuthBloc`

**Note:** The `AuthRepository` already returns `Result<User>` but `AuthBloc` currently uses raw `Map` responses from `FirebaseAuthService`. This requires updating the bloc's event handlers to unwrap `Result` types.

---

## Phase 4: Migrate ALL Screens to Use Repositories

**Migration pattern for each screen:**

| Before (current) | After (target) |
|---|---|
| `import '...services/firebase_service.dart'` | `import '...domain/repositories/content_repository.dart'` + `import '...core/di/injection.dart'` |
| `final FirebaseService _firebase = FirebaseService()` | `final _contentRepo = getIt<ContentRepository>()` |
| `OfflineDatabase.instance` | `getIt<OfflineDatabase>()` (or via DownloadRepository) |
| `PackageService()` | `getIt<PackageRepository>()` |
| `DownloadManager()` | `getIt<DownloadRepository>()` |

**Screens to migrate (48 screens, grouped by service usage):**

**FirebaseService users (32 screens) → ContentRepository/UserRepository/PaymentRepository/NotificationRepository:**
- All 6 admin screens (admin_dashboard, analytics, app_settings, content_management, entrance_management, notification_creation, payment_approval, user_management, about_management)
- Dashboard: home_tab, dashboard_screen, entrance_tab, notifications_tab, profile_tab, progress_tab, subjects_tab
- Content: chapter_content_screen
- Entrance: entrance_exam_screen, entrance_past_papers_screen, entrance_schedule_screen, entrance_subject_screen, entrance_tips_screen
- Settings: about_screen, app_settings_screen, privacy_policy_screen, terms_of_service_screen
- Onboarding: splash_screen, welcome_screen
- Payment: payment_screen, payment_history_screen
- Subject: subject_portal_screen

**OfflineDatabase users (8 screens) → DownloadRepository:**
- chapter_content_screen, exam_screen, flashcard_screen, pdf_viewer_screen, quiz_screen, video_player_screen
- dashboard/progress_tab, dashboard/subjects_tab
- settings/app_settings_screen

**PackageService users (2 screens) → PackageRepository:**
- subjects_tab, subject_portal_screen

**ImgbbService users (1 screen) → ProfileRepository:**
- payment_screen (uses `ImgbbService.uploadImage()`)

---

## Phase 5: Fix Duplicated Constants

**Consolidate into single sources of truth:**

1. **Subject colors**: Remove duplicates from `AppConstants.subjectColors` and `AppIcons.subjectColors` → all reference `AppColors.subjectColors`
2. **Subject icon assets**: Remove from `SubjectIcons` class → all use `AppIcons.subjectIconAssets`
3. **University lists**: Remove from `AppConstants` → all use `Universities` class
4. **Payment data**: Remove from `AppConstants.paymentMethods` and `AppConstants.paymentAccounts` → all use `PaymentMethods` class
5. **Subject lists**: Remove flat lists from `AppConstants` → all use `AcademicStructure.getSubjects()`

---

## Phase 6: Performance Fixes

1. **Replace `.withOpacity(x)` → `.withValues(alpha: x)`** across all ~413 occurrences project-wide
2. **Add `const` constructors** to all `StatelessWidget` subclasses in screens where possible
3. **Wrap heavy list items in `RepaintBoundary`** in admin content/user/payment cards
4. **Ensure `TextEditingController` disposal** in all screens that use text fields
5. **Hoist static maps/lists** (e.g., `_subjectsByPath` in home_tab) to top-level `const` or use existing `AcademicStructure` helpers

---

## Phase 7: Move Files to Feature-First Folder Structure

**Move screens from `lib/src/screens/` to `lib/src/features/`:**

```
features/auth/screens/       (5 files)
features/onboarding/screens/ (12 files)
features/dashboard/screens/  (1 main + 6 tab files)
features/content/screens/     (8 files)
features/entrance/screens/    (5 files)
features/payment/screens/    (2 files)
features/admin/screens/      (6 files, after deletion)
features/settings/screens/   (9 files)
features/subject/screens/     (1 file)
```

**Move widgets:**
```
shared/widgets/gradient_button.dart
shared/widgets/subject_icon_widget.dart
```

**Update ALL imports** across the entire codebase (~143 files) to reflect new paths.

---

## Phase 8: Update Router & Verify Build

1. Update `app_router.dart` imports to new feature-based paths
2. Update `main.dart` if needed
3. Run `flutter pub get`
4. Run `flutter analyze` — fix any new errors
5. Run `flutter build apk --debug` — verify it succeeds

---

## Execution Order
The phases must execute in sequence (1→8) because each depends on the previous. I'll work through them methodically, committing after each phase for safety.

## Risk Mitigation
- Each phase is independently verifiable
- Import updates will be done systematically with find/replace
- No business logic changes — only wiring/import/refactor changes
- `flutter analyze` after each major phase to catch regressions early