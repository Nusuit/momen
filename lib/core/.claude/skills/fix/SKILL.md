---
name: fix-core
description: |
  Specialized troubleshooting for global core components (Network, Utilities, Constants). 
  Use this for bugs in API clients, shared formatting, or system-wide configurations.
---

# Core Maintenance Skill (Technical Substrate)

@Agent_Instruction: You are operating in the `lib/core/` substrate. This code affects the entire project. DO NOT introduce feature-specific logic here.

## 🧭 Troubleshooting Map

Consult the following documents before applying a fix:
- **[lib/core/README.md](file:///c:/Kien/Mobile/Momen/lib/core/README.md)**: Architectural roadmap.
- **[lib/core/constants/README.md](file:///c:/Kien/Mobile/Momen/lib/core/constants/README.md)**: Style & Endpoint truth.
- **[lib/core/network/README.md](file:///c:/Kien/Mobile/Momen/lib/core/network/)**: API logic truth.

## 🛠️ Debugging Logic

### 1. Network Issues (`lib/core/network/`)
- Verify the `Dio` interceptor logic for missing headers or tokens.
- Check if the environment URL is correctly pulled from `ApiEndpoints`.

### 2. Utility Errors (`lib/core/utils/`)
- Audit `RegexUtils` or `CurrencyFormatter` for incorrect edge-case handling (e.g. null inputs).

### 3. Shared Constants (`lib/core/constants/`)
- Ensure all color and size fixes comply with the `Theme` and `AppSizes` definitions.

## ⚖️ Quality Rules
- **No Side Effects**: Ensure a fix in core doesn't break dependent features. 
- **Absolute Imports**: Always use `import 'package:momen/core/...'`.
