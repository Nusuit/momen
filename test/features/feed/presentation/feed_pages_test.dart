import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momen/features/feed/presentation/pages/camera_page.dart';
import 'package:momen/features/feed/presentation/pages/feed_page.dart';

void main() {
  testWidgets('FeedPage renders empty state', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FeedPage()));

    expect(
      find.text('Feed is empty. Connect database to load posts.'),
      findsOneWidget,
    );
  });

  testWidgets('CameraPage renders capture controls', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: CameraPage(
            onClose: () {},
            showAmountInput: true,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('camera_close_button')), findsOneWidget);
    expect(find.byKey(const Key('camera_gallery_button')), findsOneWidget);
    expect(find.byKey(const Key('camera_capture_button')), findsOneWidget);
    expect(find.byKey(const Key('camera_switch_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('camera_gallery_button')));
    await tester.tap(find.byKey(const Key('camera_capture_button')));
    await tester.tap(find.byKey(const Key('camera_switch_button')));
    await tester.tap(find.byKey(const Key('camera_close_button')));
    await tester.pump();
  });
}
