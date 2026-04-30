import 'package:flutter/foundation.dart';
import 'package:momen/features/recap/domain/entities/memory_post.dart';
import 'package:momen/features/recap/domain/entities/memory_owner_option.dart';
import 'package:momen/features/recap/domain/entities/reveal_reminder.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemoriesRemoteDataSource {
  const MemoriesRemoteDataSource(this._client);

  final SupabaseClient? _client;

  static const int pageSize = 20;

  Future<List<MemoryPost>> getMemories({
    String? ownerUserId,
    int page = 0,
  }) async {
    final client = _client;
    if (client == null) return const [];
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final normalizedOwner = (ownerUserId ?? '').trim();
    late final List records;

    try {
      debugPrint(
        '[Memories] querying shared memories owner=${normalizedOwner.isEmpty ? 'all' : normalizedOwner} page=$page',
      );
      records = await client.rpc(
        'get_memories_posts',
        params: {
          'owner_id': normalizedOwner.isEmpty ? null : normalizedOwner,
          'p_page': page,
          'p_page_size': pageSize,
        },
      );
      debugPrint('[Memories] query returned ${records.length} rows');
    } catch (e, st) {
      debugPrint('[Memories] query ERROR: $e\n$st');
      rethrow;
    }

    // ── Apply History Share Grant Filtering ──
    List filteredRecords = records;
    try {
      // 1. Fetch grants where I am the grantee
      final grantsResponse = await client
          .from('history_share_grants')
          .select('granter_id, granted_at')
          .eq('grantee_id', user.id);
      
      final sharedGranters = <String, DateTime>{};
      for (final row in grantsResponse) {
        final granterId = (row['granter_id'] as String?)?.trim() ?? '';
        final grantedAtStr = row['granted_at'] as String?;
        if (granterId.isNotEmpty && grantedAtStr != null) {
          sharedGranters[granterId] = DateTime.tryParse(grantedAtStr) ?? DateTime.now();
        }
      }

      // 2. Fetch friendship dates
      final friendshipsResponse = await client
          .from('friendships')
          .select('requester_id, addressee_id, created_at')
          .or('requester_id.eq.${user.id},addressee_id.eq.${user.id}')
          .eq('status', 'accepted');
      
      final friendshipDates = <String, DateTime>{};
      for (final row in friendshipsResponse) {
        final rId = (row['requester_id'] as String?)?.trim() ?? '';
        final aId = (row['addressee_id'] as String?)?.trim() ?? '';
        final friendId = rId == user.id ? aId : rId;
        final cStr = row['created_at'] as String?;
        if (friendId.isNotEmpty && cStr != null) {
          friendshipDates[friendId] = DateTime.tryParse(cStr) ?? DateTime.now();
        }
      }

      // 3. Filter
      filteredRecords = records.where((record) {
        final ownerId = (record['user_id'] as String?)?.trim() ?? '';
        if (ownerId == user.id || ownerId.isEmpty) return true; // Keep my own posts

        final createdAt = DateTime.tryParse((record['created_at'] as String?) ?? '') ?? DateTime.now();
        
        final grantedAt = sharedGranters[ownerId];
        if (grantedAt != null) {
           // They shared 30 days of history
           final sharedSince = grantedAt.subtract(const Duration(days: 30));
           return createdAt.isAfter(sharedSince);
        } else {
           // No history shared. Only show posts after we became friends.
           // Fallback to 1 day ago if created_at is missing from friendships.
           final friendSince = friendshipDates[ownerId] ?? DateTime.now().subtract(const Duration(days: 1));
           return createdAt.isAfter(friendSince);
        }
      }).toList();
    } catch (e) {
      debugPrint('[Memories] filtering ERROR: $e');
      // If table doesn't exist or column is missing, just fallback to not filtering
    }

    // Batch-fetch owner names for revealed posts
    final postIds = <String>[
      for (final r in filteredRecords) ((r['id'] as String?) ?? '').trim(),
    ]..removeWhere((id) => id.isEmpty);

    final revealedOwnerIds = <String>{
      for (final r in filteredRecords)
        if ((r['is_revealed'] as bool? ?? false) == true &&
            (r['user_id'] as String?) != user.id)
          (r['user_id'] as String? ?? ''),
    }..removeWhere((id) => id.isEmpty);

    final Map<String, String> ownerNames = {};
    if (revealedOwnerIds.isNotEmpty) {
      final profileRows = await client
          .from('profiles')
          .select('id,full_name')
          .inFilter('id', revealedOwnerIds.toList(growable: false));
      for (final row in profileRows) {
        final id = (row['id'] as String?) ?? '';
        if (id.isNotEmpty) {
          ownerNames[id] = _readFullName(row);
        }
      }
    }

    final reactionSummary = await _getReactionSummary(
      client: client,
      postIds: postIds,
      currentUserId: user.id,
    );

    return filteredRecords
        .map((record) {
          final imagePath = (record['image_path'] as String?) ?? '';
          final imageUrl = imagePath.startsWith('http')
              ? imagePath
              : client.storage.from('post_images').getPublicUrl(imagePath);
          final ownerId = (record['user_id'] as String?) ?? '';
          final isRevealed = (record['is_revealed'] as bool?) ?? false;
          final postId = (record['id'] as String?) ?? '';
          final reactions = reactionSummary[postId] ?? const _ReactionSummary();
          return MemoryPost(
            id: postId,
            imageUrl: imageUrl,
            caption: (record['caption'] as String?) ?? '',
            amountVnd: record['amount_vnd'] as int?,
            createdAt: DateTime.tryParse(
                      (record['created_at'] as String?) ?? '',
                    ) ??
                DateTime.now(),
            ownerId: ownerId,
            isRevealed: isRevealed,
            ownerName: isRevealed ? ownerNames[ownerId] : null,
            myReaction: reactions.myReaction,
            loveCount: reactions.loveCount,
            hahaCount: reactions.hahaCount,
            sadCount: reactions.sadCount,
          );
        })
        .where((m) => m.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<MemoryOwnerOption>> getMemoryOwners() async {
    final client = _client;
    if (client == null) return const [];
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final requesterRows = await client
        .from('friendships')
        .select('addressee_id')
        .eq('requester_id', user.id)
        .eq('status', 'accepted');

    final addresseeRows = await client
        .from('friendships')
        .select('requester_id')
        .eq('addressee_id', user.id)
        .eq('status', 'accepted');

    final friendIds = <String>{
      for (final row in requesterRows)
        ((row['addressee_id'] as String?) ?? '').trim(),
      for (final row in addresseeRows)
        ((row['requester_id'] as String?) ?? '').trim(),
    }..removeWhere((id) => id.isEmpty || id == user.id);

    if (friendIds.isEmpty) return const [];

    final profileRows = await client
        .from('profiles')
        .select('id,full_name,avatar_path')
        .inFilter('id', friendIds.toList(growable: false));

    final owners = profileRows
        .map((row) => MemoryOwnerOption(
              id: (row['id'] as String?) ?? '',
              fullName: _readFullName(row),
            ))
        .where((owner) => owner.id.isNotEmpty)
        .toList(growable: false);

    owners.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    return owners;
  }

  Future<void> updateCaption({
    required String postId,
    required String caption,
  }) async {
    final client = _requireClient();
    final user = _requireUser(client);
    await client
        .from('posts')
        .update({'caption': caption})
        .eq('id', postId)
        .eq('user_id', user.id);
  }

  Future<void> deletePost(String postId) async {
    final client = _requireClient();
    final user = _requireUser(client);

    String? imagePath;
    final rows = await client
        .from('posts')
        .select('image_path')
        .eq('id', postId)
        .eq('user_id', user.id)
        .limit(1);
    if (rows.isNotEmpty) {
      imagePath = rows.first['image_path'] as String?;
    }

    await client.from('posts').delete().eq('id', postId).eq('user_id', user.id);

    final storagePath = _storagePathFromImagePath(imagePath);
    if (storagePath != null) {
      try {
        await client.storage.from('post_images').remove([storagePath]);
      } catch (e) {
        debugPrint('[Memories] post image cleanup failed: $e');
      }
    }
  }

  Future<void> reportPost({
    required String postId,
    required String reason,
  }) async {
    final client = _requireClient();
    final user = _requireUser(client);
    await client.from('post_reports').insert({
      'post_id': postId,
      'reporter_id': user.id,
      'reason': reason,
    });
  }

  Future<void> setReaction({
    required String postId,
    required String reactionType,
  }) async {
    final client = _requireClient();
    final user = _requireUser(client);

    final current = await client
        .from('post_reactions')
        .select('reaction_type')
        .eq('post_id', postId)
        .eq('user_id', user.id)
        .maybeSingle();

    if ((current?['reaction_type'] as String?) == reactionType) {
      await client
          .from('post_reactions')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', user.id);
      return;
    }

    await client.from('post_reactions').upsert(
      {
        'post_id': postId,
        'user_id': user.id,
        'reaction_type': reactionType,
      },
      onConflict: 'post_id,user_id',
    );
  }

  Future<List<RevealReminder>> getPendingRevealReminders() async {
    final client = _client;
    if (client == null) return const [];
    if (client.auth.currentUser == null) return const [];

    try {
      final rows = await client.rpc('get_pending_reveal_reminders');
      return (rows as List)
          .map((row) {
            final imagePath = (row['image_path'] as String?) ?? '';
            final imageUrl = imagePath.startsWith('http')
                ? imagePath
                : client.storage.from('post_images').getPublicUrl(imagePath);
            return RevealReminder(
              reminderId: (row['reminder_id'] as String?) ?? '',
              postId: (row['post_id'] as String?) ?? '',
              imageUrl: imageUrl,
              caption: (row['caption'] as String?) ?? '',
              createdAt: DateTime.tryParse(
                    (row['created_at'] as String?) ?? '',
                  ) ??
                  DateTime.now(),
              dueAt: DateTime.tryParse(
                    (row['due_at'] as String?) ?? '',
                  ) ??
                  DateTime.now(),
            );
          })
          .where((item) => item.reminderId.isNotEmpty && item.postId.isNotEmpty)
          .toList(growable: false);
    } catch (e) {
      debugPrint('[Memories] reveal reminder queue unavailable: $e');
      return const [];
    }
  }

  Future<void> resolveRevealReminder({
    required String reminderId,
    required bool reveal,
  }) async {
    final client = _requireClient();
    _requireUser(client);
    await client.rpc(
      'resolve_reveal_reminder',
      params: {
        'p_reminder_id': reminderId,
        'p_reveal': reveal,
      },
    );
  }

  Future<Map<String, _ReactionSummary>> _getReactionSummary({
    required SupabaseClient client,
    required List<String> postIds,
    required String currentUserId,
  }) async {
    if (postIds.isEmpty) return const {};

    try {
      final rows = await client
          .from('post_reactions')
          .select('post_id,user_id,reaction_type')
          .inFilter('post_id', postIds);

      final builders = <String, _ReactionSummaryBuilder>{};
      for (final row in rows) {
        final postId = (row['post_id'] as String?) ?? '';
        final type = (row['reaction_type'] as String?) ?? '';
        if (postId.isEmpty || type.isEmpty) continue;
        final builder =
            builders.putIfAbsent(postId, _ReactionSummaryBuilder.new);
        builder.add(type);
        if ((row['user_id'] as String?) == currentUserId) {
          builder.myReaction = type;
        }
      }

      return {
        for (final entry in builders.entries) entry.key: entry.value.build(),
      };
    } catch (e) {
      debugPrint('[Memories] reactions unavailable: $e');
      return const {};
    }
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase is not configured.');
    }
    return client;
  }

  User _requireUser(SupabaseClient client) {
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in first.');
    }
    return user;
  }

  String? _storagePathFromImagePath(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    if (!imagePath.startsWith('http')) return imagePath;
    final marker = '/post_images/';
    final markerIndex = imagePath.indexOf(marker);
    if (markerIndex == -1) return null;
    return Uri.decodeFull(imagePath.substring(markerIndex + marker.length));
  }

  String _readFullName(Map<String, dynamic> row) {
    final fullName = ((row['full_name'] as String?) ?? '').trim();
    if (fullName.isNotEmpty) return fullName;
    final legacyDisplay = ((row['display_name'] as String?) ?? '').trim();
    if (legacyDisplay.isNotEmpty) return legacyDisplay;
    return 'Unknown';
  }
}

class _ReactionSummary {
  const _ReactionSummary({
    this.myReaction,
    this.loveCount = 0,
    this.hahaCount = 0,
    this.sadCount = 0,
  });

  final String? myReaction;
  final int loveCount;
  final int hahaCount;
  final int sadCount;
}

class _ReactionSummaryBuilder {
  String? myReaction;
  int loveCount = 0;
  int hahaCount = 0;
  int sadCount = 0;

  void add(String reactionType) {
    switch (reactionType) {
      case 'love':
        loveCount++;
        break;
      case 'haha':
        hahaCount++;
        break;
      case 'sad':
        sadCount++;
        break;
    }
  }

  _ReactionSummary build() => _ReactionSummary(
        myReaction: myReaction,
        loveCount: loveCount,
        hahaCount: hahaCount,
        sadCount: sadCount,
      );
}
