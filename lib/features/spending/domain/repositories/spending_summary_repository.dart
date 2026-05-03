import 'package:momen/features/spending/domain/entities/spending_calendar_month.dart';
import 'package:momen/features/spending/domain/entities/spending_day_post.dart';
import 'package:momen/features/spending/domain/entities/spending_summary.dart';

abstract class SpendingSummaryRepository {
  Future<SpendingSummary> getSummary();

  Future<List<SpendingCalendarMonth>> getCalendarMonths();

  Future<List<SpendingDayPost>> getDayPosts(DateTime date);
}