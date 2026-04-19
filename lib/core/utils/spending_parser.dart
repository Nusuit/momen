class SpendingParser {
  SpendingParser._();

  static final RegExp _amountRegex = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(k|m|tr|trieu|nghin|vnd|d)\b',
    caseSensitive: false,
  );

  /// Parse Vietnamese spending amounts from free text into VND integer values.
  static List<int> parseVndAmounts(String caption) {
    final matches = _amountRegex.allMatches(caption);
    final amounts = <int>[];

    for (final match in matches) {
      final rawNumber = match.group(1);
      final rawUnit = match.group(2);
      if (rawNumber == null || rawUnit == null) {
        continue;
      }

      final unit = rawUnit.toLowerCase();
      final amount = _toVnd(rawNumber, unit);
      if (amount > 0) {
        amounts.add(amount);
      }
    }

    return amounts;
  }

  static int _toVnd(String rawNumber, String unit) {
    if (unit == 'vnd' || unit == 'd') {
      final normalized = rawNumber.replaceAll(RegExp(r'[.,]'), '');
      final parsed = int.tryParse(normalized);
      return parsed ?? 0;
    }

    final normalized = rawNumber.replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return 0;
    }

    if (unit == 'k' || unit == 'nghin') {
      return (parsed * 1000).round();
    }

    if (unit == 'm' || unit == 'tr' || unit == 'trieu') {
      return (parsed * 1000000).round();
    }

    return 0;
  }
}
