import 'package:fpdart/fpdart.dart';
import 'package:momen/core/errors/failures.dart';
import 'package:momen/features/spending/domain/entities/spending_entry.dart';

abstract class SpendingRepository {
  Future<Either<Failure, List<SpendingEntry>>> parseSpendingFromCaption(
    String caption,
  );
}
