import 'package:momen/features/spending/domain/entities/spending_calendar_month.dart';
import 'package:momen/features/spending/domain/repositories/spending_summary_repository.dart';

class GetSpendingCalendarUseCase {
  const GetSpendingCalendarUseCase(this._repository);

  final SpendingSummaryRepository _repository;

  Future<List<SpendingCalendarMonth>> call() {
    return _repository.getCalendarMonths();
  }
}
