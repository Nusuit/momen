class SpendingCalendarMonth {
  const SpendingCalendarMonth({
    required this.monthStart,
    required this.totalVnd,
    required this.days,
  });

  final DateTime monthStart;
  final int totalVnd;
  final List<SpendingCalendarDay> days;
}

class SpendingCalendarDay {
  const SpendingCalendarDay({
    required this.date,
    required this.dailyTotalVnd,
    required this.latestImageUrl,
    required this.postCount,
  });

  final DateTime date;
  final int dailyTotalVnd;
  final String? latestImageUrl;
  final int postCount;
}
