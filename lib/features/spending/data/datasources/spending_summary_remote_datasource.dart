import 'package:momen/features/spending/domain/entities/spending_summary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SpendingSummaryRemoteDataSource {
  const SpendingSummaryRemoteDataSource(this._client);

  final SupabaseClient? _client;

  Future<SpendingSummary> getSummary() async {
    final client = _client;
    if (client == null) {
      return const SpendingSummary(
        monthlyTotalVnd: 0,
        todayTotalVnd: 0,
        entriesWithAmount: 0,
      );
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return const SpendingSummary(
        monthlyTotalVnd: 0,
        todayTotalVnd: 0,
        entriesWithAmount: 0,
      );
    }

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final dayStart = DateTime(now.year, now.month, now.day);

    final monthRows = await client
        .from('posts')
        .select('amount_vnd,created_at')
        .eq('user_id', user.id)
        .gte('created_at', monthStart.toIso8601String());

    var monthlyTotal = 0;
    var todayTotal = 0;
    var entries = 0;

    for (final row in monthRows) {
      final amount = row['amount_vnd'] as int?;
      if (amount == null) {
        continue;
      }

      entries += 1;
      monthlyTotal += amount;

      final createdAt = DateTime.tryParse((row['created_at'] as String?) ?? '');
      if (createdAt != null && !createdAt.isBefore(dayStart)) {
        todayTotal += amount;
      }
    }

    return SpendingSummary(
      monthlyTotalVnd: monthlyTotal,
      todayTotalVnd: todayTotal,
      entriesWithAmount: entries,
    );
  }
}