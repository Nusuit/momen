---
name: fix-backend
description: |
  Specialized troubleshooting for Feature Data and Domain layers (API, Repositories, Domain Logic, DB). 
  Handles serialization errors, API client issues, and **Database Migrations** (Hive/Isar/local storage).
---

# Feature Backend Maintenance (Data Flow & Logic)

@Agent_Instruction: You are troubleshooting the **Data** or **Domain** layers for a specific feature. Focus on the data lifecycle and business rules.

## 🧭 Troubleshooting Map

Consult the following for Data & Schema truth:
- **[PROJECT_RULE&CONVENTION.md](file:///c:/Kien/Mobile/Momen/PROJECT_RULE&CONVENTION.md)** (Section 5).
- **[lib/core/network/README.md](file:///c:/Kien/Mobile/Momen/lib/core/network/README.md)**: API Client truth.
- **[lib/features/README.md](file:///c:/Kien/Mobile/Momen/lib/features/README.md)**: Layer isolation truth.

## 🛠️ Debugging Logic

### 1. Data Integrity (`data/models/`, `domain/entities/`)
- Check `fromJson`/`toJson` for field name mismatches between the API and Model.
- Ensure the Entity remains a pure Dart object (no JSON or framework logic).

### 2. Logical Inconsistency (`domain/usecases/`, `data/repositories_impl/`)
- Trace the `Either<Failure, Success>` flow. Are all exceptions correctly caught and converted to Failures?
- Validate the business rules in pure Dart logic.

### 3. Database & Migrations 🏗️
**MANDATORY RULE**: If you are modifying a local storage schema (Hive/Isar):
- Increment the database version number.
- Implement the migration logic for existing data.
- **NEVER** overwrite the schema without handling data compatibility for existing users.

## ⚖️ Quality Rules
- **No UI Imports**: The Data and Domain layers must NOT import any widgets or presentation logic.
- **Pure Entities**: Entities must be 100% independent of any external framework (Flutter, Firebase, etc.).
- **Async Safety**: Always handle `Future` and `Stream` operations with proper timeouts and error catching.
