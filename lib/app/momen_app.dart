import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momen/app/routing/app_router.dart';
import 'package:momen/core/constants/app_theme.dart';
import 'package:momen/core/providers/theme_mode_provider.dart';

class MomenApp extends StatelessWidget {
  const MomenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _MomenMaterialApp());
  }
}

class _MomenMaterialApp extends ConsumerWidget {
  const _MomenMaterialApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Momen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
