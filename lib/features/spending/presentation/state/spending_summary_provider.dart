import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momen/core/providers/core_providers.dart';
import 'package:momen/features/spending/data/datasources/spending_summary_remote_datasource.dart';
import 'package:momen/features/spending/data/repositories_impl/spending_summary_repository_impl.dart';
import 'package:momen/features/spending/domain/entities/spending_summary.dart';
import 'package:momen/features/spending/domain/usecases/get_spending_summary_usecase.dart';

final _spendingSummaryRemoteDataSourceProvider =
    Provider<SpendingSummaryRemoteDataSource>((ref) {
  return SpendingSummaryRemoteDataSource(ref.watch(supabaseClientProvider));
});

final _spendingSummaryRepositoryProvider =
    Provider<SpendingSummaryRepositoryImpl>((ref) {
  return SpendingSummaryRepositoryImpl(
    ref.watch(_spendingSummaryRemoteDataSourceProvider),
  );
});

final _getSpendingSummaryUseCaseProvider =
    Provider<GetSpendingSummaryUseCase>((ref) {
  return GetSpendingSummaryUseCase(ref.watch(_spendingSummaryRepositoryProvider));
});

final spendingSummaryProvider =
    FutureProvider.autoDispose.family<SpendingSummary, DateTime?>((ref, month) {
  return ref.watch(_getSpendingSummaryUseCaseProvider).call(month: month);
});