import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momen/core/errors/failures.dart';
import 'package:momen/features/spending/domain/entities/spending_entry.dart';
import 'package:momen/features/spending/domain/repositories/spending_repository.dart';
import 'package:momen/features/spending/domain/usecases/parse_spending_from_caption_usecase.dart';

class _MockSpendingRepository extends Mock implements SpendingRepository {}

void main() {
  late _MockSpendingRepository repository;
  late ParseSpendingFromCaptionUseCase useCase;

  setUp(() {
    repository = _MockSpendingRepository();
    useCase = ParseSpendingFromCaptionUseCase(repository);
  });

  test('returns parsed entries when repository succeeds', () async {
    const entries = [
      SpendingEntry(amountVnd: 50000, caption: 'pho 50k'),
    ];

    when(() => repository.parseSpendingFromCaption(any()))
        .thenAnswer((_) async => const Right(entries));

    final result = await useCase('pho 50k');

    expect(result.isRight(), isTrue);
    verify(() => repository.parseSpendingFromCaption('pho 50k')).called(1);
  });

  test('returns failure when repository fails', () async {
    when(() => repository.parseSpendingFromCaption(any()))
        .thenAnswer((_) async => const Left(ParsingFailure('parse failed')));

    final result = await useCase('unknown');

    expect(result.isLeft(), isTrue);
  });
}
