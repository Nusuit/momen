import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momen/features/auth/presentation/pages/onboarding_page.dart';

void main() {
  testWidgets(
      'Onboarding advances slides and triggers onComplete at final step', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    var completeCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(
          onComplete: () => completeCalls += 1,
          onSignUp: () {},
        ),
      ),
    );

    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pump();

    expect(completeCalls, 1);
  });

  testWidgets('Onboarding sign up button triggers callback', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    var signUpCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(
          onComplete: () {},
          onSignUp: () => signUpCalls += 1,
        ),
      ),
    );

    await tester.tap(find.text('Get Started'));
    await tester.pump();

    expect(signUpCalls, 1);
  });
}
