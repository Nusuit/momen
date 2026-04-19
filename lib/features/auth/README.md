# Auth Feature Guide (Authentication)

@Agent_Instruction: This feature manages user registration, login, and identity management. It handles communication with the Identity Provider (Firebase/Supabase).

## 🧭 Directory Map & Navigation

To modify or use Authentication, follow this structure:

### 1. **Domain Layer** (`lib/features/auth/domain/`)
- **`entities/user_entity.dart`**: Defines the `UserEntity` (ID, name, email, avatar).
- **`repositories/auth_repository.dart`**: Interface for `login()`, `register()`, `logout()`.
- **`usecases/login_usecase.dart`**: Business logic for the login flow.

### 2. **Data Layer** (`lib/features/auth/data/`)
- **`models/user_model.dart`**: Maps the user's data from JSON (API) to the `UserEntity`.
- **`datasources/auth_remote_datasource.dart`**: Actual REST/GraphQL calls to the backend.
- **`repositories_impl/auth_repository_impl.dart`**: Bridges the Domain and Data layers.

### 3. **Presentation Layer** (`lib/features/auth/presentation/`)
- **`state/auth_controller.dart`**: Using Riverpod (`StateNotifierProvider`) to maintain login status.
- **`pages/login_page.dart`**: The main login screen.
- **`widgets/social_login_buttons.dart`**: Feature-specific login UI components.

## 🧭 Routes (lib/core/routing/app_router.dart)

The following routes are defined for this feature:
- `/login`: The entry point for unauthenticated users.
- `/register`: User sign-up page.
- `/forgot-password`: Password recovery page.

## ⚖️ Authentication Rules

- **Persistence**: Store the authentication token securely using `FlutterSecureStorage` (managed in `lib/core/network/`).
- **Initial State**: Check for an existing session in `main.dart` before redirecting to the `/login` or `/home` route.
- **Error Handling**: Catch specific exceptions (e.g., `IncorrectPasswordException`, `UserNotFoundException`) and map them to friendly UI messages.
