import 'package:momen/features/spending/domain/entities/spending_summary.dart';
import 'package:momen/features/spending/domain/repositories/spending_summary_repository.dart';

class GetSpendingSummaryUseCase {
  const GetSpendingSummaryUseCase(this._repository);

  final SpendingSummaryRepository _repository;

  Future<SpendingSummary> call({DateTime? month}) {
    return _repository.getSummary(month: month);
  }
}