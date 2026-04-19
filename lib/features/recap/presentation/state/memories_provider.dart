import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momen/core/providers/core_providers.dart';
import 'package:momen/features/feed/data/datasources/feed_post_remote_datasource.dart';
import 'package:momen/features/feed/data/repositories_impl/captured_post_repository_impl.dart';
import 'package:momen/features/feed/domain/usecases/create_captured_post_usecase.dart';
import 'package:momen/features/recap/data/datasources/memories_remote_datasource.dart';
import 'package:momen/features/recap/data/repositories_impl/memories_repository_impl.dart';
import 'package:momen/features/recap/domain/entities/memory_owner_option.dart';
import 'package:momen/features/recap/domain/entities/memory_post.dart';
import 'package:momen/features/recap/domain/entities/reveal_reminder.dart';
import 'package:momen/features/recap/domain/usecases/get_memory_owners_usecase.dart';
import 'package:momen/features/recap/domain/usecases/get_memories_usecase.dart';
import 'package:momen/features/recap/domain/usecases/reveal_reminder_usecases.dart';

enum MemoriesViewMode { story, grid }

// ─── Infrastructure ───────────────────────────────────────────────────────────

final _memoriesRemoteDataSourceProvider = Provider<MemoriesRemoteDataSource>(
  (ref) => MemoriesRemoteDataSource(ref.watch(supabaseClientProvider)),
);

final _memoriesRepositoryProvider = Provider<MemoriesRepositoryImpl>(
  (ref) => MemoriesRepositoryImpl(ref.watch(_memoriesRemoteDataSourceProvider)),
);

final _getMemoriesUseCaseProvider = Provider<GetMemoriesUseCase>(
  (ref) => GetMemoriesUseCase(ref.watch(_memoriesRepositoryProvider)),
);

final _getMemoryOwnersUseCaseProvider = Provider<GetMemoryOwnersUseCase>(
  (ref) => GetMemoryOwnersUseCase(ref.watch(_memoriesRepositoryProvider)),
);

final _getPendingRevealRemindersUseCaseProvider =
    Provider<GetPendingRevealRemindersUseCase>(
  (ref) =>
      GetPendingRevealRemindersUseCase(ref.watch(_memoriesRepositoryProvider)),
);

final _resolveRevealReminderUseCaseProvider =
    Provider<ResolveRevealReminderUseCase>(
  (ref) =>
      ResolveRevealReminderUseCase(ref.watch(_memoriesRepositoryProvider)),
);

final _feedPostRemoteDataSourceProvider = Provider<FeedPostRemoteDataSource>(
  (ref) => FeedPostRemoteDataSource(ref.watch(supabaseClientProvider)),
);

final _capturedPostRepositoryProvider = Provider<CapturedPostRepositoryImpl>(
  (ref) => CapturedPostRepositoryImpl(
      ref.watch(_feedPostRemoteDataSourceProvider)),
);

final _revealPostUseCaseProvider = Provider<RevealPostUseCase>(
  (ref) => RevealPostUseCase(ref.watch(_capturedPostRepositoryProvider)),
);

// ─── View state ───────────────────────────────────────────────────────────────

final selectedMemoryOwnerIdProvider =
    NotifierProvider.autoDispose<SelectedMemoryOwnerIdNotifier, String?>(
  SelectedMemoryOwnerIdNotifier.new,
);

class SelectedMemoryOwnerIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setOwnerId(String? ownerId) => state = ownerId;
}

final memoriesViewModeProvider =
    NotifierProvider.autoDispose<MemoriesViewModeNotifier, MemoriesViewMode>(
  MemoriesViewModeNotifier.new,
);

class MemoriesViewModeNotifier extends Notifier<MemoriesViewMode> {
  @override
  MemoriesViewMode build() => MemoriesViewMode.story;
  void showStory() => state = MemoriesViewMode.story;
  void showGrid() => state = MemoriesViewMode.grid;
}

final focusedMemoryIndexProvider =
    NotifierProvider.autoDispose<FocusedMemoryIndexNotifier, int>(
  FocusedMemoryIndexNotifier.new,
);

class FocusedMemoryIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setIndex(int index) => state = index < 0 ? 0 : index;
}

// ─── Pending posts (optimistic upload) ───────────────────────────────────────

final pendingPostsProvider =
    NotifierProvider<PendingPostsNotifier, List<MemoryPost>>(
  PendingPostsNotifier.new,
);

class PendingPostsNotifier extends Notifier<List<MemoryPost>> {
  @override
  List<MemoryPost> build() => const [];

  void add(MemoryPost post) => state = [post, ...state];

  void remove(String tempId) {
    state = state.where((p) => p.id != tempId).toList(growable: false);
    ref.invalidate(memoriesProvider);
    ref.invalidate(memoriesPageProvider);
    ref.invalidate(memoryCountProvider);
  }

  void markFailed(String tempId) {
    state = [
      for (final p in state)
        if (p.id == tempId)
          MemoryPost(
            id: p.id,
            imageUrl: p.imageUrl,
            caption: p.caption,
            amountVnd: p.amountVnd,
            createdAt: p.createdAt,
            ownerId: p.ownerId,
            isPending: false,
            myReaction: p.myReaction,
            loveCount: p.loveCount,
            hahaCount: p.hahaCount,
            sadCount: p.sadCount,
          )
        else
          p,
    ];
  }

  void retryRemove(String tempId) => remove(tempId);
}

// ─── Paginated memories ───────────────────────────────────────────────────────

final memoriesPageProvider =
    NotifierProvider.autoDispose<MemoriesNotifier, List<MemoryPost>>(
  MemoriesNotifier.new,
);

class MemoriesNotifier extends Notifier<List<MemoryPost>> {
  int _page = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  List<MemoryPost> build() {
    _page = 0;
    _hasMore = true;
    _loadPage(0);
    return const [];
  }

  Future<void> _loadPage(int page) async {
    final ownerId = ref.read(selectedMemoryOwnerIdProvider);
    final posts = await ref
        .read(_getMemoriesUseCaseProvider)
        .call(ownerUserId: ownerId, page: page);
    if (page == 0) {
      state = posts;
    } else {
      state = [...state, ...posts];
    }
    _hasMore = posts.length >= MemoriesRemoteDataSource.pageSize;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    _page++;
    await _loadPage(_page);
    _isLoadingMore = false;
  }

  Future<void> refresh() async {
    _page = 0;
    _hasMore = true;
    await _loadPage(0);
  }

  bool get hasMore => _hasMore;
}

// Keep the old provider name as alias so existing code compiles
final memoriesProvider = FutureProvider<List<MemoryPost>>((ref) {
  final ownerId = ref.watch(selectedMemoryOwnerIdProvider);
  return ref
      .watch(_getMemoriesUseCaseProvider)
      .call(ownerUserId: ownerId, page: 0);
});

final memoryOwnersProvider =
    FutureProvider.autoDispose<List<MemoryOwnerOption>>(
  (ref) => ref.watch(_getMemoryOwnersUseCaseProvider).call(),
);

final ownMemoriesProvider =
    FutureProvider.autoDispose<List<MemoryPost>>((ref) {
  final userId =
      ref.watch(supabaseClientProvider)?.auth.currentUser?.id;
  if (userId == null || userId.isEmpty) {
    return Future.value(const <MemoryPost>[]);
  }
  return ref
      .watch(_getMemoriesUseCaseProvider)
      .call(ownerUserId: userId, page: 0);
});

final memoryCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final memories = await ref.watch(ownMemoriesProvider.future);
  return memories.length;
});

final revealReminderQueueProvider =
    FutureProvider.autoDispose<List<RevealReminder>>((ref) {
  return ref.watch(_getPendingRevealRemindersUseCaseProvider).call();
});

// ─── Reveal identity ──────────────────────────────────────────────────────────

final revealPostControllerProvider =
    NotifierProvider.autoDispose<RevealPostController, Set<String>>(
  RevealPostController.new,
);

class RevealPostController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  Future<void> reveal(String postId) async {
    if (state.contains(postId)) return;
    state = {...state, postId};
    try {
      await ref.read(_revealPostUseCaseProvider).call(postId);
      ref.invalidate(memoriesProvider);
      ref.invalidate(memoriesPageProvider);
    } finally {
      final next = {...state}..remove(postId);
      state = next;
    }
  }
}

// ─── Single-post actions ─────────────────────────────────────────────────────

final postActionControllerProvider =
    NotifierProvider.autoDispose<PostActionController, Set<String>>(
  PostActionController.new,
);

class PostActionController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  Future<void> updateCaption({
    required String postId,
    required String caption,
  }) {
    return _run('caption:$postId', () async {
      await ref
          .read(_memoriesRepositoryProvider)
          .updateCaption(postId: postId, caption: caption);
      _refreshMemories();
    });
  }

  Future<void> deletePost(String postId) {
    return _run('delete:$postId', () async {
      await ref.read(_memoriesRepositoryProvider).deletePost(postId);
      _refreshMemories();
    });
  }

  Future<void> reportPost({
    required String postId,
    required String reason,
  }) {
    return _run('report:$postId', () {
      return ref
          .read(_memoriesRepositoryProvider)
          .reportPost(postId: postId, reason: reason);
    });
  }

  Future<void> setReaction({
    required String postId,
    required String reactionType,
  }) {
    return _run('reaction:$postId', () async {
      await ref.read(_memoriesRepositoryProvider).setReaction(
            postId: postId,
            reactionType: reactionType,
          );
      _refreshMemories();
    });
  }

  Future<void> _run(String key, Future<void> Function() action) async {
    if (state.contains(key)) return;
    state = {...state, key};
    try {
      await action();
    } finally {
      final next = {...state}..remove(key);
      state = next;
    }
  }

  void _refreshMemories() {
    ref.invalidate(memoriesProvider);
    ref.invalidate(memoriesPageProvider);
    ref.invalidate(memoryCountProvider);
  }
}

final revealReminderControllerProvider =
    NotifierProvider.autoDispose<RevealReminderController, Set<String>>(
  RevealReminderController.new,
);

class RevealReminderController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  Future<void> decide({
    required RevealReminder reminder,
    required bool reveal,
  }) async {
    final key = '${reveal ? 'reveal' : 'skip'}:${reminder.reminderId}';
    if (state.contains(key)) return;

    state = {...state, key};
    try {
      await ref.read(_resolveRevealReminderUseCaseProvider).call(
            reminderId: reminder.reminderId,
            reveal: reveal,
          );
      ref.invalidate(revealReminderQueueProvider);
      if (reveal) {
        ref.invalidate(memoriesProvider);
        ref.invalidate(memoriesPageProvider);
      }
    } finally {
      final next = {...state}..remove(key);
      state = next;
    }
  }
}
