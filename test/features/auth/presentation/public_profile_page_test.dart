import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momen/features/auth/domain/entities/public_profile_post.dart';
import 'package:momen/features/auth/domain/entities/public_profile_view.dart';
import 'package:momen/features/auth/presentation/pages/public_profile_page.dart';
import 'package:momen/features/auth/presentation/state/friend_search_provider.dart';

void main() {
  Widget buildPage(PublicProfileView profile) {
    return ProviderScope(
      overrides: [
        publicProfileByIdProvider(profile.id).overrideWith(
          (ref) => Future.value(profile),
        ),
        publicProfilePostsProvider(profile.id).overrideWith(
          (ref) => Future.value(const <PublicProfilePost>[]),
        ),
      ],
      child: MaterialApp(
        home: PublicProfilePage(
          userId: profile.id,
          onBack: () {},
        ),
      ),
    );
  }

  testWidgets('shows Unfriend for accepted friendship', (tester) async {
    const profile = PublicProfileView(
      id: 'u1',
      fullName: 'Alice',
      isFriend: true,
      hasPendingOutgoing: false,
      hasPendingIncoming: false,
    );

    await tester.pumpWidget(buildPage(profile));
    await tester.pumpAndSettle();

    expect(find.text('Unfriend'), findsOneWidget);
  });

  testWidgets('shows Cancel request for outgoing pending', (tester) async {
    const profile = PublicProfileView(
      id: 'u2',
      fullName: 'Bob',
      isFriend: false,
      hasPendingOutgoing: true,
      hasPendingIncoming: false,
    );

    await tester.pumpWidget(buildPage(profile));
    await tester.pumpAndSettle();

    expect(find.text('Cancel request'), findsOneWidget);
  });

  testWidgets('shows Accept and Reject for incoming pending', (tester) async {
    const profile = PublicProfileView(
      id: 'u3',
      fullName: 'Charlie',
      isFriend: false,
      hasPendingOutgoing: false,
      hasPendingIncoming: true,
    );

    await tester.pumpWidget(buildPage(profile));
    await tester.pumpAndSettle();

    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
  });
}
