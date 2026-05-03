class SpendingDayPost {
  const SpendingDayPost({
    required this.id,
    required this.imageUrl,
    required this.caption,
    required this.createdAt,
    required this.amountVnd,
  });

  final String id;
  final String imageUrl;
  final String caption;
  final DateTime createdAt;
  final int? amountVnd;
}
