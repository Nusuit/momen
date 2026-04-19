import 'package:momen/core/utils/spending_parser.dart';

abstract class SpendingLocalDataSource {
  List<int> extractAmounts(String caption);
}

class SpendingLocalDataSourceImpl implements SpendingLocalDataSource {
  @override
  List<int> extractAmounts(String caption) {
    return SpendingParser.parseVndAmounts(caption);
  }
}
