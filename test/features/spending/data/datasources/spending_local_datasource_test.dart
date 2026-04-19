import 'package:flutter_test/flutter_test.dart';
import 'package:momen/features/spending/data/datasources/spending_local_datasource.dart';

void main() {
  test('SpendingLocalDataSourceImpl delegates amount extraction to parser', () {
    final dataSource = SpendingLocalDataSourceImpl();

    final result = dataSource.extractAmounts('pho 50k va giay 1.5m');

    expect(result, [50000, 1500000]);
  });
}
