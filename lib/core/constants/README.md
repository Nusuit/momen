# App Constants Directory (Style Guide)

@Agent_Instruction: This directory is the single source of truth for all global variables, themes, and configuration assets. Absolutely NO hardcoded values (colors, sizes, strings) should exist elsewhere in the app.

## 🧭 How to Reference Styles

To maintain design consistency, always use the following mapping:

### 1. Colors (`app_colors.dart`)
- **Primary Color**: Use `Theme.of(context).colorScheme.primary` (e.g., brand brand colors).
- **Secondary Color**: Use `Theme.of(context).colorScheme.secondary`.
- **Backgrounds**: Use `Theme.of(context).colorScheme.surface`.

### 2. Spacing and Sizes (`app_sizes.dart`)
- **Padding/Margin**: Never use `EdgeInsets.all(16)`. Instead, use `AppSizes.p16` (e.g., `EdgeInsets.all(AppSizes.p16)`).
- **Radius**: Use `AppSizes.r12` for corner rounding.
- **Iconography**: Use `AppSizes.i24` for standard icon sizes.

### 3. Typography (`app_text_theme.dart`)
- **Headings**: Use `Theme.of(context).textTheme.headlineMedium`.
- **Body Text**: Use `Theme.of(context).textTheme.bodyLarge`.
- **Labels**: Use `Theme.of(context).textTheme.labelSmall`.

### 4. Endpoints & Constants (`api_endpoints.dart`)
- **Base URL**: Use `ApiEndpoints.baseUrl`.
- **Feed Endpoint**: Use `ApiEndpoints.getFeed`.
- **Timeout**: Use `ApiEndpoints.connectionTimeout`.

## 🛠️ Design Philosophy

We aim for a high-quality "Gen Z" aesthetic:
- **Responsive Layouts**: Use `AppSizes` to ensure the UI looks great on any screen size.
- **Vibrant Colors**: Ensure accessibility and a modern, premium feel.
- **Dynamic Themes**: Support both Light and Dark modes via the `AppThemes` class.
