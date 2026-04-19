import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momen/app/routing/app_route.dart';
import 'package:momen/app/routing/main_tab.dart';
import 'package:momen/core/components/cached_post_image.dart';
import 'package:momen/core/constants/app_sizes.dart';
import 'package:momen/core/observability/local_notification_service.dart';
import 'package:momen/core/providers/capture_preferences_provider.dart';
import 'package:momen/core/providers/theme_mode_provider.dart';
import 'package:momen/features/auth/presentation/pages/profile_page.dart';
import 'package:momen/features/feed/presentation/pages/camera_page.dart';
import 'package:momen/features/feed/presentation/pages/feed_money_page.dart';
import 'package:momen/features/recap/domain/entities/reveal_reminder.dart';
import 'package:momen/features/recap/presentation/pages/memories_page.dart';
import 'package:momen/core/providers/camera_provider.dart';
import 'package:momen/features/recap/presentation/state/memories_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({required this.tab, super.key});

  final MainTab tab;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _isRevealPromptOpen = false;

  static const List<MainTab> _visibleTabs = [
    MainTab.camera,
    MainTab.memories,
    MainTab.social,
    MainTab.profile,
  ];

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<RevealReminder>>>(
      revealReminderQueueProvider,
      (previous, next) {
        if (!mounted || _isRevealPromptOpen) return;
        final queue = next.asData?.value;
        if (queue == null || queue.isEmpty) return;

        for (final reminder in queue) {
          unawaited(
            LocalNotificationService.notifyRevealReminder(
              reminderId: reminder.reminderId,
              title: '3-day reveal reminder',
              body:
                  'Post from ${_formatDateTime(reminder.createdAt)} is ready. Swipe to reveal or keep anonymous.',
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _isRevealPromptOpen) return;
          _openRevealPrompt(queue.first);
        });
      },
    );

    ref.watch(cameraControllerProvider);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final showAmountInput = ref.watch(showAmountInputProvider);
    final selectedTabIndex = _visibleTabs.indexOf(widget.tab);

    final body = switch (widget.tab) {
      MainTab.memories => const MemoriesPage(),
      MainTab.social => const FeedMoneyPage(),
      MainTab.camera => CameraPage(
          showAmountInput: showAmountInput,
          onClose: () => _goToTab(context, MainTab.memories),
          onSwipeToMemories: () {
            ref.read(memoriesViewModeProvider.notifier).showStory();
            ref.read(focusedMemoryIndexProvider.notifier).setIndex(0);
            _goToTab(context, MainTab.memories);
          },
        ),
      MainTab.profile => ProfilePage(
          onEditProfile: () => context.goNamed(AppRoute.editProfile.name),
          isDarkMode: isDarkMode,
          showAmountInput: showAmountInput,
          onDarkModeChanged: (enabled) => ref
            .read(themeModeProvider.notifier)
            .setDarkMode(enabled),
          onShowAmountInputChanged: (enabled) => ref
            .read(showAmountInputProvider.notifier)
            .setShowAmountInput(enabled),
        ),
    };

    return Scaffold(
      body: SafeArea(child: body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTabIndex < 0 ? 0 : selectedTabIndex,
        onDestinationSelected: (index) => _goToTab(
          context,
          _visibleTabs[index],
        ),
        height: 72,
        destinations: const [
          NavigationDestination(
            icon: _CaptureNavIcon(),
            selectedIcon: _CaptureNavIcon(),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories),
            label: 'Memories',
          ),
          NavigationDestination(
            icon: Icon(Icons.dynamic_feed),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> _openRevealPrompt(RevealReminder reminder) async {
    _isRevealPromptOpen = true;

    final shouldReveal = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _RevealReminderSwipeDialog(
          reminder: reminder,
          onDecision: (reveal) => Navigator.of(dialogContext).pop(reveal),
        );
      },
    );

    if (!mounted) return;
    _isRevealPromptOpen = false;
    if (shouldReveal == null) return;

    try {
      await ref.read(revealReminderControllerProvider.notifier).decide(
            reminder: reminder,
            reveal: shouldReveal,
          );
      await LocalNotificationService.markReminderResolved(reminder.reminderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shouldReveal
                ? 'Post has been revealed to your friends.'
                : 'Post remains anonymous.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot save reveal decision: $error')),
      );
    }
  }

  void _goToTab(BuildContext context, MainTab tab) {
    context.goNamed(
      AppRoute.mainTab.name,
      pathParameters: tab.pathParameters,
    );
  }

  static String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString().padLeft(4, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _RevealReminderSwipeDialog extends StatelessWidget {
  const _RevealReminderSwipeDialog({
    required this.reminder,
    required this.onDecision,
  });

  final RevealReminder reminder;
  final ValueChanged<bool> onDecision;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
      child: Dismissible(
        key: ValueKey('reveal-reminder-${reminder.reminderId}'),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          onDecision(direction == DismissDirection.endToStart);
          return false;
        },
        background: _SwipeDecisionBackground(
          color: Colors.red.shade600,
          icon: Icons.visibility_off,
          text: 'Keep Anonymous',
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: _SwipeDecisionBackground(
          color: Colors.green.shade600,
          icon: Icons.visibility,
          text: 'Reveal Post',
          alignment: Alignment.centerRight,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.r16),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 260,
                  child: CachedPostImage(imageUrl: reminder.imageUrl),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSizes.p16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '3-day reminder',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSizes.p8),
                      Text(
                        'You posted this on ${_formatDateTime(reminder.createdAt)}. Reveal now?',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSizes.p8),
                      Text(
                        'Swipe left to reveal (green). Swipe right to keep anonymous (red).',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString().padLeft(4, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _SwipeDecisionBackground extends StatelessWidget {
  const _SwipeDecisionBackground({
    required this.color,
    required this.icon,
    required this.text,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final String text;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSizes.r16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: AppSizes.p8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureNavIcon extends StatelessWidget {
  const _CaptureNavIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: Color(0xFFFFD54F),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.add,
          color: Color(0xFF1F1F1F),
          size: 30,
        ),
      ),
    );
  }
}
