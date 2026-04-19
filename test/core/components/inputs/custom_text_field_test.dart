import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momen/core/components/inputs/custom_text_field.dart';

void main() {
  testWidgets('CustomTextField renders label and hint text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            label: 'EMAIL',
            hintText: 'you@example.com',
          ),
        ),
      ),
    );

    expect(find.text('EMAIL'), findsOneWidget);
    expect(find.text('you@example.com'), findsOneWidget);
  });

  testWidgets('CustomTextField applies obscureText', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            label: 'PASSWORD',
            hintText: 'Enter password',
            obscureText: true,
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.obscureText, isTrue);
  });
}
