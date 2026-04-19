---
name: deploy
description: |
  Provides a comprehensive checklist and automated command guidance for building and 
  deploying the Flutter application (iOS/Android) and its backend services.
---

# Deploy Skill (Reliable Builds)

This skill ensures that your code is correctly packaged and deployed into the production environment.

## 🧭 When to Use

- ✅ When a feature is ready for the Minimum Viable Product (MVP).
- ✅ When pushing new changes to the app store (or Firebase App Distribution).
- ✅ When updating the backend database schema.

## 🛠️ Work Process (High Rigor)

### 1. Build Verification 🏗️
Run the build command locally before deploying:
- `flutter build apk --release` (Android)
- `flutter build ios --release` (iOS)
- **RULE**: Mandatory check for `pubspec.yaml` versioning and dependencies.

### 2. Environment Audit 🌍
Check the following:
- **API Endpoints**: Ensure `lib/core/constants/api_endpoints.dart` is set to the production URL.
- **Keys**: Ensure all environment variables/secrets are correctly loaded.
- **Database**: Ensure the production DB schema matches the staging/dev environment.

### 3. Deploy Checklist 📋
- [ ] Run all tests (`flutter test`).
- [ ] Update `Checklist.md`.
- [ ] Push changes to main.
- [ ] Trigger CI/CD (GitHub Actions/Fastlane).

## 📐 Example Prompt

**User**: "Deploy the version 1.0.1 for Android."
**Agent (Claude)**: 
1. *Setup*: Runs `flutter clean` then `flutter build apk`. 
2. *Audit*: Noticed the version in `pubspec.yaml` is 1.0.0. 
3. *Recommendation*: "I noticed your version is 1.0.0. I will update it to 1.0.1 before proceeding."
4. *Action*: Updates `pubspec.yaml` and starts the build.

## 📜 Commits
`git commit -m "chore: release version 1.0.1"`
