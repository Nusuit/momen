import 'package:fpdart/fpdart.dart';
import 'package:momen/core/errors/failures.dart';
import 'package:momen/features/spending/domain/entities/spending_entry.dart';
import 'package:momen/features/spending/domain/repositories/spending_repository.dart';

class ParseSpendingFromCaptionUseCase {
  const ParseSpendingFromCaptionUseCase(this._repository);

  final SpendingRepository _repository;

  Future<Either<Failure, List<SpendingEntry>>> call(String caption) {
    return _repository.parseSpendingFromCaption(caption);
  }
}
