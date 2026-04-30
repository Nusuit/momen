import 'package:momen/features/auth/domain/entities/friend_profile.dart';
import 'package:momen/features/auth/domain/entities/nearby_user_profile.dart';
import 'package:momen/features/auth/domain/entities/public_profile_post.dart';
import 'package:momen/features/auth/domain/entities/friend_request.dart';
import 'package:momen/features/auth/domain/entities/public_profile_view.dart';

abstract class FriendSearchRepository {
  Future<List<FriendProfile>> search(String query);

  Future<int> getFriendCount();

  Future<void> sendFriendRequest(String addresseeId);

  Future<List<FriendRequest>> getIncomingRequests();

  Future<void> respondToFriendRequest({
    required String requesterId,
    required bool accept,
    bool shareHistory = false,
  });

  Future<PublicProfileView?> getPublicProfileById(String userId);

  Future<List<PublicProfilePost>> getPublicProfilePosts(String userId);

  Future<void> removeFriendship(String targetUserId);

  Future<List<NearbyUserProfile>> getNearbyUsers({
    required double lat,
    required double lon,
    int radiusM = 5000,
  });

  Future<List<FriendProfile>> getContactMatches(List<String> phoneHashes);

  Future<void> blockUser(String targetUserId);

  Future<void> reportUser({
    required String targetUserId,
    required String reason,
  });

  Future<void> updateLocation({
    required double lat,
    required double lon,
  });
}
