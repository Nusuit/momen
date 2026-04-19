# Tech Stack Recommendations for Momen

This document tracks the chosen scalable technologies to move the project from UI prototype stage to production-grade Flutter app.

Current policy: install selected platform packages when an integration point exists, but keep generated models and media packages until their feature slices need them.

## 1) Core Flutter dependencies

- flutter_riverpod
  - Why: aligns with project rule for scalable state management and DI.
  - Status: installed and used by the app shell.
  - Use: app providers now, feature controllers next.

- go_router
  - Why: typed route declarations and predictable navigation flow.
  - Status: installed and used in `lib/app/routing`.
  - Use: app shell routes for onboarding/auth/main/detail/edit profile.

- freezed_annotation + json_annotation
- build_runner + freezed + json_serializable
  - Why: immutable models, unions, safer mapping for data/domain.
  - Use: entity/model classes and state objects.

- dio
  - Why: robust HTTP client with interceptors and cancellation.
  - Status: not installed; Supabase SDK covers the first backend slice.
  - Use later only if custom REST endpoints are added.

- flutter_secure_storage
  - Why: secure token/session persistence.
  - Status: not installed; Supabase manages its initial auth storage.
  - Use later if custom secrets/tokens are needed.

- fpdart (or dartz)
  - Why: Either-based error flow required by convention.
  - Status: installed.
  - Use: repository interfaces and use cases.

- intl
  - Why: money/date formatting for dashboard and memories.

## 2) Image & media stack

- cached_network_image
  - Why: feed/memory pages are image-heavy and need caching placeholders.

- image_picker + camera
  - Why: camera capture and gallery import.

- path_provider
  - Why: local file handling for photos before upload.
  - Status: installed for Isar directory resolution.

## 3) Local persistence and offline

- isar
  - Why: local cache for feed/memories/dashboard summaries.
  - Status: selected and installed.

- connectivity_plus
  - Why: network-aware UX and retry policies.

## 4) Observability & quality

- logger
  - Why: structured logs in data/network layers.

- firebase_crashlytics
  - Why: production crash/error monitoring.
  - Status: selected and installed, guarded until Firebase config files exist.

- very_good_analysis or flutter_lints
  - Why: static analysis baseline.

## 5) Testing stack

- flutter_test
- mocktail
- golden_toolkit (optional for stable visual snapshots)

## 6) Suggested dependency rollout order

1. Done: fpdart + flutter_lints + mocktail for testable domain/data slices.
2. Done: Riverpod + GoRouter app shell.
3. Done: Supabase SDK, Isar, Firebase Crashlytics integration guards.
4. Next: camera/image picker + cached_network_image when building real photo capture and feed.
5. Next: freezed/json_serializable + build_runner when DTO volume justifies generation.
6. Later: connectivity_plus and logger when offline retry and data-layer logging exist.

## 7) Compatibility notes with current code

- Current source has Flutter Android, iOS, and web runners.
- Existing UI uses centralized constants and core components, which is compatible with Riverpod and testable architecture.
- Supabase and Crashlytics are runtime-guarded so tests and local development can run without cloud credentials.
