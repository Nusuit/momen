import 'package:momen/features/auth/domain/entities/friend_profile.dart';
import 'package:momen/features/auth/domain/entities/nearby_user_profile.dart';
import 'package:momen/features/auth/domain/entities/public_profile_post.dart';
import 'package:momen/features/auth/domain/entities/friend_request.dart';
import 'package:momen/features/auth/domain/entities/public_profile_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendSearchRemoteDataSource {
  const FriendSearchRemoteDataSource(this._client);

  final SupabaseClient? _client;

  /// Search by name or ID. '#CODE' performs exact ID lookup.
  Future<List<FriendProfile>> search(String query) async {
    final client = _client;
    if (client == null) return const [];
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final normalized = query.trim();
    if (normalized.isEmpty) return const [];

    List rows;
    if (normalized.startsWith('#')) {
      final code = normalized.substring(1).toUpperCase();
      rows = await client
          .from('profiles')
          .select('id,full_name,user_code,avatar_path')
          .neq('id', user.id)
          .eq('user_code', code)
          .limit(5);
    } else {
      final escaped = normalized.replaceAll('%', r'\%').replaceAll(',', r'\,');
      rows = await client
          .from('profiles')
          .select('id,full_name,user_code,avatar_path')
          .neq('id', user.id)
          .or('full_name.ilike.%$escaped%,user_code.ilike.%$escaped%')
          .limit(15);
    }

    return rows
        .map((row) => FriendProfile(
              id: (row['id'] as String?) ?? '',
              fullName: _readFullName(row),
              userCode: (row['user_code'] as String?) ?? '',
              avatarUrl: _buildAvatarUrl(client, row['avatar_path'] as String?),
            ))
        .where((f) => f.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<int> getFriendCount() async {
    final client = _client;
    if (client == null) return 0;
    final user = client.auth.currentUser;
    if (user == null) return 0;

    final r = await client
        .from('friendships')
        .select('id')
        .eq('requester_id', user.id)
        .eq('status', 'accepted');
    final a = await client
        .from('friendships')
        .select('id')
        .eq('addressee_id', user.id)
        .eq('status', 'accepted');
    return r.length + a.length;
  }

  Future<void> sendFriendRequest(String addresseeId) async {
    final client = _client;
    if (client == null) throw Exception('Supabase is not configured.');
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Please sign in to send friend request.');
    if (addresseeId.isEmpty || addresseeId == user.id) throw Exception('Invalid friend target.');

    final existingDirect = await client
        .from('friendships')
        .select('id,status')
        .eq('requester_id', user.id)
        .eq('addressee_id', addresseeId)
        .limit(1);
    if (existingDirect.isNotEmpty) return;

    final existingReverse = await client
        .from('friendships')
        .select('id,status')
        .eq('requester_id', addresseeId)
        .eq('addressee_id', user.id)
        .limit(1);

    if (existingReverse.isNotEmpty) {
      final reverseStatus =
          ((existingReverse.first['status'] as String?) ?? '').trim();
      if (reverseStatus == 'pending') {
        await client
            .from('friendships')
            .update({'status': 'accepted'})
            .eq('requester_id', addresseeId)
            .eq('addressee_id', user.id)
            .eq('status', 'pending');
      }
      return;
    }

    await client.from('friendships').insert({
      'requester_id': user.id,
      'addressee_id': addresseeId,
      'status': 'pending',
    });
  }

  Future<List<FriendRequest>> getIncomingRequests() async {
    final client = _client;
    if (client == null) return const [];
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final rows = await client
        .from('friendships')
        .select('requester_id,status')
        .eq('addressee_id', user.id)
        .eq('status', 'pending')
        .limit(50);

    final requesterIds = rows
        .map((row) => ((row['requester_id'] as String?) ?? '').trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (requesterIds.isEmpty) return const [];

    final profileRows = await client
        .from('profiles')
        .select('id,full_name,avatar_path')
        .inFilter('id', requesterIds);

    final profileMap = {
      for (final row in profileRows)
        ((row['id'] as String?) ?? '').trim(): row,
    };

    final requests = requesterIds
        .map((id) {
          final profile = profileMap[id];
          if (profile == null) return null;
          return FriendRequest(
            requesterId: id,
            fullName: _readFullName(profile),
          );
        })
        .whereType<FriendRequest>()
        .toList(growable: false);

    requests.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    return requests;
  }

  Future<void> respondToFriendRequest({
    required String requesterId,
    required bool accept,
  }) async {
    final client = _client;
    if (client == null) throw Exception('Supabase is not configured.');
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Please sign in first.');
    final normalizedId = requesterId.trim();
    if (normalizedId.isEmpty || normalizedId == user.id) {
      throw Exception('Invalid friend request.');
    }

    await client
        .from('friendships')
        .update({'status': accept ? 'accepted' : 'rejected'})
        .eq('requester_id', normalizedId)
        .eq('addressee_id', user.id)
        .eq('status', 'pending');
  }

  Future<PublicProfileView?> getPublicProfileById(String userId) async {
    final client = _client;
    if (client == null) return null;
    final currentUser = client.auth.currentUser;
    if (currentUser == null) return null;
    final targetId = userId.trim();
    if (targetId.isEmpty || targetId == currentUser.id) return null;

    final profiles = await client
        .from('profiles')
        .select('id,full_name,user_code,avatar_path')
        .eq('id', targetId)
        .limit(1);
    if (profiles.isEmpty) return null;

    final direct = await client
        .from('friendships')
        .select('status')
        .eq('requester_id', currentUser.id)
        .eq('addressee_id', targetId)
        .limit(1);

    final reverse = await client
        .from('friendships')
        .select('status')
        .eq('requester_id', targetId)
        .eq('addressee_id', currentUser.id)
        .limit(1);

    final directStatus =
        ((direct.isNotEmpty ? direct.first['status'] : null) as String?)?.trim() ?? '';
    final reverseStatus =
        ((reverse.isNotEmpty ? reverse.first['status'] : null) as String?)?.trim() ?? '';

    final profile = profiles.first;
    return PublicProfileView(
      id: targetId,
      fullName: _readFullName(profile),
      isFriend: directStatus == 'accepted' || reverseStatus == 'accepted',
      hasPendingOutgoing: directStatus == 'pending',
      hasPendingIncoming: reverseStatus == 'pending',
      userCode: (profile['user_code'] as String?) ?? '',
      avatarUrl: _buildAvatarUrl(client, profile['avatar_path'] as String?),
    );
  }

  Future<void> removeFriendship(String targetUserId) async {
    final client = _client;
    if (client == null) throw Exception('Supabase is not configured.');
    final currentUser = client.auth.currentUser;
    if (currentUser == null) throw Exception('Please sign in first.');
    final targetId = targetUserId.trim();
    if (targetId.isEmpty || targetId == currentUser.id) throw Exception('Invalid target.');

    await client
        .from('friendships')
        .delete()
        .eq('requester_id', currentUser.id)
        .eq('addressee_id', targetId)
        .inFilter('status', ['pending', 'accepted']);

    await client
        .from('friendships')
        .delete()
        .eq('requester_id', targetId)
        .eq('addressee_id', currentUser.id)
        .eq('status', 'accepted');
  }

  Future<List<PublicProfilePost>> getPublicProfilePosts(String userId) async {
    final client = _client;
    if (client == null) return const [];
    final currentUser = client.auth.currentUser;
    if (currentUser == null) return const [];
    final targetId = userId.trim();
    if (targetId.isEmpty) return const [];

    final records = await client
        .from('posts')
        .select('id,image_path,caption,created_at')
        .eq('user_id', targetId)
        .order('created_at', ascending: false)
        .limit(60);

    return records
        .map((record) {
          final imagePath = (record['image_path'] as String?) ?? '';
          final imageUrl = imagePath.startsWith('http')
              ? imagePath
              : client.storage.from('post_images').getPublicUrl(imagePath);
          return PublicProfilePost(
            id: (record['id'] as String?) ?? '',
            imageUrl: imageUrl,
            caption: (record['caption'] as String?) ?? '',
            createdAt: DateTime.tryParse(
                      (record['created_at'] as String?) ?? '',
                    ) ??
                DateTime.now(),
          );
        })
        .where((post) => post.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<NearbyUserProfile>> getNearbyUsers({
    required double lat,
    required double lon,
    int radiusM = 5000,
  }) async {
    final client = _client;
    if (client == null) return const [];
    if (client.auth.currentUser == null) return const [];

    final rows = await client.rpc('get_nearby_users', params: {
      'lat': lat,
      'lon': lon,
      'radius_m': radiusM,
    });

    return (rows as List)
        .map((row) => NearbyUserProfile(
              id: (row['id'] as String?) ?? '',
              fullName: (row['full_name'] as String?) ?? 'Unknown',
              distanceM: ((row['distance_m'] as num?) ?? 0).toDouble(),
              userCode: (row['user_code'] as String?) ?? '',
              avatarUrl: _buildAvatarUrl(client, row['avatar_path'] as String?),
            ))
        .where((u) => u.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<FriendProfile>> getContactMatches(List<String> phoneHashes) async {
    final client = _client;
    if (client == null) return const [];
    if (client.auth.currentUser == null) return const [];
    if (phoneHashes.isEmpty) return const [];

    final rows = await client.rpc('match_contacts', params: {
      'phone_hashes': phoneHashes,
    });

    return (rows as List)
        .map((row) => FriendProfile(
              id: (row['id'] as String?) ?? '',
            fullName: (row['full_name'] as String?) ?? 'Unknown',
            userCode: (row['user_code'] as String?) ?? '',
            avatarUrl: _buildAvatarUrl(client, row['avatar_path'] as String?),
            matchedPhoneHash: row['matched_phone_hash'] as String?,
          ))
        .where((f) => f.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> blockUser(String targetUserId) async {
    final client = _client;
    if (client == null) throw Exception('Supabase is not configured.');
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Please sign in first.');
    await client.from('user_blocks').insert({
      'blocker_id': user.id,
      'blocked_id': targetUserId,
    });
  }

  Future<void> reportUser({
    required String targetUserId,
    required String reason,
  }) async {
    final client = _client;
    if (client == null) throw Exception('Supabase is not configured.');
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Please sign in first.');
    await client.from('user_reports').insert({
      'reporter_id': user.id,
      'reported_id': targetUserId,
      'reason': reason,
    });
  }

  Future<void> updateLocation({
    required double lat,
    required double lon,
  }) async {
    final client = _client;
    if (client == null) return;
    final user = client.auth.currentUser;
    if (user == null) return;

    await client.from('profiles').update({
      'location': 'POINT($lon $lat)',
    }).eq('id', user.id);
  }

  String _readFullName(Map<String, dynamic> row) {
    final fullName = ((row['full_name'] as String?) ?? '').trim();
    if (fullName.isNotEmpty) return fullName;
    final legacyDisplay = ((row['display_name'] as String?) ?? '').trim();
    if (legacyDisplay.isNotEmpty) return legacyDisplay;
    final legacyUser = ((row['username'] as String?) ?? '').trim();
    if (legacyUser.isNotEmpty) return legacyUser;
    return 'Unknown';
  }

  String? _buildAvatarUrl(SupabaseClient client, String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) return null;
    if (avatarPath.startsWith('http')) return avatarPath;
    return client.storage.from('avatars').getPublicUrl(avatarPath);
  }
}
