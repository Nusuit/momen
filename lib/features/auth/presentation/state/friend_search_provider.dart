import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momen/core/providers/core_providers.dart';
import 'package:momen/features/auth/data/datasources/friend_search_remote_datasource.dart';
import 'package:momen/features/auth/data/repositories_impl/friend_search_repository_impl.dart';
import 'package:momen/features/auth/domain/entities/friend_profile.dart';
import 'package:momen/features/auth/domain/entities/nearby_user_profile.dart';
import 'package:momen/features/auth/domain/entities/public_profile_post.dart';
import 'package:momen/features/auth/domain/entities/friend_request.dart';
import 'package:momen/features/auth/domain/entities/public_profile_view.dart';
import 'package:momen/features/auth/domain/usecases/search_friends_usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

final _friendSearchRemoteDataSourceProvider =
    Provider<FriendSearchRemoteDataSource>(
  (ref) => FriendSearchRemoteDataSource(ref.watch(supabaseClientProvider)),
);

final _friendSearchRepositoryProvider = Provider<FriendSearchRepositoryImpl>(
  (ref) => FriendSearchRepositoryImpl(
      ref.watch(_friendSearchRemoteDataSourceProvider)),
);

final _searchFriendsUseCaseProvider = Provider<SearchFriendsUseCase>(
  (ref) => SearchFriendsUseCase(ref.watch(_friendSearchRepositoryProvider)),
);

final _getFriendCountUseCaseProvider = Provider<GetFriendCountUseCase>(
  (ref) => GetFriendCountUseCase(ref.watch(_friendSearchRepositoryProvider)),
);

final _sendFriendRequestUseCaseProvider = Provider<SendFriendRequestUseCase>(
  (ref) =>
      SendFriendRequestUseCase(ref.watch(_friendSearchRepositoryProvider)),
);

final _getIncomingFriendRequestsUseCaseProvider =
    Provider<GetIncomingFriendRequestsUseCase>(
  (ref) => GetIncomingFriendRequestsUseCase(
      ref.watch(_friendSearchRepositoryProvider)),
);

final _respondToFriendRequestUseCaseProvider =
    Provider<RespondToFriendRequestUseCase>(
  (ref) => RespondToFriendRequestUseCase(
      ref.watch(_friendSearchRepositoryProvider)),
);

final _getPublicProfileByIdUseCaseProvider =
    Provider<GetPublicProfileByIdUseCase>(
  (ref) => GetPublicProfileByIdUseCase(
      ref.watch(_friendSearchRepositoryProvider)),
);

final _removeFriendshipUseCaseProvider = Provider<RemoveFriendshipUseCase>(
  (ref) =>
      RemoveFriendshipUseCase(ref.watch(_friendSearchRepositoryProvider)),
);

final _getPublicProfilePostsUseCaseProvider =
    Provider<GetPublicProfilePostsUseCase>(
  (ref) => GetPublicProfilePostsUseCase(
      ref.watch(_friendSearchRepositoryProvider)),
);

final _getNearbyUsersUseCaseProvider = Provider<GetNearbyUsersUseCase>(
  (ref) => GetNearbyUsersUseCase(ref.watch(_friendSearchRepositoryProvider)),
);

final _getContactMatchesUseCaseProvider = Provider<GetContactMatchesUseCase>(
  (ref) => GetContactMatchesUseCase(ref.watch(_friendSearchRepositoryProvider)),
);

final _blockUserUseCaseProvider = Provider<BlockUserUseCase>(
  (ref) => BlockUserUseCase(ref.watch(_friendSearchRepositoryProvider)),
);

final _reportUserUseCaseProvider = Provider<ReportUserUseCase>(
  (ref) => ReportUserUseCase(ref.watch(_friendSearchRepositoryProvider)),
);

final _updateLocationUseCaseProvider = Provider<UpdateLocationUseCase>(
  (ref) =>
      UpdateLocationUseCase(ref.watch(_friendSearchRepositoryProvider)),
);

// ─── Search ───────────────────────────────────────────────────────────────────

final friendSearchQueryProvider =
    NotifierProvider.autoDispose<FriendSearchQueryController, String>(
  FriendSearchQueryController.new,
);

class FriendSearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
}

final friendSearchResultsProvider =
    FutureProvider.autoDispose<List<FriendProfile>>((ref) {
  final query = ref.watch(friendSearchQueryProvider).trim();
  if (query.isEmpty) return Future.value(const []);
  return ref.watch(_searchFriendsUseCaseProvider).call(query);
});

// ─── Nearby ───────────────────────────────────────────────────────────────────

class NearbySearchParams {
  const NearbySearchParams({required this.lat, required this.lon});
  final double lat;
  final double lon;

  @override
  bool operator ==(Object other) =>
      other is NearbySearchParams && other.lat == lat && other.lon == lon;

  @override
  int get hashCode => Object.hash(lat, lon);
}

final nearbyUsersProvider =
    FutureProvider.autoDispose.family<List<NearbyUserProfile>, NearbySearchParams>(
  (ref, params) => ref
      .watch(_getNearbyUsersUseCaseProvider)
      .call(lat: params.lat, lon: params.lon),
);

// ─── Contacts ─────────────────────────────────────────────────────────────────

final contactMatchesProvider =
    FutureProvider.autoDispose.family<List<FriendProfile>, List<String>>(
  (ref, phoneHashes) =>
      ref.watch(_getContactMatchesUseCaseProvider).call(phoneHashes),
);

// ─── Friend count ─────────────────────────────────────────────────────────────

final friendCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(_getFriendCountUseCaseProvider).call(),
);

// ─── Incoming requests (with Realtime refresh) ────────────────────────────────

final incomingFriendRequestsProvider =
    FutureProvider.autoDispose<List<FriendRequest>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client != null) {
    final userId = client.auth.currentUser?.id;
    if (userId != null) {
      final channel = client.channel('incoming_requests_$userId');
      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'friendships',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'addressee_id',
              value: userId,
            ),
            callback: (_) => ref.invalidateSelf(),
          )
          .subscribe();
      ref.onDispose(() => client.removeChannel(channel));
    }
  }
  return ref.watch(_getIncomingFriendRequestsUseCaseProvider).call();
});

// ─── Friend request controller ────────────────────────────────────────────────

final friendRequestPendingIdsProvider =
    NotifierProvider.autoDispose<FriendRequestController, Set<String>>(
  FriendRequestController.new,
);

class FriendRequestController extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  Future<void> sendRequest(String addresseeId) async {
    if (state.contains(addresseeId)) return;
    state = {...state, addresseeId};
    try {
      await ref.read(_sendFriendRequestUseCaseProvider).call(addresseeId);
      ref.invalidate(friendCountProvider);
    } finally {
      final next = {...state}..remove(addresseeId);
      state = next;
    }
  }

  Future<void> respondToRequest({
    required String requesterId,
    required bool accept,
  }) async {
    final actionKey = '${accept ? 'accept' : 'reject'}:$requesterId';
    if (state.contains(actionKey)) return;
    state = {...state, actionKey};
    try {
      await ref
          .read(_respondToFriendRequestUseCaseProvider)
          .call(requesterId: requesterId, accept: accept);
      ref.invalidate(friendCountProvider);
      ref.invalidate(incomingFriendRequestsProvider);
    } finally {
      final next = {...state}..remove(actionKey);
      state = next;
    }
  }

  Future<void> removeFriendship(String targetUserId) async {
    final actionKey = 'remove:$targetUserId';
    if (state.contains(actionKey)) return;
    state = {...state, actionKey};
    try {
      await ref.read(_removeFriendshipUseCaseProvider).call(targetUserId);
      ref.invalidate(friendCountProvider);
      ref.invalidate(incomingFriendRequestsProvider);
    } finally {
      final next = {...state}..remove(actionKey);
      state = next;
    }
  }

  Future<void> blockUser(String targetUserId) async {
    final actionKey = 'block:$targetUserId';
    if (state.contains(actionKey)) return;
    state = {...state, actionKey};
    try {
      await ref.read(_blockUserUseCaseProvider).call(targetUserId);
      // Also remove friendship if any
      await ref
          .read(_removeFriendshipUseCaseProvider)
          .call(targetUserId)
          .catchError((_) {});
      ref.invalidate(friendCountProvider);
    } finally {
      final next = {...state}..remove(actionKey);
      state = next;
    }
  }

  Future<void> reportUser({
    required String targetUserId,
    required String reason,
  }) async {
    await ref
        .read(_reportUserUseCaseProvider)
        .call(targetUserId: targetUserId, reason: reason);
  }

  Future<void> updateLocation({
    required double lat,
    required double lon,
  }) async {
    await ref
        .read(_updateLocationUseCaseProvider)
        .call(lat: lat, lon: lon);
  }
}

// ─── Public profile ───────────────────────────────────────────────────────────

final publicProfileByIdProvider =
    FutureProvider.autoDispose
        .family<PublicProfileView?, String>((ref, userId) {
  return ref.watch(_getPublicProfileByIdUseCaseProvider).call(userId);
});

final publicProfilePostsProvider =
    FutureProvider.autoDispose
        .family<List<PublicProfilePost>, String>((ref, userId) {
  return ref.watch(_getPublicProfilePostsUseCaseProvider).call(userId);
});
