import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momen/core/components/cached_post_image.dart';
import 'package:momen/core/components/empty_state_card.dart';
import 'package:momen/core/constants/app_sizes.dart';
import 'package:momen/features/spending/domain/entities/spending_calendar_month.dart';
import 'package:momen/features/spending/presentation/state/spending_calendar_provider.dart';

class SpendingCalendarPage extends ConsumerWidget {
  const SpendingCalendarPage({required this.onOpenMoney, super.key});

  final Function(DateTime) onOpenMoney;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarAsync = ref.watch(spendingCalendarProvider);

    return calendarAsync.when(
      data: (months) {
        final hasAnyData = months.any((month) =>
            month.totalVnd > 0 || month.days.any((day) => day.postCount > 0));
        if (!hasAnyData) {
          return const Padding(
            padding: EdgeInsets.all(AppSizes.p16),
            child: EmptyStateCard(
              title:
                  'No calendar data yet. Capture posts to build your spending calendar.',
            ),
          );
        }

        return ListView.separated(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(
            AppSizes.p16,
            AppSizes.p8,
            AppSizes.p16,
            AppSizes.p24,
          ),
          itemCount: months.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSizes.p24),
          itemBuilder: (context, index) {
            return _MonthSection(
              month: months[index],
              onOpenMoney: onOpenMoney,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: Text('Cannot load calendar: $error'),
        ),
      ),
    );
  }
}

class _MonthSection extends StatelessWidget {
  const _MonthSection({required this.month, required this.onOpenMoney});

  final SpendingCalendarMonth month;
  final Function(DateTime) onOpenMoney;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(AppSizes.r16),
          onTap: () => onOpenMoney(month.monthStart),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p8,
              vertical: AppSizes.p4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatMonthYear(month.monthStart),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: AppSizes.p4),
                      Text(
                        'Total spent: ${_formatCompactAmount(month.totalVnd)}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p12),
        _WeekdayHeader(colorScheme: colorScheme),
        const SizedBox(height: AppSizes.p8),
        _MonthGrid(month: month),
      ],
    );
  }

  String _formatMonthYear(DateTime date) {
    final names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${names[date.month - 1]} ${date.year}';
  }

  String _formatCompactAmount(int amount) {
    if (amount <= 0) return '0k';
    final thousand = amount ~/ 1000;
    final remainder = amount % 1000;
    if (remainder == 0) {
      return '${_formatNumber(thousand)}k';
    }
    final decimal = (remainder / 100).round();
    return '${_formatNumber(thousand)}.${decimal}k';
  }

  String _formatNumber(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    const labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Center(
              child: Text(
                labels[i],
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: i >= 5
                          ? colorScheme.primary.withValues(alpha: 0.7)
                          : colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month});

  final SpendingCalendarMonth month;

  @override
  Widget build(BuildContext context) {
    final firstDay = month.monthStart;
    final leadingCells = (firstDay.weekday + 6) % 7;
    final visibleCells = month.days.length + leadingCells;
    final trailingCells = (7 - visibleCells % 7) % 7;
    final previousMonth = DateTime(firstDay.year, firstDay.month - 1, 1);
    final previousDays = DateTime(previousMonth.year, previousMonth.month + 1, 0).day;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: visibleCells + trailingCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: AppSizes.p8,
        mainAxisSpacing: AppSizes.p8,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        if (index < leadingCells || index >= visibleCells) {
          final day = index < leadingCells
              ? previousDays - (leadingCells - index) + 1
              : index - visibleCells + 1;
          return _PlaceholderDay(day: day);
        }

        final day = month.days[index - leadingCells];
        return _CalendarDayCell(day: day);
      },
    );
  }
}

class _PlaceholderDay extends StatelessWidget {
  const _PlaceholderDay({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        day.toString().padLeft(2, '0'),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.14),
            ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({required this.day});

  final SpendingCalendarDay day;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final hasImage = day.latestImageUrl != null && day.latestImageUrl!.isNotEmpty;
    final content = hasImage
        ? Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedPostImage(imageUrl: day.latestImageUrl!),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.p4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.scrim.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(AppSizes.r8),
                          ),
                          child: Text(
                            day.date.day.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 9,
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatCompactAmount(day.dailyTotalVnd),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                    ),
              ),
            ],
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                day.date.day.toString().padLeft(2, '0'),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: day.postCount > 0
                      ? colorScheme.primary.withValues(alpha: 0.45)
                      : colorScheme.onSurface.withValues(alpha: 0.15),
                ),
              ),
            ],
          );

    return GestureDetector(
      onTap: day.postCount > 0
          ? () => _openDayGallery(context, day.date)
          : null,
      child: content,
    );
  }

  String _formatCompactAmount(int amount) {
    if (amount <= 0) return '';
    final thousand = amount ~/ 1000;
    final remainder = amount % 1000;
    if (remainder == 0) {
      return '${_formatNumber(thousand)}k';
    }
    final decimal = (remainder / 100).round();
    return '${_formatNumber(thousand)}.${decimal}k';
  }

  String _formatNumber(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  Future<void> _openDayGallery(BuildContext context, DateTime date) async {
    await showDialog<void>(
      context: context,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.7),
      builder: (dialogContext) {
        return _DayGalleryDialog(date: date);
      },
    );
  }
}

class _DayGalleryDialog extends ConsumerWidget {
  const _DayGalleryDialog({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final postsAsync = ref.watch(spendingDayPostsProvider(date));

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p24),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(AppSizes.p24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSizes.r24),
              ),
              child: const Text('No photos for this day.'),
            );
          }

          return PageView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.r24),
                  child: Container(
                    color: colorScheme.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Image ─────────────────────────────────────────────
                        Expanded(
                          flex: 65,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedPostImage(
                                imageUrl: post.imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                              // Top gradient: Time + Back button
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                      AppSizes.p16, AppSizes.p12, AppSizes.p12, AppSizes.p32),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Color(0xB3000000), Color(0x00000000)],
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Material(
                                        color: Colors.white24,
                                        shape: const CircleBorder(),
                                        child: IconButton(
                                          iconSize: 20,
                                          color: Colors.white,
                                          onPressed: () => Navigator.of(context).pop(),
                                          icon: const Icon(Icons.arrow_back),
                                        ),
                                      ),
                                      const SizedBox(width: AppSizes.p12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _formatFullDate(post.createdAt),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                shadows: [
                                                  Shadow(color: Colors.black54, blurRadius: 8),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              _formatTime(post.createdAt),
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.8),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                shadows: const [
                                                  Shadow(color: Colors.black54, blurRadius: 4),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (posts.length > 1)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black38,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${index + 1}/${posts.length}',
                                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Info panel ────────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.fromLTRB(
                              AppSizes.p20, AppSizes.p16, AppSizes.p20, AppSizes.p24),
                          color: colorScheme.surface,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (post.amountVnd != null && post.amountVnd! > 0) ...[
                                Text(
                                  _formatLongAmount(post.amountVnd!),
                                  style: const TextStyle(
                                    color: Color(0xFFE8A234),
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: AppSizes.p8),
                              ],
                              if (post.caption.isNotEmpty)
                                Text(
                                  post.caption,
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                )
                              else
                                Text(
                                  'No caption',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Container(
          padding: const EdgeInsets.all(AppSizes.p24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSizes.r24),
          ),
          child: Text('Cannot load photos: $error'),
        ),
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatLongAmount(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final ri = s.length - i;
      buf.write(s[i]);
      if (ri > 1 && ri % 3 == 1) buf.write('.');
    }
    return '${buf.toString()} VND';
  }
}
