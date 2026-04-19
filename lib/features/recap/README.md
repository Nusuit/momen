# Recap Feature Guide (Shared Rooms & Photo Memories)

@Agent_Instruction: This feature allows users to gather their photos into shared rooms for collaborative viewing and memory creation. It supports exporting to social media (CapCut/Instagram).

## 🧭 Directory Map & Navigation

### 1. **Domain Layer** (`lib/features/recap/domain/`)
- **`entities/recap_room_entity.dart`**: Defines the `RecapRoomEntity` (Room ID, name, list of photos, members).
- **`repositories/recap_repository.dart`**: Interface for `createRoom()`, `joinRoom()`, `addPhotoToRecap()`.

### 2. **Data Layer** (`lib/features/recap/data/`)
- **`models/recap_room_model.dart`**: Handles data mapping for the Shared Rooms API.
- **`datasources/recap_remote_datasource.dart`**: Fetches the collection of shared photos.

### 3. **Presentation Layer** (`lib/features/recap/presentation/`)
- **`state/recap_controller.dart`**: Manages the multi-user photo selection and editing state.
- **`pages/recap_room_page.dart`**: The collaborative editing screen.
- **`widgets/photo_grid_widget.dart`**: A layout specific for the shared photo wall.

## 🧭 Routes (lib/core/routing/app_router.dart)

- `/recaps`: A list of your current shared rooms.
- `/room-detail`: The editor and viewer for a specific room.
- `/export`: The flow for generating a memory video or collage.

## ⚖️ Recap Feature Rules

- **Collaboration**: Multiple users should be able to see updates in real-time as photos are added to a room.
- **Exporting**: Photos should be normalized for aspect ratio before being exported via the `CapCut` API.
- **Privacy**: Photo access is strictly limited to members of the room.
