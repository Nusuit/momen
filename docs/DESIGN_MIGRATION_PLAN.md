# Design Migration Plan (zip -> lib)

## 1) What was migrated

Source design:
- zip/src/App.tsx
- zip/src/components/*.tsx

Target Flutter source:
- lib/app.dart
- lib/main.dart
- lib/core/constants/app_sizes.dart
- lib/core/constants/app_theme.dart
- lib/core/components/buttons/primary_button.dart
- lib/core/components/inputs/custom_text_field.dart
- lib/core/models/memory_item.dart
- lib/features/auth/presentation/pages/*
- lib/features/feed/presentation/pages/*
- lib/features/recap/presentation/pages/*
- lib/features/spending/presentation/pages/*

## 2) Component mapping

- Onboarding.tsx -> features/auth/presentation/pages/onboarding_page.dart
- SignIn.tsx -> features/auth/presentation/pages/sign_in_page.dart
- SignUp.tsx -> features/auth/presentation/pages/sign_up_page.dart
- Profile.tsx -> features/auth/presentation/pages/profile_page.dart
- EditProfile.tsx -> features/auth/presentation/pages/edit_profile_page.dart
- MainLayout.tsx -> app.dart (app shell + tabs + camera FAB)
- Memories.tsx -> features/recap/presentation/pages/memories_page.dart
- Feed placeholder in App.tsx -> features/feed/presentation/pages/feed_page.dart
- Camera.tsx -> features/feed/presentation/pages/camera_page.dart
- Dashboard.tsx -> features/spending/presentation/pages/dashboard_page.dart
- DetailView.tsx -> features/feed/presentation/pages/detail_page.dart

## 3) Compatibility strategy

- Design token compatibility:
  - React CSS variables were moved into ThemeData and ColorScheme.
  - Spacing/radius/icon values were centralized in AppSizes.
- Interaction compatibility:
  - App flow was preserved: onboarding -> sign in/up -> main tabs -> detail/edit profile.
- Architecture compatibility:
  - Shared model MemoryItem was moved to core/models to avoid cross-feature imports.

## 4) Scalability strategy

- Keep Presentation/Data/Domain split per feature.
- Move current static screen data into feature state providers (Riverpod) before API integration.
- Add domain entities and repository contracts first, then data sources.
- Keep UI dependencies one-way: feature -> core.
- Add test layers in order:
  1. Domain use case tests
  2. Repository implementation tests (mock data source)
  3. Widget tests for critical reusable UI

## 5) Next migration checkpoints

- Add core/routing/app_router.dart with GoRouter route names for all screens.
- Replace local state flow in app.dart with Riverpod state notifiers.
- Add data/domain skeleton for each migrated presentation page.
- Add network image component with caching policy for feed/memory heavy screens.
