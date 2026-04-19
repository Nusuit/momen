---
name: fix-frontend
description: |
  Specialized troubleshooting for Feature Presentation layers (UI, Widgets, State). 
  Focuses on pixel-perfect layouts, widget lifecycle bugs, and state management errors.
---

# Feature Frontend Maintenance (UI & Layer Logic)

@Agent_Instruction: You are troubleshooting the **Presentation Layer** for a specific feature. Focus on the user-facing interface and its immediate state.

## 🧭 Troubleshooting Map

Consult the following for UI & Placement truth:
- **[PROJECT_RULE&CONVENTION.md](file:///c:/Kien/Mobile/Momen/PROJECT_RULE&CONVENTION.md)** (Section 4 & 7).
- **[lib/core/components/README.md](file:///c:/Kien/Mobile/Momen/lib/core/components/README.md)**: Ensure component reuse.
- **[lib/core/constants/README.md](file:///c:/Kien/Mobile/Momen/lib/core/constants/README.md)**: Style & Padding truth.

## 🛠️ Debugging Logic

### 1. Widget Layout (`presentation/pages/`, `presentation/widgets/`)
- Check if `AppSizes` or `EdgeInsets.all(AppSizes.pXX)` are used.
- Verify that `Theme.of(context).colorScheme` is the source of all colors.

### 2. State Management (`presentation/state/`)
- **Lifecycle Audit**: Are you using `ref.watch` inside a build method and `ref.read` inside a callback?
- **Sync Issues**: Verify that the UI correctly reacts to state changes (Loading, Success, Failure).

## ⚖️ Quality Rules
- **No Direct Layer Calls**: The UI must call the **Controller/Provider**, never the Repository or UseCase directly.
- **Pixel-Perfect Alignment**: Maintain the "Locket" aesthetic - full screen, high-quality photos, minimal clutter.
- **Error States**: Ensure every page has a user-friendly way to show errors via the `Left(Failure)` mapping.
