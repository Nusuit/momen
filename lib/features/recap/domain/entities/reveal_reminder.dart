class RevealReminder {
  const RevealReminder({
    required this.reminderId,
    required this.postId,
    required this.imageUrl,
    required this.caption,
    required this.createdAt,
    required this.dueAt,
  });

  final String reminderId;
  final String postId;
  final String imageUrl;
  final String caption;
  final DateTime createdAt;
  final DateTime dueAt;
}
