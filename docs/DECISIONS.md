# Technical Decisions

This file tracks choices that should not be made casually during implementation.

## Accepted Decisions

### Backend / BaaS

Decision: Supabase.

Reason: good fit for auth, storage, realtime feed, relational friend/spending data, and MVP speed.

Implementation status:
- `supabase_flutter` is installed.
- `SupabaseService` initializes only when `SUPABASE_URL` and `SUPABASE_ANON_KEY` are provided via `--dart-define`.

### Local Persistence

Decision: Isar.

Reason: good fit for offline cache, draft posts, and object-style local feed/memory data.

Implementation status:
- `isar`, `isar_flutter_libs`, and `path_provider` are installed.
- `LocalDatabaseService` opens Isar when feature schemas exist.

### Observability

Decision: Firebase Crashlytics.

Reason: strong mobile crash reporting for Android and iOS.

Implementation status:
- `firebase_core` and `firebase_crashlytics` are installed.
- `CrashReportingService` is guarded behind `ENABLE_FIREBASE_CRASHLYTICS`.
- Firebase platform files still need to be generated with FlutterFire before enabling.

### Prototype Archive

Decision: remove `zip/`.

Reason: it was a design prototype and should not be treated as source of truth.

### Platform Scaffolding

Decision: generate Android, iOS, and web Flutter runners.

Implementation status:
- `android/`, `ios/`, and `web/` exist.

## Pending Decisions

### App Identifiers

Status: Pending human decision.

Current generated defaults use Flutter template identifiers. Before beta/release, choose final Android `applicationId` and iOS `bundle identifier`.

Examples:
- `com.momen.app`
- `vn.momen.app`

### Firebase Project

Status: Pending human action.

Run FlutterFire configuration after the Firebase project exists, then add the generated platform config files.

## Current Working Decisions

- App shell uses Riverpod and GoRouter.
- Coverage target is 80%, enforced by `scripts/coverage_gate.cmd`.
