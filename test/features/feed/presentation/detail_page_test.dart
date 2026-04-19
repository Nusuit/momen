import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momen/core/models/memory_item.dart';
import 'package:momen/features/feed/presentation/pages/detail_page.dart';

void main() {
  testWidgets('DetailPage shows fallback when memory is null', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DetailPage(
          memory: null,
          onBack: () {},
        ),
      ),
    );

    expect(find.text('No memory selected'), findsOneWidget);
  });

  testWidgets('DetailPage renders memory details', (tester) async {
    const memory = MemoryItem(
      day: 5,
      amount: '890k',
      category: 'Shopping',
      alias: 'MoonFox',
      caption: 'Dinner with friends',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DetailPage(
          memory: memory,
          onBack: () {},
        ),
      ),
    );

    expect(find.text('Alias: MoonFox'), findsOneWidget);
    expect(find.text('Dinner with friends'), findsOneWidget);
    expect(find.text('890k'), findsOneWidget);
    expect(find.text('Category: Shopping | Day 5'), findsOneWidget);
  });
}
