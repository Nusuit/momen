---
name: workflow-checking
description: |
  Automated architectural guardrail that validates if the current code follows the project's 
  strict conventions (Core vs Features independence, Dependency DI, Layer separation).
---

# Workflow Checking Skill (Architectural Guardrail)

This skill ensures your project stays clean, modular, and easy to maintain by enforcing strict architectural rules.

## 🧭 When to Use

- ✅ Before a Pull Request (PR).
- ✅ When receiving a "Dependency Loop" or "Core Error".
- ✅ To verify if a new feature is correctly isolated.

## 🛠️ Work Process (High Rigor)

### 1. Independence Audit 🛡️
**RULE**: "Features MUST NOT call each other directly."
- Scan all `import` statements in `lib/features/`.
- **Constraint**: A feature folder (e.g. `auth`) cannot import from another feature folder (e.g. `feed`). 
- **Solution**: If communication is needed, it must go through `lib/core/` (interfaces/DTOs).

### 2. Core Integrity Scan 🏗️
**RULE**: "Core layer MUST NOT import from the Features layer."
- Scan all `import` statements in `lib/core/`.
- **Constraint**: Files in `lib/core/` cannot reference `lib/features/`.

### 3. Layer Separation Audit 📂
Verify each feature has exactly 3 layers (Domain, Data, Presentation):
- **Domain**: Pure Dart (no Flutter imports).
- **Data**: No UI imports.
- **Presentation**: UI and State only.

## 📐 Example Prompt

**User**: "Check the `Auth` feature's architecture."
**Agent (Claude)**: 
1. *Setup*: Scans `auth/domain/entities/user_entity.dart`. 
2. *Audit*: Noticed it imports `package:flutter/material.dart` for a `Color`. 
3. *Recommendation*: "Move the `Color` definition to a hex string in the entity or use a separate UI model. Use the `lib/core/constants/app_colors.dart` reference instead."

## 📜 Commits
`git commit -m "chore: fixed architectural violations in auth feature"`
