import 'package:fpdart/fpdart.dart';
import 'package:momen/core/errors/failures.dart';
import 'package:momen/features/spending/data/datasources/spending_local_datasource.dart';
import 'package:momen/features/spending/domain/entities/spending_entry.dart';
import 'package:momen/features/spending/domain/repositories/spending_repository.dart';

class SpendingRepositoryImpl implements SpendingRepository {
  const SpendingRepositoryImpl(this._localDataSource);

  final SpendingLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, List<SpendingEntry>>> parseSpendingFromCaption(
    String caption,
  ) async {
    try {
      final amounts = _localDataSource.extractAmounts(caption);
      final entries = amounts
          .map(
            (amount) => SpendingEntry(
              amountVnd: amount,
              caption: caption,
            ),
          )
          .toList(growable: false);

      return Right(entries);
    } catch (error) {
      return Left(ParsingFailure(error.toString()));
    }
  }
}
