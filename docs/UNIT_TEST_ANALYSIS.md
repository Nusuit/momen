# Unit Test Analysis and Plan

This plan targets current Flutter files in lib and prioritizes unit/widget tests with the highest regression risk.

## 1) Current testability snapshot

Current verification status:
- `scripts/check.cmd` passes end-to-end.
- `flutter analyze` reports no issues.
- `flutter test --coverage` passes.
- Coverage is 95.32% (367/385 lines), above the 80% target.

- Existing tests cover:
  - App shell startup and a basic onboarding/sign-in/camera-tab flow.
  - Main tab navigation through feed, dashboard, profile, and edit profile.
  - Sign-up, profile, and edit-profile presentation callbacks.
  - Onboarding progression callbacks.
  - Feed and camera presentation placeholders.
  - Memories chip callback.
  - Detail page null and non-null state rendering.
  - CustomTextField label/hint/obscure behavior.
  - Dashboard presentation.
  - Spending parser, datasource, use case, and repository mapping.

- Gaps:
  - Most app behavior is still static presentation UI.
  - No Riverpod controllers exist yet, so state-transition tests are not available.
  - Auth, feed, recap, camera, and dashboard do not have real domain/data implementations yet.

## 2) Coverage priority matrix

P0 (write now):
- Onboarding progression and callbacks.
- Memory selection callback from chip taps.
- Detail page null and non-null state rendering.
- CustomTextField configuration behavior.

P1 (after Riverpod controllers exist):
- Controller state transitions for auth/feed/spending/recap.
- Failure/success paths from use cases.

P2 (after repositories/data sources exist):
- Repository mapping from exceptions to Either failures.
- Datasource error translation and timeout behavior.

## 3) Proposed test structure

- test/core/components/...
- test/features/auth/presentation/...
- test/features/recap/presentation/...
- test/features/feed/presentation/...
- test/features/spending/presentation/...

## 4) Required assertions per layer

Presentation:
- widget presence, button taps, callback invocations, conditional rendering.

Domain (upcoming):
- use case input validation, pure business rules, failure mapping.

Data (upcoming):
- API response mapping, exception conversion, empty/error edge cases.

## 5) Execution strategy

1. Run `flutter pub get`.
2. Run `flutter analyze`.
3. Run `flutter test --coverage`.
4. Run `scripts/coverage_gate.cmd -MinCoverage 80`.
5. Add CI to run `scripts/check.cmd`.
6. Add golden tests for key pages after stable theming.

## 6) Definition of done for this phase

- `flutter test --coverage` completes without timeout.
- Coverage is 80% or higher.
- Test file organization matches feature-first architecture.
- No cross-feature imports introduced by tests.
