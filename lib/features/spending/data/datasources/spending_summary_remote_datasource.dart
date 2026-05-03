import 'package:momen/features/spending/domain/entities/spending_calendar_month.dart';
import 'package:momen/features/spending/domain/entities/spending_day_post.dart';
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

  Future<List<SpendingCalendarMonth>> getCalendarMonths() async {
    final client = _client;
    if (client == null) {
      return _buildEmptyCalendarMonths(
        monthCount: _monthsBetween(_currentMonthStart(), _currentMonthStart()) + 1,
        monthStart: _currentMonthStart(),
      );
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return _buildEmptyCalendarMonths(
        monthCount: _monthsBetween(_currentMonthStart(), _currentMonthStart()) + 1,
        monthStart: _currentMonthStart(),
      );
    }

    final currentMonthStart = _currentMonthStart();
    final accountStart = await _getAccountStart(client, user.id) ?? currentMonthStart;
    final accountMonthStart = DateTime(accountStart.year, accountStart.month, 1);
    final monthCount = _monthsBetween(accountMonthStart, currentMonthStart) + 1;
    final queryStart = accountMonthStart;

    final rows = await client
        .from('posts')
        .select('image_path,amount_vnd,created_at')
        .eq('user_id', user.id)
        .gte('created_at', queryStart.toIso8601String())
        .order('created_at', ascending: false);

    final monthBuckets = <DateTime, _MonthBucket>{};
    final dayBuckets = <DateTime, _DayBucket>{};

    for (var i = 0; i < monthCount; i++) {
      final monthStart = DateTime(currentMonthStart.year, currentMonthStart.month - i, 1);
      monthBuckets[monthStart] = _MonthBucket(monthStart: monthStart);

      final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
      for (var day = 1; day <= daysInMonth; day++) {
        final date = DateTime(monthStart.year, monthStart.month, day);
        dayBuckets[date] = _DayBucket(date: date);
      }
    }

    for (final row in rows) {
      final createdAt = DateTime.tryParse((row['created_at'] as String?) ?? '');
      if (createdAt == null) {
        continue;
      }

      final date = DateTime(createdAt.year, createdAt.month, createdAt.day);
      final monthStart = DateTime(createdAt.year, createdAt.month, 1);
      final dayBucket = dayBuckets[date];
      final monthBucket = monthBuckets[monthStart];
      if (dayBucket == null || monthBucket == null) {
        continue;
      }

      dayBucket.postCount += 1;

      final amount = row['amount_vnd'] as int?;
      if (amount != null) {
        dayBucket.dailyTotalVnd += amount;
        monthBucket.totalVnd += amount;
      }

      if (dayBucket.latestImageUrl == null) {
        final imagePath = (row['image_path'] as String?) ?? '';
        if (imagePath.isNotEmpty) {
          dayBucket.latestImageUrl = imagePath.startsWith('http')
              ? imagePath
              : client.storage.from('post_images').getPublicUrl(imagePath);
        }
      }
    }

    final result = monthBuckets.values.map((monthBucket) {
      final days = dayBuckets.values
          .where((day) => day.date.year == monthBucket.monthStart.year && day.date.month == monthBucket.monthStart.month)
          .toList(growable: false)
        ..sort((a, b) => a.date.compareTo(b.date));

      return SpendingCalendarMonth(
        monthStart: monthBucket.monthStart,
        totalVnd: monthBucket.totalVnd,
        days: days
            .map(
              (day) => SpendingCalendarDay(
                date: day.date,
                dailyTotalVnd: day.dailyTotalVnd,
                latestImageUrl: day.latestImageUrl,
                postCount: day.postCount,
              ),
            )
            .toList(growable: false),
      );
    }).toList(growable: false)
      ..sort((a, b) => b.monthStart.compareTo(a.monthStart));

    return result;
  }

  Future<List<SpendingDayPost>> getDayPosts(DateTime date) async {
    final client = _client;
    if (client == null) return const [];
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final rows = await client
        .from('posts')
        .select('id,image_path,amount_vnd,caption,created_at')
        .eq('user_id', user.id)
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String())
        .order('created_at', ascending: false);

    return rows
        .map((row) {
          final imagePath = (row['image_path'] as String?) ?? '';
          if (imagePath.isEmpty) {
            return null;
          }
          final imageUrl = imagePath.startsWith('http')
              ? imagePath
              : client.storage.from('post_images').getPublicUrl(imagePath);
          return SpendingDayPost(
            id: (row['id'] as String?) ?? '',
            imageUrl: imageUrl,
            caption: (row['caption'] as String?) ?? '',
            amountVnd: row['amount_vnd'] as int?,
            createdAt: DateTime.tryParse((row['created_at'] as String?) ?? '') ??
                DateTime.now(),
          );
        })
        .whereType<SpendingDayPost>()
        .toList(growable: false);
  }

  List<SpendingCalendarMonth> _buildEmptyCalendarMonths({
    required int monthCount,
    required DateTime monthStart,
  }) {
    return List.generate(monthCount, (index) {
      final targetMonth = DateTime(monthStart.year, monthStart.month - index, 1);
      final daysInMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
      final days = List.generate(daysInMonth, (dayIndex) {
        return SpendingCalendarDay(
          date: DateTime(targetMonth.year, targetMonth.month, dayIndex + 1),
          dailyTotalVnd: 0,
          latestImageUrl: null,
          postCount: 0,
        );
      });

      return SpendingCalendarMonth(
        monthStart: targetMonth,
        totalVnd: 0,
        days: days,
      );
    });
  }

  DateTime _currentMonthStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  int _monthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month);
  }

  Future<DateTime?> _getAccountStart(SupabaseClient client, String userId) async {
    try {
      final row = await client
          .from('profiles')
          .select('created_at')
          .eq('id', userId)
          .maybeSingle();
      final createdAt = DateTime.tryParse((row?['created_at'] as String?) ?? '');
      return createdAt;
    } catch (_) {
      return null;
    }
  }
}

class _MonthBucket {
  _MonthBucket({required this.monthStart});

  final DateTime monthStart;
  int totalVnd = 0;
}

class _DayBucket {
  _DayBucket({required this.date});

  final DateTime date;
  int dailyTotalVnd = 0;
  int postCount = 0;
  String? latestImageUrl;
}