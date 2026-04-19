import 'package:momen/features/spending/domain/entities/spending_summary.dart';

abstract class SpendingSummaryRepository {
  Future<SpendingSummary> getSummary();
}