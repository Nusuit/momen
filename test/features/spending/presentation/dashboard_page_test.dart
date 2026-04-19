import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momen/features/spending/presentation/pages/dashboard_page.dart';

void main() {
  testWidgets('DashboardPage renders empty state before data loads', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: DashboardPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final emptyState = find.text(
      'No spending data yet. Submit posts with amount to populate this page.',
    );
    final loading = find.byType(CircularProgressIndicator);
    expect(
      emptyState.evaluate().isNotEmpty || loading.evaluate().isNotEmpty,
      isTrue,
    );
  });
}
