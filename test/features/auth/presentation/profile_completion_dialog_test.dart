import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momen/features/auth/presentation/widgets/profile_completion_dialog.dart';

void main() {
  testWidgets('shows validation error when date of birth is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileCompletionDialog(
            onSubmit: ({
              required fullName,
              required userCode,
              required phone,
              required email,
              required dateOfBirth,
            }) async =>
                true,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'Kien');
    await tester.tap(find.text('Save & Continue'));
    await tester.pumpAndSettle();

    expect(
      find.text('Please fill in full name, ID, email, and date of birth.'),
      findsOneWidget,
    );
  });

  testWidgets('submits selected date from calendar picker', (tester) async {
    String? submittedName;
    String? submittedCode;
    String? submittedPhone;
    String? submittedEmail;
    DateTime? submittedDob;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileCompletionDialog(
            onSubmit: ({
              required fullName,
              required userCode,
              required phone,
              required email,
              required dateOfBirth,
            }) async {
              submittedName = fullName;
              submittedCode = userCode;
              submittedPhone = phone;
              submittedEmail = email;
              submittedDob = dateOfBirth;
              return true;
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'Kien Nguyen');
    await tester.enterText(find.byType(TextField).at(1), 'KIEN01');
    await tester.enterText(find.byType(TextField).at(2), '+84901234567');
    await tester.enterText(find.byType(TextField).at(3), 'kien@example.com');
    await tester.ensureVisible(
      find.byKey(const Key('profile_completion_dob_picker_button')),
    );
    await tester.tap(find.byKey(const Key('profile_completion_dob_picker_button')));
    await tester.pumpAndSettle();

    final okFinder = find.text('OK');
    if (okFinder.evaluate().isNotEmpty) {
      await tester.tap(okFinder.last);
    }
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save & Continue'));
    await tester.pumpAndSettle();

    expect(submittedName, 'Kien Nguyen');
    expect(submittedCode, 'KIEN01');
    expect(submittedPhone, '+84901234567');
    expect(submittedEmail, 'kien@example.com');
    expect(submittedDob, isNotNull);
  });
}
