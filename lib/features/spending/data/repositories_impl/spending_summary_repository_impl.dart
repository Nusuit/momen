import 'package:momen/features/spending/data/datasources/spending_summary_remote_datasource.dart';
import 'package:momen/features/spending/domain/entities/spending_calendar_month.dart';
import 'package:momen/features/spending/domain/entities/spending_day_post.dart';
import 'package:momen/features/spending/domain/entities/spending_summary.dart';
import 'package:momen/features/spending/domain/repositories/spending_summary_repository.dart';

class SpendingSummaryRepositoryImpl implements SpendingSummaryRepository {
  const SpendingSummaryRepositoryImpl(this._remoteDataSource);

  final SpendingSummaryRemoteDataSource _remoteDataSource;

  @override
  Future<SpendingSummary> getSummary() {
    return _remoteDataSource.getSummary();
  }

  @override
  Future<List<SpendingCalendarMonth>> getCalendarMonths() {
    return _remoteDataSource.getCalendarMonths();
  }

  @override
  Future<List<SpendingDayPost>> getDayPosts(DateTime date) {
    return _remoteDataSource.getDayPosts(date);
  }
}