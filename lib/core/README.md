# Core Layer Guide

@Agent_Instruction: This directory contains "Global" code. If a function, model, or widget is only used for a specific screen, ABSOLUTELY DO NOT place it here. This layer is the bedrock of the application and must remain independent of any features.

## 🏗️ Directory Roadmap

To locate or build a shared resource, navigate based on its purpose:

- **[components/](file:///c:/Kien/Mobile/Momen/lib/core/components/README.md)**: 
  -> **Purpose**: UI pieces used by multiple features.
  -> **Usage**: Before building any custom widget, check this folder to see if it already exists (e.g., standard buttons, text inputs).
  -> **Selection**: Look for a filename that matches the widget type (e.g., `primary_button.dart`).

- **[constants/](file:///c:/Kien/Mobile/Momen/lib/core/constants/)**: 
  -> **Purpose**: The "Source of Truth" for styles and configuration.
  -> **Contents**: `app_colors.dart`, `app_sizes.dart`, `app_themes.dart`, `api_endpoints.dart`.
  -> **Instruction**: Never use hardcoded strings (e.g., "http://api.com") or hex codes (e.g., #FFFFFF). Always reference a constant from here.

- **[errors/](file:///c:/Kien/Mobile/Momen/lib/core/errors/)**: 
  -> **Purpose**: Standardizes error handling.
  -> **Usage**: Define your `Failure` (Domain) and `Exception` (Data) objects here to ensure consistency in the `Either<Failure, Success>` pattern.

- **[config/](file:///c:/Kien/Mobile/Momen/lib/core/config/)**:
  -> **Purpose**: Reads compile-time configuration from `--dart-define`.
  -> **Usage**: Keep SDK keys and feature toggles centralized here.

- **[observability/](file:///c:/Kien/Mobile/Momen/lib/core/observability/)**:
  -> **Purpose**: Crash reporting and production diagnostics setup.

- **[persistence/](file:///c:/Kien/Mobile/Momen/lib/core/persistence/)**:
  -> **Purpose**: Local storage infrastructure. Isar lives here.

- **[providers/](file:///c:/Kien/Mobile/Momen/lib/core/providers/)**:
  -> **Purpose**: Shared Riverpod providers for app-wide services.

- **[services/](file:///c:/Kien/Mobile/Momen/lib/core/services/)**:
  -> **Purpose**: SDK integration wrappers such as Supabase startup.

- **[utils/](file:///c:/Kien/Mobile/Momen/lib/core/utils/)**: 
  -> **Purpose**: Logic helpers.
  -> **Usage**: Formatting currency, parsing spending strings via Regex, or date manipulation.

## ⚖️ Rules of the Core Directory

1. **NO FEATURE IMPORTS**: The Core layer is NOT allowed to import any files from the `lib/features/` directory. Doing so creates circular dependencies and breaks Clean Architecture.
2. **DEPENDENCY FLOW**: Architecture arrows must only point from **Features -> Core**.
3. **INDEPENDENCE**: Every file here should be able to exist even if all features were deleted.

## App Composition Boundary

Navigation lives in `lib/app/routing/`, not in `core`, because routing composes feature pages. The `app` layer may import features; `core` must not.
