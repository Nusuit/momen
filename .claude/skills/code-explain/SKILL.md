---
name: code-explain
description: |
  Provides deep technical explanations for complex logic and data flows using Mermaid diagrams for visualization. 
  Best for teaching or documenting complex architectural interactions.
---

# Code Explanation Skill (Visualized Logic)

This skill helps you understand how different parts of the system interact, from the presentation layer down to the database.

## 🧭 When to Use

- ✅ When a user asks "Explain how this feature works."
- ✅ When documenting a complex data flow between features.
- ✅ When onboarding a new developer to a specific architectural pattern.

## 🛠️ Work Process (High Rigor)

### 1. Analyze the Context
Identify the files and layers involved in the process (e.g., UI -> Controller -> UseCase -> Repository -> Service/API).

### 2. Visualize with Mermaid 🧜‍♀️
**MANDATORY RULE**: Every complex explanation must include a Mermaid diagram (Sequence, Class, or Flowchart). 
- **Sequence Diagram**: Best for data flow through layers.
- **Class Diagram**: Best for structural relationships between classes.
- **Flowchart**: Best for logic branching within a function.

### 3. Step-by-Step Breakdown 🏗️
Explain the technical details of Each Step in the flow:
- Input data.
- Logic/transformation at each layer.
- Final output/UI update.

## 📐 Example Prompt

**User**: "Explain the `SpendingParser` logic."
**Agent (Claude)**: 
1. *Setup*: Drafts `mermaid flowchart`.
2. *Visual*: 
   ```mermaid
   graph TD
     A[Input Text] --> B{Regex Match?}
     B -- Yes --> C[Extract Amount]
     B -- No --> D[Return Null]
     C --> E[Format Currency]
     E --> F[Result]
   ```
3. *Detail*: Explains the Regex pattern used and why it resides in `lib/core/utils/`.

## 📜 Commits
`git commit -m "docs: explain spending parser logic"`
