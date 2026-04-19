import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momen/core/components/cached_post_image.dart';
import 'package:momen/core/components/empty_state_card.dart';
import 'package:momen/core/constants/app_sizes.dart';
import 'package:momen/core/providers/core_providers.dart';
import 'package:momen/core/utils/post_alias.dart';
import 'package:momen/features/auth/presentation/state/friend_search_provider.dart';
import 'package:momen/features/recap/domain/entities/memory_owner_option.dart';
import 'package:momen/features/recap/domain/entities/memory_post.dart';
import 'package:momen/features/recap/presentation/state/memories_provider.dart';

class MemoriesPage extends ConsumerStatefulWidget {
  const MemoriesPage({super.key});

  @override
  ConsumerState<MemoriesPage> createState() => _MemoriesPageState();
}

class _MemoriesPageState extends ConsumerState<MemoriesPage> {
  @override
  Widget build(BuildContext context) {
    final selectedOwnerId = ref.watch(selectedMemoryOwnerIdProvider);
    final ownersAsync = ref.watch(memoryOwnersProvider);
    final memoriesAsync = ref.watch(memoriesProvider);
    final pendingPosts = ref.watch(pendingPostsProvider);
    final viewMode = ref.watch(memoriesViewModeProvider);
    final focusedIndex = ref.watch(focusedMemoryIndexProvider);
    final currentUserId =
        ref.watch(supabaseClientProvider)?.auth.currentUser?.id ?? '';

    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          // ── Top bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.p16, AppSizes.p8, AppSizes.p16, AppSizes.p4),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                  ),
                  child: const Icon(Icons.account_circle_outlined),
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: Center(
                    child: _MemoryOwnerDropdown(
                      ownersAsync: ownersAsync,
                      selectedOwnerId: selectedOwnerId,
                      onChanged: (value) => ref
                          .read(selectedMemoryOwnerIdProvider.notifier)
                          .setOwnerId(value),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.p12),
                Material(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  shape: const CircleBorder(),
                  child: IconButton(
                    key: const Key('memories_overview_toggle_button'),
                    onPressed: () {
                      final n = ref.read(memoriesViewModeProvider.notifier);
                      if (viewMode == MemoriesViewMode.story) {
                        n.showGrid();
                      } else {
                        n.showStory();
                      }
                    },
                    icon: Icon(
                      viewMode == MemoriesViewMode.story
                          ? Icons.grid_view_rounded
                          : Icons.view_carousel_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Pending upload strip ─────────────────────────────────────
          if (pendingPosts.isNotEmpty)
            _PendingPostsStrip(
              pendingPosts: pendingPosts,
              onRetry: (id) =>
                  ref.read(pendingPostsProvider.notifier).retryRemove(id),
            ),

          // ── Feed ─────────────────────────────────────────────────────
          Expanded(
            child: memoriesAsync.when(
              data: (memories) {
                if (memories.isEmpty && pendingPosts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSizes.p16),
                    child: EmptyStateCard(
                      title:
                          'No memories yet. Friends-only anonymous posts will appear here.',
                    ),
                  );
                }

                final clampedIndex = memories.isEmpty
                    ? 0
                    : focusedIndex >= memories.length
                        ? memories.length - 1
                        : focusedIndex;

                if (memories.isNotEmpty && clampedIndex != focusedIndex) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref
                        .read(focusedMemoryIndexProvider.notifier)
                        .setIndex(clampedIndex);
                  });
                }

                if (viewMode == MemoriesViewMode.grid) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(AppSizes.p12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: AppSizes.p8,
                      mainAxisSpacing: AppSizes.p8,
                      childAspectRatio: 0.74,
                    ),
                    itemCount: memories.length,
                    itemBuilder: (context, index) {
                      final memory = memories[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(AppSizes.r16),
                        onTap: () {
                          ref
                              .read(focusedMemoryIndexProvider.notifier)
                              .setIndex(index);
                          ref
                              .read(memoriesViewModeProvider.notifier)
                              .showStory();
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppSizes.r16),
                          child: CachedPostImage(imageUrl: memory.imageUrl),
                        ),
                      );
                    },
                  );
                }

                return _MemoryStoryView(
                  memories: memories,
                  initialIndex: clampedIndex,
                  currentUserId: currentUserId,
                  onPageChanged: (index) => ref
                      .read(focusedMemoryIndexProvider.notifier)
                      .setIndex(index),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.p24),
                  child: Text('Cannot load memories: $error'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pending posts strip ──────────────────────────────────────────────────────

class _PendingPostsStrip extends StatelessWidget {
  const _PendingPostsStrip({
    required this.pendingPosts,
    required this.onRetry,
  });

  final List<MemoryPost> pendingPosts;
  final void Function(String id) onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(AppSizes.p8),
        itemCount: pendingPosts.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppSizes.p8),
        itemBuilder: (_, i) {
          final post = pendingPosts[i];
          return SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.r8),
                  child: post.imageUrl.startsWith('/')
                      ? Image.file(File(post.imageUrl),
                          width: 52, height: 52, fit: BoxFit.cover)
                      : CachedPostImage(
                          imageUrl: post.imageUrl,
                          width: 52,
                          height: 52),
                ),
                if (post.isPending)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                else
                  GestureDetector(
                    onTap: () => onRetry(post.id),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(AppSizes.r8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.white, size: 16),
                          Text('Retry',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Story view ───────────────────────────────────────────────────────────────

class _MemoryStoryView extends ConsumerStatefulWidget {
  const _MemoryStoryView({
    required this.memories,
    required this.initialIndex,
    required this.currentUserId,
    required this.onPageChanged,
  });

  final List<MemoryPost> memories;
  final int initialIndex;
  final String currentUserId;
  final ValueChanged<int> onPageChanged;

  @override
  ConsumerState<_MemoryStoryView> createState() => _MemoryStoryViewState();
}

class _MemoryStoryViewState extends ConsumerState<_MemoryStoryView> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void didUpdateWidget(covariant _MemoryStoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex &&
        _pageController.hasClients) {
      _pageController.jumpToPage(widget.initialIndex);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final revealingIds = ref.watch(revealPostControllerProvider);

    return PageView.builder(
      controller: _pageController,
      itemCount: widget.memories.length,
      onPageChanged: widget.onPageChanged,
      itemBuilder: (context, index) {
        final memory = widget.memories[index];
        final trimmedCaption = memory.caption.trim();
        final alias = PostAlias.fromPostId(memory.id);
        final isOwn = memory.ownerId == widget.currentUserId;
        final ageInDays =
            DateTime.now().difference(memory.createdAt).inDays;
        final canReveal =
            isOwn && ageInDays >= 3 && !memory.isRevealed;
        final isRevealing = revealingIds.contains(memory.id);
        final postActions = ref.watch(postActionControllerProvider);
        final isPostBusy = postActions.any((key) => key.endsWith(memory.id));

        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSizes.p12, AppSizes.p8, AppSizes.p12, AppSizes.p12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.r24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedPostImage(imageUrl: memory.imageUrl),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.p16,
                      AppSizes.p12,
                      AppSizes.p16,
                      AppSizes.p32,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xB3000000), Color(0x00000000)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        memory.isRevealed && memory.ownerName != null
                            ? memory.ownerName!
                            : alias,
                        key: const Key('memories_story_alias_top_center'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSizes.p8,
                  left: AppSizes.p12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p8,
                      vertical: AppSizes.p4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(AppSizes.r12),
                    ),
                    child: Text(
                      _timeAgo(memory.createdAt),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSizes.p8,
                  right: AppSizes.p8,
                  child: PopupMenuButton<_PostMenuAction>(
                    key: const Key('memories_story_post_menu_button'),
                    enabled: !isPostBusy,
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    color: Theme.of(context).colorScheme.surface,
                    onSelected: (action) => _handlePostMenuAction(
                      context: context,
                      memory: memory,
                      isOwn: isOwn,
                      action: action,
                    ),
                    itemBuilder: (_) => [
                      if (isOwn)
                        const PopupMenuItem(
                          value: _PostMenuAction.editCaption,
                          child: Text('Edit caption'),
                        ),
                      if (isOwn)
                        const PopupMenuItem(
                          value: _PostMenuAction.delete,
                          child: Text('Delete post'),
                        ),
                      if (!isOwn)
                        const PopupMenuItem(
                          value: _PostMenuAction.report,
                          child: Text('Report post'),
                        ),
                      if (!isOwn)
                        const PopupMenuItem(
                          value: _PostMenuAction.unfriend,
                          child: Text('Unfriend'),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.p16,
                      AppSizes.p32,
                      AppSizes.p16,
                      AppSizes.p16,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xB3000000)],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (trimmedCaption.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.p24,
                            ),
                            child: Text(
                              trimmedCaption,
                              key: const Key('memories_story_caption_center'),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                height: 1.18,
                                shadows: [
                                  Shadow(color: Colors.black87, blurRadius: 10),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.p12),
                        ],
                        _ReactionBar(
                          memory: memory,
                          isBusy: postActions.contains('reaction:${memory.id}'),
                          onReact: (reactionType) async {
                            try {
                              await ref
                                  .read(postActionControllerProvider.notifier)
                                  .setReaction(
                                    postId: memory.id,
                                    reactionType: reactionType,
                                  );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: AppSizes.p8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (canReveal)
                              FilledButton.icon(
                                onPressed: isRevealing
                                    ? null
                                    : () => ref
                                        .read(revealPostControllerProvider
                                            .notifier)
                                        .reveal(memory.id),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white24,
                                  foregroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: isRevealing
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.visibility, size: 14),
                                label: Text(isRevealing
                                    ? 'Revealing...'
                                    : 'Reveal identity'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  Future<void> _handlePostMenuAction({
    required BuildContext context,
    required MemoryPost memory,
    required bool isOwn,
    required _PostMenuAction action,
  }) async {
    switch (action) {
      case _PostMenuAction.editCaption:
        if (!isOwn) return;
        final caption = await _captionDialog(context, memory.caption);
        if (caption == null) return;
        try {
          await ref.read(postActionControllerProvider.notifier).updateCaption(
                postId: memory.id,
                caption: caption,
              );
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Caption updated.')),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
        return;
      case _PostMenuAction.delete:
        if (!isOwn) return;
        final confirmed = await _confirmDeleteDialog(context);
        if (confirmed != true) return;
        try {
          await ref
              .read(postActionControllerProvider.notifier)
              .deletePost(memory.id);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted.')),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
        return;
      case _PostMenuAction.report:
        if (isOwn) return;
        final reason = await _postReportDialog(context);
        if (reason == null || reason.isEmpty) return;
        try {
          await ref.read(postActionControllerProvider.notifier).reportPost(
                postId: memory.id,
                reason: reason,
              );
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report submitted.')),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      case _PostMenuAction.unfriend:
        if (isOwn) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Unfriend?'),
            content: const Text('Remove this user from your friend list?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Unfriend'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        try {
          await ref
              .read(friendRequestPendingIdsProvider.notifier)
              .removeFriendship(memory.ownerId);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unfriended.')),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
    }
  }

  Future<String?> _captionDialog(BuildContext context, String initialCaption) {
    final controller = TextEditingController(text: initialCaption);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit caption'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Write a caption...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This removes the photo from your memories.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<String?> _postReportDialog(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report post'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration:
              const InputDecoration(hintText: 'Describe the issue...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

enum _PostMenuAction { editCaption, delete, report, unfriend }

class _ReactionBar extends StatelessWidget {
  const _ReactionBar({
    required this.memory,
    required this.isBusy,
    required this.onReact,
  });

  final MemoryPost memory;
  final bool isBusy;
  final ValueChanged<String> onReact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSizes.p8,
      children: [
        _ReactionButton(
          icon: Icons.favorite,
          reactionType: 'love',
          count: memory.loveCount,
          selectedReaction: memory.myReaction,
          isBusy: isBusy,
          onReact: onReact,
          selectedColor: const Color(0xFFFF5B7F),
        ),
        _ReactionButton(
          icon: Icons.sentiment_very_satisfied,
          reactionType: 'haha',
          count: memory.hahaCount,
          selectedReaction: memory.myReaction,
          isBusy: isBusy,
          onReact: onReact,
          selectedColor: const Color(0xFFFFC83D),
        ),
        _ReactionButton(
          icon: Icons.sentiment_dissatisfied,
          reactionType: 'sad',
          count: memory.sadCount,
          selectedReaction: memory.myReaction,
          isBusy: isBusy,
          onReact: onReact,
          selectedColor: const Color(0xFF6AA9FF),
        ),
      ],
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.icon,
    required this.reactionType,
    required this.count,
    required this.selectedReaction,
    required this.isBusy,
    required this.onReact,
    required this.selectedColor,
  });

  final IconData icon;
  final String reactionType;
  final int count;
  final String? selectedReaction;
  final bool isBusy;
  final ValueChanged<String> onReact;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedReaction == reactionType;
    final bgColor = isSelected ? selectedColor : Colors.white24;
    final fgColor = isSelected ? Colors.black : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(AppSizes.r20),
          onTap: isBusy ? null : () => onReact(reactionType),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppSizes.r20),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white38,
                width: isSelected ? 1.4 : 1,
              ),
              boxShadow: isSelected
                  ? const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, size: 24, color: fgColor),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── Owner dropdown ───────────────────────────────────────────────────────────

class _MemoryOwnerDropdown extends StatelessWidget {
  const _MemoryOwnerDropdown({
    required this.ownersAsync,
    required this.selectedOwnerId,
    required this.onChanged,
  });

  final AsyncValue<List<MemoryOwnerOption>> ownersAsync;
  final String? selectedOwnerId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final friends = ownersAsync.maybeWhen(
      data: (owners) => owners,
      orElse: () => const <MemoryOwnerOption>[],
    );

    final menuItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(
          value: null, child: Text('All friends & me')),
      ...friends.map((owner) => DropdownMenuItem<String?>(
          value: owner.id, child: Text(owner.fullName))),
    ];

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.r20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          key: const Key('memories_owner_dropdown'),
          value: menuItems.any((item) => item.value == selectedOwnerId)
              ? selectedOwnerId
              : null,
          isExpanded: true,
          alignment: Alignment.center,
          items: menuItems,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
