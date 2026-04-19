# Features Status And Test Coverage

Last updated: 2026-04-17

This file tracks which features are implemented and whether they have automated tests.

## Legend

- Implemented: Feature is available in app flow.
- Partial: Some parts are implemented; missing sub-flows remain.
- Planned: Not implemented yet.
- Unit: Domain/data logic tests.
- Widget: UI interaction/render tests.

## Feature Matrix

| Feature | Status | Test Coverage | Test Files | Notes |
| --- | --- | --- | --- | --- |
| App shell navigation (Capture -> Social -> Memories -> Profile) | Implemented | Widget | test/app_shell_flow_test.dart | Main tab flow covered |
| Camera capture flow (take photo) | Implemented | Partial Widget | test/app_shell_flow_test.dart | End-to-end camera plugin behavior is not mocked in depth |
| Post preview + manual submit only | Implemented | Partial Widget | test/app_shell_flow_test.dart | Manual submit behavior covered by shell flow; no dedicated camera unit tests |
| Post upload retry/progress and Supabase insert | Implemented | Not yet | - | Covered functionally in app, no dedicated datasource unit test yet |
| Gallery image pick for posting | Implemented | Not yet | - | Implemented via image_picker; no widget test yet |
| Memories list (friends-only anonymous feed) | Implemented | Widget | test/features/recap/presentation/memories_page_test.dart | Feed does not expose poster identity |
| Memories owner dropdown (history filter) | Implemented | Partial Widget | test/features/recap/presentation/memories_page_test.dart | Allows filtering timeline by specific friend profile history |
| Spending parser (extract VND from caption) | Implemented | Unit | test/core/utils/spending_parser_test.dart, test/features/spending/domain/usecases/parse_spending_from_caption_usecase_test.dart | Core parsing paths covered |
| Spending repository/local datasource | Implemented | Unit | test/features/spending/data/datasources/spending_local_datasource_test.dart, test/features/spending/data/repositories_impl/spending_repository_impl_test.dart | Data layer covered |
| Spending dashboard | Implemented | Widget | test/features/spending/presentation/dashboard_page_test.dart | Basic render/empty state covered |
| Feed pages and detail page | Implemented | Widget | test/features/feed/presentation/feed_pages_test.dart, test/features/feed/presentation/detail_page_test.dart | Core UI render/navigation checks |
| Auth basic pages (sign up, forgot/reset, otp, profile, edit profile) | Implemented | Widget | test/features/auth/presentation/auth_pages_test.dart | Main forms and interactions covered |
| Public friend profile page | Implemented | Widget | test/features/auth/presentation/public_profile_page_test.dart | Friend/pending button states covered |
| Friend search and send request | Implemented | Partial Unit+Widget | test/features/auth/domain/usecases/friendship_usecases_test.dart, test/features/auth/presentation/auth_pages_test.dart | Send request usecase covered; datasource logic lacks direct unit tests |
| Incoming friend requests (accept/reject) | Implemented | Unit + Partial Widget | test/features/auth/domain/usecases/friendship_usecases_test.dart, test/features/auth/presentation/public_profile_page_test.dart | Usecase/UI state covered |
| Unfriend / cancel request | Implemented | Unit + Partial Widget | test/features/auth/domain/usecases/friendship_usecases_test.dart, test/features/auth/presentation/public_profile_page_test.dart | Usecase/UI state covered |
| Copy profile deep-link and open public profile | Implemented | Partial Widget | test/features/auth/presentation/public_profile_page_test.dart | Profile page copy action has no direct widget assertion yet |
| DB permission hardening (friends-only posts) | Implemented | SQL policy validated manually | sql/supabase_friendship_permissions.sql | Enforced in Supabase RLS policies |
| Anonymous feed UI | Planned | - | - | Checklist item still open |
| Weekly spending leaderboard | Planned | - | - | Checklist item still open |
| Collaborative recap rooms | Planned | - | - | Checklist item still open |

## Security-Critical Rule Snapshot

- Post visibility policy is self immediately, accepted friends after 3 days.
- Posting identity is always anonymous at display layer (per-post alias, no profile reveal from post cards).
- Friendship state changes are permissioned by role:
  - Addressee accepts/rejects pending request.
  - Requester can cancel pending request.
  - Both participants can unfriend accepted relationship.
- Reference SQL: sql/supabase_friendship_permissions.sql

## Recommended Next Features (Locket-like, privacy-first)

1. Anonymous Identity Layer 2.0 (High priority)
- Keep auto-anonymous as mandatory default (already applied) and add stable anonymous aliases per day.
- Friend can view content but cannot map alias to profile.
- Add tests for alias generation determinism and anti-correlation rules.

2. Privacy Tiers Without Identity Reveal (High priority)
- Modes: Friends-only anonymous (default), Private (self only).
- No visible identity reveal toggle on post UI.
- Enforce via post-level visibility field + RLS policies.

3. Friend Feed Rate Limits / Safety (High priority)
- Throttle posting and friend requests to reduce spam.
- Add abuse controls (cooldown, request cap/day).
- Add unit tests for guard logic.

4. Friendship Inbox Page (Medium priority)
- Dedicated page for pending requests and history (accepted/rejected/cancelled).
- Add widget tests for request lifecycle transitions.

5. Share Link Hardening (Medium priority)
- Move from plain uid link to signed, expiring invite token.
- Add backend validation and replay protection.
- Add tests for token expiry and invalid signature paths.

6. Private Reactions And Seen State (Medium priority)
- Add friend-only reactions and seen receipts with strict RLS.
- Keep anonymous mode by masking reactor identity when required.
- Add unit tests for permission checks and aggregation.

## Suggested Testing Backlog

- Add datasource unit tests for friend_search_remote_datasource.dart
- Add widget tests for profile copy-link action and search-result tap -> public profile navigation
- Add tests for memories dropdown selection switching owner data
- Add tests for feed post datasource retry/cleanup behavior
