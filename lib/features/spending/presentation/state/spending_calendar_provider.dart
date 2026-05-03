import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momen/core/providers/core_providers.dart';
import 'package:momen/features/spending/data/datasources/spending_summary_remote_datasource.dart';
import 'package:momen/features/spending/data/repositories_impl/spending_summary_repository_impl.dart';
import 'package:momen/features/spending/domain/entities/spending_calendar_month.dart';
import 'package:momen/features/spending/domain/entities/spending_day_post.dart';
import 'package:momen/features/spending/domain/usecases/get_spending_calendar_usecase.dart';
import 'package:momen/features/spending/domain/usecases/get_spending_day_posts_usecase.dart';

final _calendarRemoteDataSourceProvider =
    Provider<SpendingSummaryRemoteDataSource>((ref) {
  return SpendingSummaryRemoteDataSource(ref.watch(supabaseClientProvider));
});

final _calendarRepositoryProvider = Provider<SpendingSummaryRepositoryImpl>((ref) {
  return SpendingSummaryRepositoryImpl(ref.watch(_calendarRemoteDataSourceProvider));
});

final _getSpendingCalendarUseCaseProvider =
    Provider<GetSpendingCalendarUseCase>((ref) {
  return GetSpendingCalendarUseCase(ref.watch(_calendarRepositoryProvider));
});

final _getSpendingDayPostsUseCaseProvider =
    Provider<GetSpendingDayPostsUseCase>((ref) {
  return GetSpendingDayPostsUseCase(ref.watch(_calendarRepositoryProvider));
});

final spendingCalendarProvider =
    FutureProvider.autoDispose<List<SpendingCalendarMonth>>((ref) {
  return ref.watch(_getSpendingCalendarUseCaseProvider).call();
});

final spendingDayPostsProvider =
    FutureProvider.autoDispose.family<List<SpendingDayPost>, DateTime>(
  (ref, date) {
    return ref.watch(_getSpendingDayPostsUseCaseProvider).call(date);
  },
);
