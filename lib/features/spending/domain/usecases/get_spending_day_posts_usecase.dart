import 'package:momen/features/spending/domain/entities/spending_day_post.dart';
import 'package:momen/features/spending/domain/repositories/spending_summary_repository.dart';

class GetSpendingDayPostsUseCase {
  const GetSpendingDayPostsUseCase(this._repository);

  final SpendingSummaryRepository _repository;

  Future<List<SpendingDayPost>> call(DateTime date) {
    return _repository.getDayPosts(date);
  }
}
