---
name: refactor
description: |
  Enforces code quality and Clean Architecture principles through "Refactoring" without changing logic. 
  Focuses on DRY (Don't Repeat Yourself), layered isolation, and architectural purity.
---

# Code Refactor Skill (Architectural Integrity & DRY)

@Agent_Instruction: You are performing a refactor. The goal is to improve the structure and maintainability of the code without altering its functional behavior.

## 🧭 Refactor Map

Consult the following for the "Source of Truth" for Architecture and Cleanliness:
- **[PROJECT_RULE&CONVENTION.md](file:///c:/Kien/Mobile/Momen/PROJECT_RULE&CONVENTION.md)**: Supreme Rules.
- **[lib/core/README.md](file:///c:/Kien/Mobile/Momen/lib/core/README.md)**: Core Layer Truth.
- **[lib/features/README.md](file:///c:/Kien/Mobile/Momen/lib/features/README.md)**: Feature Layer Truth.

## 🛠️ Refactoring Logic (High Rigor)

### 1. **DRY** Audit (Don't Repeat Yourself) 🧩
**CRITICAL RULE**: "Prioritize DRY over complex patterns for now."
- Search for duplicate UI logic (e.g. repeated buttons or inputs) and move them to **`lib/core/components/`**.
- Search for duplicate business logic (e.g. date formatting or currency parsing) and move them to **`lib/core/utils/`**.
- Extract repeated API logic to the shared **`Dio`** instance or interceptors.

### 2. Layer Isolation Audit 📂
- Verify that Feature A does NOT import from Feature B.
- Ensure the **Domain** layer (Entities/UseCases) remains 100% pure Dart (no Flutter, no JSON).
- Audit that the **Presentation** layer (UI) calls ONLY the **Controller/Provider**, never the Data Sources.

### 3. Dependency Injection Check 🏗️
- Ensure all Repositories and Services are injected via **Riverpod Providers**.
- Remove any manual instantiation (`final repo = AuthRepositoryImpl();`) and replace with `ref.watch(authRepositoryProvider)`.

## ⚖️ Quality Rules
- **No Logical Changes**: Refactoring MUST NOT change the app's behavior. 
- **Mandatory Testing**: Run the existing tests in `lib/features/*/test/` after the refactor to ensure no regressions.
- **Clean Commits**: Always use `git commit -m "refactor: [describe change]"` for these updates.
