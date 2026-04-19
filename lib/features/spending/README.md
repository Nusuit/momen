# Spending Feature Guide (Parsing & Leaderboard)

@Agent_Instruction: This feature handles all aspects of identifying and tracking currency in captions. It uses Regex logic and parses spending habits relative to friends.

## 🧭 Directory Map & Navigation

### 1. **Domain Layer** (`lib/features/spending/domain/`)
- **`entities/spending_entry.dart`**: Defines the `SpendingEntryEntity` (amount, currency, category, timestamp).
- **`repositories/spending_repository.dart`**: Interface for `getWeeklySpending()`, `saveAmount()`, `getLeaderboard()`.

### 2. **Data Layer** (`lib/features/spending/data/`)
- **`models/spending_model.dart`**: Handles data mapping for the Weekly Spending API.
- **`datasources/spending_remote_datasource.dart`**: Fetches spending summaries and friend leaderboards.

### 3. **Presentation Layer** (`lib/features/spending/presentation/`)
- **`state/spending_controller.dart`**: Manages the Leaderboard ranking and filters.
- **`pages/leaderboard_page.dart`**: Shows friends' spending comparisons ("Flexing & Shaming").
- **`widgets/rank_card_widget.dart`**: Displays a single friend's rank and spending total.

## 🧭 Routes (lib/core/routing/app_router.dart)

- `/leaderboard`: View your rank versus your friends.
- `/spending-stats`: A detailed view of your personal spending habits.

## ⚖️ Spending Feature Rules

- **Regex Logic**: Always use the `SpendingParser` utility from `lib/core/utils/` to extract amounts from photo captions.
- **Gamification**: The UI should feel fun and playful (e.g., using "Flex" or "Shame" badges).
- **Weekly Reset**: Spending totals should reset every Monday morning at 00:00.
