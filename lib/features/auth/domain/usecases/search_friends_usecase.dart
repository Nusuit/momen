import 'package:momen/features/auth/domain/entities/friend_profile.dart';
import 'package:momen/features/auth/domain/entities/nearby_user_profile.dart';
import 'package:momen/features/auth/domain/entities/public_profile_post.dart';
import 'package:momen/features/auth/domain/entities/friend_request.dart';
import 'package:momen/features/auth/domain/entities/public_profile_view.dart';
import 'package:momen/features/auth/domain/repositories/friend_search_repository.dart';

class SearchFriendsUseCase {
  const SearchFriendsUseCase(this._repository);
  final FriendSearchRepository _repository;
  Future<List<FriendProfile>> call(String query) => _repository.search(query);
}

class GetFriendCountUseCase {
  const GetFriendCountUseCase(this._repository);
  final FriendSearchRepository _repository;
  Future<int> call() => _repository.getFriendCount();
}

class SendFriendRequestUseCase {
  const SendFriendRequestUseCase(this._repository);
  final FriendSearchRepository _repository;
  Future<void> call(String addresseeId) => _repository.sendFriendRequest(addresseeId);
}

class GetIncomingFriendRequestsUseCase {
  const GetIncomingFriendRequestsUseCase(this._repository);
  final FriendSearchRepository _repository;
  Future<List<FriendRequest>> call() => _repository.getIncomingRequests();
}

class RespondToFriendRequestUseCase {
  const RespondToFriendRequestUseCase(this._repository);
  final FriendSearchRepository _repository;
  Future<void> call({
    required String requesterId, 
    required bool accept,
    bool shareHistory = false,
  }) =>
      _repository.respondToFriendRequest(
        requesterId: requesterId, 
        accept: accept,
        shareHistory: shareHistory,
      );
}

class GetPublicProfileByIdUseCase {
  const GetPublicProfileByIdUseCase(this._repository);
  final FriendSearchRepository _repository;
  Future<PublicProfileView?> call(String userId) => _repository.getPublicProfileById(userId);
}

class RemoveFriendshipUseCase {
  const RemoveFriendshipUseCase(this._repository);
  final FriendSearchRepository _repository;
  Future<void> call(String targetUserId) => _repository.removeFriendship(targetUserId);
}

class GetPublicProfilePostsUseCase {
  const GetPublicProfilePostsUseCase(this._repository);
  final FriendSearchRepository _repository;
  Future<List<PublicProfilePost>> call(String userId) =>
      _repository.getPublicProfilePosts(userId);
}

class GetNearbyUsersUseCase {
  const GetNearbyUsersUseCase(this._repository);
  final FriendSearchRepository _repository;
  Future<List<NearbyUserProfile>> call({
    required double lat,
    required double lon,
    int radiusM = 5000,
  }) =>
      _repository.getNearbyUsers(lat: lat, lon: lon, radiusM: radiusM);
}

class GetContactMatchesUseCase {
  const GetContactMatchesUseCase(this._repository);
  final FriendSearchRepository _repository;
  Future<List<FriendProfile>> call(List<String> phoneHashes) =>
      _repository.getContactMatches(phoneHashes);
}

class BlockUserUseCase {
  const BlockUserUseCase(this._repository);
  final FriendSearchRepository _repository;
  Future<void> call(String targetUserId) => _repository.blockUser(targetUserId);
}

class ReportUserUseCase {
  const ReportUserUseCase(this._repository);
  final FriendSearchRepository _repository;
  Future<void> call({required String targetUserId, required String reason}) =>
      _repository.reportUser(targetUserId: targetUserId, reason: reason);
}

class UpdateLocationUseCase {
  const UpdateLocationUseCase(this._repository);
  final FriendSearchRepository _repository;
  Future<void> call({required double lat, required double lon}) =>
      _repository.updateLocation(lat: lat, lon: lon);
}
