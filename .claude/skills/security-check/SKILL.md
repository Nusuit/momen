---
name: security-check
description: |
  Performs a full-stack security audit, scanning for hardcoded secrets, unsafe API calls, 
  and missing input validation at every layer (Frontend -> Backend -> Database).
---

# Security Check Skill (Rigorous Audit)

This skill ensures that your application is safe from common vulnerabilities and data leaks.

## 🧭 When to Use

- ✅ Before merging a feature branch.
- ✅ When exposing a new API endpoint.
- ✅ When handling sensitive user information (e.g., Auth, Financials).

## 🛠️ Work Process (High Rigor)

### 1. Secret Scan 🗝️
Scan the entire repository for:
- API Keys, Secret Tokens, or Hardcoded Credentials.
- Cleartext Sensitive Data (e.g., passwords in logs).
- **RULE**: Mandatory check for `lib/core/network/` configurations.

### 2. Full-Stack Data Validation 🛡️
Ensure data is validated at every layer:
- **Presentation**: Input filtering in TextFields.
- **Data**: Data type validation in Model `fromJson`.
- **Backend (Supabase/Firebase)**: Check for Row Level Security (RLS) rules and API permissions.

### 3. Error Handling Integrity ⚠️
Ensure that error messages don't leak server-side internals. 
- Use the `Left(Failure)` pattern from the Domain layer to translate technical errors into user-friendly messages.

## 📐 Example Prompt

**User**: "Check security for the `Spending` feature."
**Agent (Claude)**: 
1. *Setup*: Scans `spending_input_field.dart` for input validation. 
2. *Audit*: Noticed amount is entered as a string with no limit. 
3. *Recommendation*: "Add a length limit to the TextField and enforce a max value in the UseCase to prevent overflow attacks."

## 📜 Commits
`git commit -m "chore: implement security audit recommendations"`
