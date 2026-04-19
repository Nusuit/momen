class MemoryItem {
  const MemoryItem({
    required this.day,
    required this.amount,
    required this.category,
    this.imageUrl = '',
    this.alias = '',
    this.caption = '',
  });

  final int day;
  final String amount;
  final String category;
  final String imageUrl;
  final String alias;
  final String caption;
}
