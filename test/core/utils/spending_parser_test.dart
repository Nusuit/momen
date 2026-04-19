import 'package:flutter_test/flutter_test.dart';
import 'package:momen/core/utils/spending_parser.dart';

void main() {
  test('parseVndAmounts parses k/m/tr and vnd units', () {
    final result = SpendingParser.parseVndAmounts(
      'An pho 50k, ca phe 1.2m, taxi 2tr, do linh tinh 150000 vnd',
    );

    expect(result, [50000, 1200000, 2000000, 150000]);
  });

  test('parseVndAmounts returns empty when no supported units exist', () {
    final result = SpendingParser.parseVndAmounts('hom nay khong chi tieu');
    expect(result, isEmpty);
  });
}
