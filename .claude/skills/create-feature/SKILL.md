---
name: create-feature
description: |
  Automates the creation of a new, high-quality feature using a full-stack analysis (Frontend -> Backend -> Database). 
  Use this when the user wants to add a new functional module to the app. 
  It enforces the "Momen" Clean Architecture (Domain, Data, Presentation layers) 
  and mandates high-quality architectural decisions.
---

# Feature Creation Skill (Full-Stack & Rigorous)

This skill ensures that every new feature is built on a solid foundation, from the database schema up to the UI.

## 🧭 When to Use

- ✅ When a user asks for a new feature (e.g., "Add a profiling feature").
- ✅ When refactoring a large feature into sub-features.
- ✅ When you need to ensure architectural consistency across the stack.

## 🛠️ Work Process (High Rigor)

### 1. Requirements & Full-Stack Audit
Before writing any code, perform a trace through the stack:
- **Frontend**: Identify required screens, state parameters, and widgets.
- **Backend (API)**: Check `lib/core/network/api_client.dart` and `api_endpoints.dart`. Does the necessary endpoint exist?
- **Database (DB)**: Check the current schema (Supabase/Firebase/Local). Does the table/field exist?

### 2. Quality Gate 🚧
**CRITICAL RULE**: "No low-quality workarounds."
- If an API is missing the correct field, **DO NOT** mangle another field to fit it. 
- If the Database lacks a table/column for this feature, **STOP** and propose a schema change or a new table creation. 
- You must suggest a robust, high-quality solution even if it requires more work (e.g. creating a new migration).

### 3. Folder Generation
Create the directory structure inside `lib/features/<feature_name>/`:
- `domain/entities/`, `domain/repositories/`, `domain/usecases/`
- `data/models/`, `data/datasources/`, `data/repositories_impl/`
- `presentation/state/`, `presentation/pages/`, `presentation/widgets/`

### 4. Boilerplate Implementation
- **Entity**: Standard Dart object (independent of JSON).
- **Repository Interface**: Pure abstract class.
- **UseCase**: Single-responsibility class.
- **Model**: Extends Entity with `fromJson`/`toJson`.
- **DataSource**: Implementation of the network call.
- **Repo Impl**: Bridges Domain and Data.
- **Controller**: Riverpod/Bloc state management.

### 5. Tracking & Checklist 📝
**MANDATORY STEP**: After the feature is created, update the `Checklist.md` file in the root directory. 
- Add the new feature to the list.
- Mark it as `[ ]` (in progress) or `[x]` (if you generated the full boilerplate).

## 🧩 Example Prompt

**User**: "Add a feature for user badges."
**Agent (Claude)**: 
1. *Audit*: Checks if `badges` table exists in DB. 
2. *Decision*: Noticed DB only has `users` table. 
3. *Proposal*: "I will create the `Badges` table in the DB first with fields `id`, `name`, `icon_url`, `user_id`. Then I will build the feature."
4. *Action*: Creates the 3-layer structure in `lib/features/badges/`.

## 📐 Commits
After creating the feature, use: `git commit -m "feat: implement badges feature"`
