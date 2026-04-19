# Momen

Momen is a Flutter prototype for a Gen Z social photo-sharing app with anonymous feed interactions, spending parsing from captions, and recap memories.

## Current Status

The Flutter source is in an MVP foundation phase. The app has presentation skeletons, shared UI components, a spending parser slice, GoRouter navigation, Riverpod app composition, Supabase startup guards, an Isar database service, Firebase Crashlytics startup guards, and a passing coverage gate.

## Requirements

- Flutter SDK 3.38.x or compatible
- Dart SDK from the Flutter installation

## Useful Commands

```powershell
flutter pub get
flutter analyze
flutter test --coverage
.\scripts\coverage_gate.cmd -MinCoverage 80
.\scripts\check.cmd
```

## Architecture

- Feature-first Clean Architecture under `lib/features`.
- App composition, startup, routing, and shell UI under `lib/app`.
- Shared UI, constants, failures, persistence, SDK services, providers, and utilities under `lib/core`.
- Domain and parser logic should stay testable with pure Dart where possible.
- More detail: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Project documents are centralized under [docs/](docs/).

## Runtime Configuration

Supabase is initialized only when these values are passed:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Or place both keys in a local `.env` file and run:

```powershell
flutter run --dart-define-from-file=.env
```

Crashlytics is disabled by default until Firebase platform config files are added. After running FlutterFire configuration, enable it with:

```powershell
flutter run --dart-define=ENABLE_FIREBASE_CRASHLYTICS=true
```

## Supabase Manual Setup

Run these SQL files in Supabase SQL Editor, in order:

1. `sql/supabase_init.sql`
2. `sql/supabase_friendship_permissions.sql`
3. `sql/supabase_memories_friend_policy.sql`

Storage bucket `post_images` is created as public by `sql/supabase_init.sql`. If it already exists, the script keeps it in sync.

For manual verification after SQL runs:

1. Confirm tables exist: `profiles`, `friendships`, `posts`.
2. Confirm `profiles` has columns: `id`, `full_name`, `date_of_birth`, `created_at`, `updated_at`.
3. Confirm RLS is enabled for `profiles`, `friendships`, `posts`.
4. Confirm storage policies for `post_images` are created.

## Quality Bar

- Analyzer must pass with no errors.
- Unit/widget coverage target: 80% or higher.
- New feature work should include tests for success, empty, and failure states.
- Docs should describe implemented behavior or clearly label future decisions.
