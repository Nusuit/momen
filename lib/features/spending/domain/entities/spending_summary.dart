class SpendingSummary {
  const SpendingSummary({
    required this.monthlyTotalVnd,
    required this.todayTotalVnd,
    required this.entriesWithAmount,
  });

  final int monthlyTotalVnd;
  final int todayTotalVnd;
  final int entriesWithAmount;
}