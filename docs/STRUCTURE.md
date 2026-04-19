lib/
├── app/                        # App composition layer
│   ├── bootstrap/              # Startup services (Supabase, Crashlytics guards)
│   ├── routing/                # GoRouter route declarations and tab route mapping
│   ├── shell/                  # Cross-feature shell UI (bottom navigation)
│   └── momen_app.dart         # ProviderScope + MaterialApp.router
│
├── core/                       # Shared code across the app (NO feature-specific logic here)
│   ├── components/             # Shared UI widgets (Button, TextField, Card)
│   ├── config/                 # Compile-time env config via --dart-define
│   ├── constants/              # App colors, themes, text styles, API endpoints
│   ├── errors/                 # Defined Failure and Exception types
│   ├── models/                 # Shared models used by more than one feature
│   ├── observability/          # Crash reporting setup
│   ├── persistence/            # Isar local database service
│   ├── providers/              # Shared Riverpod providers
│   ├── services/               # SDK integration services (Supabase, etc.)
│   ├── utils/                  # Utility functions (Currency formatting, dates, regex parsers)
│   └── README.md               # -> @Agent: Read this file before modifying shared core code
│
├── features/                   # Contains independent features (Feature-based)
│   ├── auth/                   # Authentication (Login, Register)
│   ├── feed/                   # Anonymous Feed (Overthinking Feed)
│   ├── spending/               # Spending parser (Regex-based) & Leaderboard
│   ├── recap/                  # Shared memory rooms and photo sharing
│   └── README.md               # -> @Agent: Read this file to understand the internal feature structure
│
├── app.dart                    # Compatibility export for MomenApp
└── main.dart                   # Entry point only
