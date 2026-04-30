import 'package:momen/features/auth/data/datasources/friend_search_remote_datasource.dart';
import 'package:momen/features/auth/domain/entities/friend_profile.dart';
import 'package:momen/features/auth/domain/entities/nearby_user_profile.dart';
import 'package:momen/features/auth/domain/entities/public_profile_post.dart';
import 'package:momen/features/auth/domain/entities/friend_request.dart';
import 'package:momen/features/auth/domain/entities/public_profile_view.dart';
import 'package:momen/features/auth/domain/repositories/friend_search_repository.dart';

class FriendSearchRepositoryImpl implements FriendSearchRepository {
  const FriendSearchRepositoryImpl(this._remoteDataSource);

  final FriendSearchRemoteDataSource _remoteDataSource;

  @override
  Future<List<FriendProfile>> search(String query) =>
      _remoteDataSource.search(query);

  @override
  Future<int> getFriendCount() => _remoteDataSource.getFriendCount();

  @override
  Future<void> sendFriendRequest(String addresseeId) =>
      _remoteDataSource.sendFriendRequest(addresseeId);

  @override
  Future<List<FriendRequest>> getIncomingRequests() =>
      _remoteDataSource.getIncomingRequests();

  @override
  Future<void> respondToFriendRequest({
    required String requesterId,
    required bool accept,
    bool shareHistory = false,
  }) =>
      _remoteDataSource.respondToFriendRequest(
        requesterId: requesterId,
        accept: accept,
        shareHistory: shareHistory,
      );

  @override
  Future<PublicProfileView?> getPublicProfileById(String userId) =>
      _remoteDataSource.getPublicProfileById(userId);

  @override
  Future<List<PublicProfilePost>> getPublicProfilePosts(String userId) =>
      _remoteDataSource.getPublicProfilePosts(userId);

  @override
  Future<void> removeFriendship(String targetUserId) =>
      _remoteDataSource.removeFriendship(targetUserId);

  @override
  Future<List<NearbyUserProfile>> getNearbyUsers({
    required double lat,
    required double lon,
    int radiusM = 5000,
  }) =>
      _remoteDataSource.getNearbyUsers(lat: lat, lon: lon, radiusM: radiusM);

  @override
  Future<List<FriendProfile>> getContactMatches(List<String> phoneHashes) =>
      _remoteDataSource.getContactMatches(phoneHashes);

  @override
  Future<void> blockUser(String targetUserId) =>
      _remoteDataSource.blockUser(targetUserId);

  @override
  Future<void> reportUser({
    required String targetUserId,
    required String reason,
  }) =>
      _remoteDataSource.reportUser(
          targetUserId: targetUserId, reason: reason);

  @override
  Future<void> updateLocation({required double lat, required double lon}) =>
      _remoteDataSource.updateLocation(lat: lat, lon: lon);
}
