📜 Project Rules & Conventions

@Agent_Instruction: This is the supreme rulebook of the project. EVERY PIECE OF CODE YOU GENERATE MUST COMPLY WITH THIS FILE.

1. Architecture

Use Feature-First Clean Architecture.

Features MUST NOT call each other's code directly.

If 2 Features need to communicate, it must be done through the lib/core/ directory or via Dependency Injection.

2. State Management

Use Riverpod (or Bloc depending on user setup) for state management.

Do not use setState for API calls or complex logic. Only use setState for internal UI animations within a Widget.

3. Import Rules

DO NOT use overly long relative paths like ../../../core/...

ALWAYS use Absolute paths for the core directory: import 'package:app_name/core/...'

4. UI & Design

All spacing values (padding, margin) must use variables from lib/core/constants/app_sizes.dart. DO NOT hardcode numbers (e.g., padding: EdgeInsets.all(16) is incorrect, you must use EdgeInsets.all(AppSizes.p16)).

All colors must be retrieved from Theme.of(context).colorScheme.

5. Error Handling

The Data layer will throw an Exception.

The Repository layer (implementation) will catch the Exception and return Either<Failure, Success> (using the dartz or fpdart package).

6. Tracking & Checklist

MANDATORY to update the Checklist.md file when starting or completing a new feature/task.

Only mark with a tick (- [x]) if that feature is completely finished and functioning correctly.

If the feature is in progress or not finished, it must be left unticked (- [ ]).

7. Dependency Injection (DI)

All Services, UseCases, and Repositories MUST be injected.
If using Riverpod, define global providers for dependencies in `lib/core/state/` or within the corresponding feature's `state/` directory.

8. Testing Strategy

- Domain & Data Layer: Business logic (UseCases), Repositories, and Utils MUST have Unit Tests.
- Presentation Layer: Controllers and complex state must have Unit Tests. Key reusable Widgets should have Component/Widget Tests.