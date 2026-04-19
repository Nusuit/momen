import 'package:flutter_test/flutter_test.dart';
import 'package:momen/app.dart';

Future<void> _goToSignIn(WidgetTester tester) async {
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Get Started'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('MomenApp starts at onboarding when unauthenticated', (tester) async {
    await tester.pumpWidget(const MomenApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Capture spending through the lens'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Onboarding routes to sign in and sign up', (tester) async {
    await tester.pumpWidget(const MomenApp());
    await tester.pump(const Duration(milliseconds: 300));

    await _goToSignIn(tester);

    expect(find.text('Welcome back, Curator'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('Forgot password screen is reachable from sign in', (tester) async {
    await tester.pumpWidget(const MomenApp());
    await tester.pump(const Duration(milliseconds: 300));

    await _goToSignIn(tester);

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot Password'), findsOneWidget);
    expect(find.text('Send Reset Email'), findsOneWidget);
  });
}
