import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momen/core/components/cached_post_image.dart';
import 'package:momen/core/constants/app_sizes.dart';
import 'package:momen/core/utils/post_alias.dart';
import 'package:momen/features/auth/presentation/state/friend_search_provider.dart';

class PublicProfilePage extends ConsumerWidget {
  const PublicProfilePage({
    required this.userId,
    required this.onBack,
    super.key,
  });

  final String userId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileByIdProvider(userId));
    final postsAsync = ref.watch(publicProfilePostsProvider(userId));
    final pending = ref.watch(friendRequestPendingIdsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Friend profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showActions(context, ref),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
                child: Text('Profile not found or unavailable.'));
          }

          final addPending = pending.contains(profile.id);
          final acceptPending = pending.contains('accept:${profile.id}');
          final rejectPending = pending.contains('reject:${profile.id}');
          final removePending = pending.contains('remove:${profile.id}');

          return ListView(
            padding: const EdgeInsets.all(AppSizes.p24),
            children: [
              // ── Avatar ──────────────────────────────────────────────
              Center(
                child: profile.avatarUrl != null
                    ? ClipOval(
                        child: CachedPostImage(
                          imageUrl: profile.avatarUrl!,
                          width: 88,
                          height: 88,
                        ),
                      )
                    : const CircleAvatar(
                        radius: 44,
                        child: Icon(Icons.person, size: 36),
                      ),
              ),
              const SizedBox(height: AppSizes.p12),
              Text(
                profile.fullName,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (profile.userCode != null &&
                  profile.userCode!.isNotEmpty) ...[
                const SizedBox(height: AppSizes.p4),
                Text(
                  '#${profile.userCode}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSizes.p24),

              // ── Friendship action ────────────────────────────────────
              if (profile.isFriend)
                FilledButton.tonal(
                  onPressed: removePending
                      ? null
                      : () async {
                          await ref
                              .read(friendRequestPendingIdsProvider.notifier)
                              .removeFriendship(profile.id);
                          ref.invalidate(publicProfileByIdProvider(userId));
                        },
                  child: Text(removePending ? 'Removing...' : 'Unfriend'),
                )
              else if (profile.hasPendingOutgoing)
                FilledButton.tonal(
                  onPressed: removePending
                      ? null
                      : () async {
                          await ref
                              .read(friendRequestPendingIdsProvider.notifier)
                              .removeFriendship(profile.id);
                          ref.invalidate(publicProfileByIdProvider(userId));
                        },
                  child: Text(removePending ? 'Cancelling...' : 'Cancel request'),
                )
              else if (profile.hasPendingIncoming)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: acceptPending || rejectPending
                            ? null
                            : () async {
                                await ref
                                    .read(
                                        friendRequestPendingIdsProvider.notifier)
                                    .respondToRequest(
                                      requesterId: profile.id,
                                      accept: false,
                                    );
                                ref.invalidate(publicProfileByIdProvider(userId));
                              },
                        child:
                            Text(rejectPending ? 'Rejecting...' : 'Reject'),
                      ),
                    ),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(
                      child: FilledButton(
                        onPressed: acceptPending || rejectPending
                            ? null
                            : () async {
                                await ref
                                    .read(
                                        friendRequestPendingIdsProvider.notifier)
                                    .respondToRequest(
                                      requesterId: profile.id,
                                      accept: true,
                                    );
                                ref.invalidate(publicProfileByIdProvider(userId));
                              },
                        child:
                            Text(acceptPending ? 'Accepting...' : 'Accept'),
                      ),
                    ),
                  ],
                )
              else
                FilledButton(
                  onPressed: addPending
                      ? null
                      : () async {
                          await ref
                              .read(friendRequestPendingIdsProvider.notifier)
                              .sendRequest(profile.id);
                          ref.invalidate(publicProfileByIdProvider(userId));
                        },
                  child: Text(addPending ? 'Sending...' : 'Add friend'),
                ),

              const SizedBox(height: AppSizes.p20),
              Text(
                'Visible posts (after 3 days)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSizes.p8),

              // ── Posts ────────────────────────────────────────────────
              postsAsync.when(
                data: (posts) {
                  if (posts.isEmpty) {
                    return const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: AppSizes.p8),
                      child: Text('No public posts visible yet.'),
                    );
                  }
                  return Column(
                    children: posts
                        .map((post) => Card(
                              margin: const EdgeInsets.only(
                                  bottom: AppSizes.p12),
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(AppSizes.p12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          AppSizes.r12),
                                      child: CachedPostImage(
                                        imageUrl: post.imageUrl,
                                        width: 88,
                                        height: 88,
                                      ),
                                    ),
                                    const SizedBox(width: AppSizes.p12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            post.caption.isEmpty
                                                ? '(No caption)'
                                                : post.caption,
                                            maxLines: 2,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: AppSizes.p8),
                                          Text(
                                            'Alias: ${PostAlias.fromPostId(post.id)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ))
                        .toList(growable: false),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.p8),
                  child: LinearProgressIndicator(),
                ),
                error: (error, _) => Text('Cannot load posts: $error'),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p24),
            child: Text('Cannot load profile: $error'),
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block user',
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed =
                    await _confirmDialog(context, 'Block this user?',
                        'They will no longer be able to find you.');
                if (confirmed != true) return;
                try {
                  await ref
                      .read(friendRequestPendingIdsProvider.notifier)
                      .blockUser(userId);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User blocked.')),
                  );
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).maybePop();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report user'),
              onTap: () async {
                Navigator.pop(ctx);
                final reason = await _reportDialog(context);
                if (reason == null || reason.isEmpty) return;
                try {
                  await ref
                      .read(friendRequestPendingIdsProvider.notifier)
                      .reportUser(targetUserId: userId, reason: reason);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Report submitted. Thank you.')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDialog(
      BuildContext context, String title, String body) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
  }

  Future<String?> _reportDialog(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report user'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Describe the issue...',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Submit')),
        ],
      ),
    );
  }
}
