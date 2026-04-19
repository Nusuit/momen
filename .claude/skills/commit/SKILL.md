---
name: commit
description: |
  Generates standard Git commit messages following the Conventional Commits specification. 
  Analyzes changes and produces clear, concise "feat", "fix", "docs", or "refactor" messages.
---

# Commit Skill (Conventional Standards)

This skill ensures that your version history is clean, readable, and professional.

## 🧭 When to Use

- ✅ After completing a task or sub-task.
- ✅ When preparing to push changes to the repository.
- ✅ Before merging a feature branch.

## 🛠️ Work Process (High Rigor)

### 1. Analyze Changes
If staged changes exist, run `git diff --cached` (or equivalent) to understand the scope of the modification. 

### 2. Categorize the Change 🏷️
Assign the correct type to the commit:
- **`feat`**: A new feature for the user.
- **`fix`**: A bug fix for the user.
- **`docs`**: Changes to the documentation.
- **`style`**: Formatting, missing semi-colons, etc; no production code change.
- **`refactor`**: Refactoring production code, e.g. renaming a variable.
- **`test`**: Adding missing tests, refactoring tests; no production code change.
- **`chore`**: Updating build tasks, package manager configs, etc; no production code change.

### 3. Draft the Message 📜
**RULE**: Use the format `git commit -m "type: description"`. Keep the description concise and in the imperative mood (e.g., "implement login logic").

## 📐 Example Prompt

**User**: "I added the login logic and updated the README."
**Agent (Claude)**: 
1. *Analysis*: Noticed a new UseCase and a change to `PROJECT_OVERVIEW.md`.
2. *Decision*: Create two separate commits if preferred, or a combined feat. 
3. *Recommendation*: `git commit -m "feat: implement user login logic"` then `git commit -m "docs: update project overview"`.

## 📜 Commits
`git commit -m "feat: implement user login logic"`
