import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momen/features/auth/domain/entities/friend_profile.dart';
import 'package:momen/features/auth/domain/entities/friend_request.dart';
import 'package:momen/features/auth/domain/entities/public_profile_view.dart';
import 'package:momen/features/auth/domain/repositories/friend_search_repository.dart';
import 'package:momen/features/auth/domain/usecases/search_friends_usecase.dart';

class _MockFriendSearchRepository extends Mock implements FriendSearchRepository {}

void main() {
  late _MockFriendSearchRepository repository;

  setUp(() {
    repository = _MockFriendSearchRepository();
  });

  test('GetIncomingFriendRequestsUseCase returns repository data', () async {
    const requests = [
      FriendRequest(requesterId: 'u1', fullName: 'Alice'),
    ];

    when(() => repository.getIncomingRequests())
        .thenAnswer((_) async => requests);

    final useCase = GetIncomingFriendRequestsUseCase(repository);
    final result = await useCase.call();

    expect(result, requests);
    verify(() => repository.getIncomingRequests()).called(1);
  });

  test('RespondToFriendRequestUseCase forwards accept action', () async {
    when(
      () => repository.respondToFriendRequest(
        requesterId: 'u2',
        accept: true,
      ),
    ).thenAnswer((_) async {});

    final useCase = RespondToFriendRequestUseCase(repository);
    await useCase.call(requesterId: 'u2', accept: true);

    verify(
      () => repository.respondToFriendRequest(
        requesterId: 'u2',
        accept: true,
      ),
    ).called(1);
  });

  test('GetPublicProfileByIdUseCase returns nullable profile', () async {
    const profile = PublicProfileView(
      id: 'u3',
      fullName: 'Bob',
      isFriend: false,
      hasPendingOutgoing: true,
      hasPendingIncoming: false,
    );

    when(() => repository.getPublicProfileById('u3'))
        .thenAnswer((_) async => profile);

    final useCase = GetPublicProfileByIdUseCase(repository);
    final result = await useCase.call('u3');

    expect(result, profile);
    verify(() => repository.getPublicProfileById('u3')).called(1);
  });

  test('RemoveFriendshipUseCase forwards target id', () async {
    when(() => repository.removeFriendship('u4')).thenAnswer((_) async {});

    final useCase = RemoveFriendshipUseCase(repository);
    await useCase.call('u4');

    verify(() => repository.removeFriendship('u4')).called(1);
  });

  test('SearchFriendsUseCase still works after contract expansion', () async {
    const friends = [
      FriendProfile(id: 'u5', fullName: 'Linh'),
    ];
    when(() => repository.search('linh')).thenAnswer((_) async => friends);

    final useCase = SearchFriendsUseCase(repository);
    final result = await useCase.call('linh');

    expect(result, friends);
    verify(() => repository.search('linh')).called(1);
  });
}
