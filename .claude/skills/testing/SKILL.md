---
name: testing
description: |
  Generates high-quality tests for the Momen project. 
  Covers Unit Tests for Domain/Data logic and Widget Tests for the Presentation layer. 
  Mandates the use of mocks for dependencies and ensures 100% logic path coverage.
---

# Testing Skill (Logical & UI Coverage)

This skill ensures that your code is robust, reliable, and meets the quality standards of the project.

## 🧭 When to Use

- ✅ After creating a new UseCase or Repository Implementation.
- ✅ After building a new reusable UI component or Page.
- ✅ When refactoring logic to ensure no regressions.

## 🛠️ Work Process (High Rigor)

### 1. Identify the Test Target
Determine the type of test based on the file location:
- **`lib/features/*/domain/usecases/`** -> **Unit Test**.
- **`lib/features/*/data/repositories_impl/`** -> **Unit Test (with Mocks)**.
- **`lib/features/*/presentation/pages/`** -> **Widget/Integrations Test**.
- **`lib/core/utils/`** -> **Unit Test**.

### 2. Mock Dependencies 🎭
**RULE**: Never use real network/DB calls in tests. 
- Use a mocking library (e.g., `mocktail` or `mockito`).
- Mock the Repository in UseCase tests.
- Mock the DataSource in Repository tests.

### 3. Implement Test Cases
- **Success Case**: Everything works as expected.
- **Failure Case**: Test the `Left(Failure)` edge cases (e.g., `ServerFailure`, `ConnectionFailure`).
- **Input Validation**: Test invalid data handling.

### 4. Widget Pump (Presentation)
- Pump the widget using `tester.pumpWidget()`.
- Use `find.byType()` or `find.byKey()` to verify UI elements.
- Simulate user interaction with `tester.tap()`.

## 📐 Example Prompt

**User**: "Test the `LoginUseCase`."
**Agent (Claude)**: 
1. *Setup*: Drafts `login_usecase_test.dart`.
2. *Mocking*: Mocks `AuthRepository`.
3. *Test Case*: "Should return `UserEntity` when login succeeds."
4. *Test Case*: "Should return `AuthFailure` when password is wrong."

## 📜 Commits
`git commit -m "test: implement tests for login usecase"`
