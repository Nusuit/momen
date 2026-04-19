# UI Components Directory (Design System)

@Agent_Instruction: Before you create a new Widget for a screen, **CHECK IF IT ALREADY EXISTS HERE**. We must reuse components to ensure a consistent, professional design throughout the application.

## 🧭 How to Find and Use Components

If you need a UI element (e.g., a button), navigate to the subfolder corresponding to the component's category:

### 1. Buttons (lib/core/components/buttons/)
- **Primary Button (`primary_button.dart`)**: The main call-to-action (brand color).
- **Secondary Button (`secondary_button.dart`)**: An outlined or less prominent button.
- **Social Login Button (`social_login_button.dart`)**: Pre-styled for Google/Apple authentication.

### 2. TextFields (lib/core/components/inputs/)
- **Custom TextField (`custom_text_field.dart`)**: The standard input field for forms.
- **Spending Input Field (`spending_input_field.dart`)**: Specialized for currency input and spending captions (contains logic for parsing the currency symbol).

### 3. Display Elements (lib/core/components/display/)
- **Anonymous Avatar (`anonymous_avatar.dart`)**: Used in the "Overthinking" Feed to blur/hide user identities.
- **Custom Network Image (`custom_network_image.dart`)**: A robust image loader featuring shimmer effects and caching (CRITICAL for a Locket-style photo app).

## 🛠️ Naming Conventions for New Components

- **Filename**: `snake_case.dart` (e.g., `primary_button.dart`)
- **Class Name**: `PascalCase` matching the file name (e.g., `PrimaryButton`)
- **Location**: Use subfolders (`buttons/`, `inputs/`, `display/`, `layout/`) to keep this directory organized.

## 📐 Spacing & Colors

@Agent_Rule: NEVER use hardcoded numbers or hex codes within these components. Always use:
- **Spacing**: `AppSizes.p16`, `AppSizes.p8`, etc., from `lib/core/constants/app_sizes.dart`.
- **Colors**: `Theme.of(context).colorScheme.primary`, etc., from the global app theme.
