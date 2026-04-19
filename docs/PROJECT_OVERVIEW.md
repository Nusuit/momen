🌟 Project Overview & Current Focus

@Agent_Instruction: Read this file to understand the core concept of the application, the target audience, and the current development phase. This will help you provide context-aware code and suggestions.

1. What is this project?

This is a mobile social photo-sharing application inspired by Locket, but with a unique psychological twist targeting Gen Z users.

Instead of normal photo sharing, the app combines three main pillars:

The "Overthinking" Feed (Anonymous Social): Users form a close circle of friends. When a user posts a photo, it appears on their friends' feeds anonymously. Friends have to guess ("overthink") who posted it. This reduces the pressure to be perfect and encourages casual, funny, or random ("dump") posts.

Fun Financials (Flexing & Shaming): Users can include monetary amounts in their photo captions (e.g., "Ate a bowl of Pho for 50k"). The app parses these numbers using Regex to calculate weekly spending and creates a fun leaderboard to "shame" or "flex" among friends (e.g., "You spent 2x more than your best friend!").

Collaborative Recap Rooms: Users can create rooms to gather their anonymous/public photos and edit them together into a shared memory or export them via CapCut.

2. Tech Stack

Framework: Flutter (Cross-platform for iOS and Android)

Architecture: Feature-First Clean Architecture

State Management: Riverpod

Local Database/Caching: Isar

Backend/BaaS: Supabase

Observability: Firebase Crashlytics

3. 🎯 CURRENT FOCUS (Update this section regularly)

@Agent_Instruction: When generating code or suggesting solutions, prioritize the tasks listed in this current focus area.

Phase 1: Minimum Viable Product (MVP) - The Foundation

[x] Setting up the Clean Architecture folder structure (app, core, and features).

[x] Implementing the base UI components (Design System: Buttons, TextFields, Colors).

[ ] Building the Camera functionality to take pictures.

[ ] Building the Anonymous Feed UI (displaying images with blurred avatars or mysterious placeholder names).

[x] Simple text parser for extracting money amounts from captions (Regex logic).

Note to Human Developer: Please update the "CURRENT FOCUS" section whenever a phase is completed.
