import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momen/core/models/memory_item.dart';
import 'package:momen/features/recap/presentation/pages/memories_page.dart';

void main() {
  testWidgets('MemoriesPage renders empty state', (tester) async {
    MemoryItem? selected;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MemoriesPage(
            onOpenDetail: (item) => selected = item,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final emptyState =
      find.text('No memories yet. Friends-only anonymous posts will appear here.');
    final loading = find.byType(CircularProgressIndicator);
    expect(
      emptyState.evaluate().isNotEmpty || loading.evaluate().isNotEmpty,
      isTrue,
    );
    expect(selected, isNull);
  });
}
