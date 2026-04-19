# Features Layer Guide (Feature-First Architecture)

@Agent_Instruction: Each folder inside `lib/features/` must represent an independent, modular feature. A feature should be completely self-contained except for its dependencies on the **Core** layer.

## 🏗️ Feature Standardization (MVVM-inspired Clean Architecture)

Every feature MUST be strictly divided into three distinct layers: **Domain**, **Data**, and **Presentation**. This ensures a clear separation of concerns.

### 1. **Domain Layer** (The Core of the Feature)
- **Entities**: Business logic objects (e.g., `user_entity.dart`).
- **Repositories**: Abstract interfaces defined as abstract classes (e.g., `auth_repository.dart`).
- **Use Cases**: Individual business actions (e.g., `login_usecase.dart`).
- **@Agent_Rule**: NO framework imports (e.g., `import 'package:flutter/...'`) allowed here. This layer should be pure Dart.

### 2. **Data Layer** (The Implementation Detail)
- **Models**: Data transfer objects with serialization/deserialization logic (e.g., `user_model.dart`).
- **DataSources**: Actual API calls or database interaction (e.g., `auth_remote_datasource.dart`).
- **Repositories Impl**: Concrete implementation of the Domain's abstract Repository.
- **@Agent_Rule**: All model objects should extend their corresponding Entity from the Domain layer.

### 3. **Presentation Layer** (The UI & State Management)
- **State**: Riverpod Providers or Bloc Cubits/Controllers (e.g., `auth_controller.dart`).
- **Pages**: Main screens of the feature (e.g., `login_page.dart`).
- **Widgets**: Reusable UI elements specific only to this feature (e.g., `login_footer_widget.dart`).

## 🧭 Data Flow Reference

1. **The Page** triggers an action by calling a method on the **Controller/Provider**.
2. **The Controller** calls a **UseCase** (Domain layer).
3. **The UseCase** calls a **Repository Interface** (Domain layer).
4. **The Repository Implementation** (Data layer) calls any number of **DataSources** (Remote/Local).
5. **The Repository Impl** maps the resulting **Model** (Data layer) into an **Entity** (Domain layer).
6. **The Result** is returned to the **Controller** using the `Either<Failure, Entity>` pattern for error handling.
7. **The UI** listens to the Controller's state and updates the screen accordingly.

## ⚖️ Rules for Feature Communication

1. **NO DIRECT FEATURE IMPORTS**: Feature A must NOT import a file from Feature B.
2. **SHARED DATA**: If two features need the same data, that data should be placed in `lib/core/models/` or communicated via global state in `lib/core/state/`.
3. **NAVIGATION**: Feature pages should receive callbacks from the app/routing layer. App-level routes live in `lib/app/routing/`.
