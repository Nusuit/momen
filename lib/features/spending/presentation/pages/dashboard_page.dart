import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momen/core/components/empty_state_card.dart';
import 'package:momen/core/constants/app_sizes.dart';
import 'package:momen/features/spending/presentation/state/spending_summary_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({this.month, super.key});

  final DateTime? month;

  String _formatAmount(int amount) {
    final value = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final reverseIndex = value.length - i;
      buffer.write(value[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return '${buffer.toString()} VND';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(spendingSummaryProvider(month));

    return summaryAsync.when(
      data: (summary) {
        if (summary.entriesWithAmount == 0) {
          return const Padding(
            padding: EdgeInsets.all(AppSizes.p16),
            child: EmptyStateCard(
              title:
                  'No spending data yet. Submit posts with amount to populate this page.',
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSizes.p16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      month == null
                          ? 'This month'
                          : 'Month ${month!.month}/${month!.year}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: AppSizes.p8),
                    Text(
                      _formatAmount(summary.monthlyTotalVnd),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p12),
            Card(
              child: ListTile(
                title: const Text('Today'),
                subtitle: Text(_formatAmount(summary.todayTotalVnd)),
              ),
            ),
            const SizedBox(height: AppSizes.p12),
            Card(
              child: ListTile(
                title: const Text('Posts with amount'),
                subtitle: Text('${summary.entriesWithAmount} posts'),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: Text('Cannot load dashboard: $error'),
        ),
      ),
    );
  }
}
