import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momen/features/auth/presentation/pages/onboarding_page.dart';

void main() {
  testWidgets(
      'Onboarding advances slides and triggers onComplete at final step', (
    tester,
  ) async {
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
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pump();

    expect(completeCalls, 1);
  });

  testWidgets('Onboarding sign up button triggers callback', (tester) async {
    var signUpCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(
          onComplete: () {},
          onSignUp: () => signUpCalls += 1,
        ),
      ),
    );

    await tester.tap(find.text('Create Account'));
    await tester.pump();

    expect(signUpCalls, 1);
  });
}
