class MemoryPost {
  const MemoryPost({
    required this.id,
    required this.imageUrl,
    required this.caption,
    required this.createdAt,
    required this.ownerId,
    this.amountVnd,
    this.ownerName,
    this.isRevealed = false,
    this.isPending = false,
    this.myReaction,
    this.loveCount = 0,
    this.hahaCount = 0,
    this.sadCount = 0,
  });

  final String id;
  final String imageUrl;
  final String caption;
  final DateTime createdAt;
  final String ownerId;
  final int? amountVnd;
  final String? ownerName;
  final bool isRevealed;
  final bool isPending;
  final String? myReaction;
  final int loveCount;
  final int hahaCount;
  final int sadCount;
}
