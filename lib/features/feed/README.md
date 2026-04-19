# Feed Feature Guide (Anonymous Overthinking Feed)

@Agent_Instruction: This feature is the core engagement loop of the app. It handles the photography, anonymous delivery, and the "guessing" (overthinking) mechanism.

## 🧭 Directory Map & Navigation

### 1. **Domain Layer** (`lib/features/feed/domain/`)
- **`entities/feed_post_entity.dart`**: Defines the `FeedPostEntity` (photo URL, timestamp, blurred avatar status).
- **`repositories/feed_repository.dart`**: Interface for `getPosts()`, `uploadPhoto()`, `guessAuthor()`.

### 2. **Data Layer** (`lib/features/feed/data/`)
- **`models/feed_post_model.dart`**: Maps raw JSON data from the feed API.
- **`datasources/feed_remote_datasource.dart`**: Handles the photo upload to the cloud and fetching the feed.

### 3. **Presentation Layer** (`lib/features/feed/presentation/`)
- **`state/feed_controller.dart`**: Manages the scrolling list of posts and the "Guessing" state.
- **`pages/feed_page.dart`**: The primary feed screen.
- **`widgets/post_card_widget.dart`**: Feature-specific UI for each photo post.

## 🧭 Routes (lib/core/routing/app_router.dart)

- `/feed`: The main social feed.
- `/camera`: The camera interface to take and post a photo.
- `/post-detail`: A detailed view of a single post to "overthink" and guess the author.

## ⚖️ Feed Rules

- **Anonymity**: The author's avatar must remain blurred until a certain threshold is met (e.g., number of guesses or time elapsed).
- **Locket Style**: The feed should prioritize high-quality, full-screen photo views over text.
- **Real-time Updates**: Use WebSockets or Supabase Realtime to push new posts to users instantly.
