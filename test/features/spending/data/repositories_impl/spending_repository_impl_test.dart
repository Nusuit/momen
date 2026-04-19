import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momen/features/spending/data/datasources/spending_local_datasource.dart';
import 'package:momen/features/spending/data/repositories_impl/spending_repository_impl.dart';

class _MockSpendingLocalDataSource extends Mock
    implements SpendingLocalDataSource {}

void main() {
  late _MockSpendingLocalDataSource dataSource;
  late SpendingRepositoryImpl repository;

  setUp(() {
    dataSource = _MockSpendingLocalDataSource();
    repository = SpendingRepositoryImpl(dataSource);
  });

  test('maps datasource amounts to domain entries', () async {
    when(() => dataSource.extractAmounts(any())).thenReturn([50000, 1200000]);

    final result =
        await repository.parseSpendingFromCaption('pho 50k, giay 1.2m');

    expect(result.isRight(), isTrue);
    result.match(
      (_) => fail('Expected right result'),
      (entries) {
        expect(entries.length, 2);
        expect(entries.first.amountVnd, 50000);
        expect(entries.last.amountVnd, 1200000);
      },
    );
  });

  test('returns left when datasource throws', () async {
    when(() => dataSource.extractAmounts(any())).thenThrow(Exception('boom'));

    final result = await repository.parseSpendingFromCaption('bad input');

    expect(result.isLeft(), isTrue);
  });
}
