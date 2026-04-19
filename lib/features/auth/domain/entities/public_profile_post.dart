class PublicProfilePost {
  const PublicProfilePost({
    required this.id,
    required this.imageUrl,
    required this.caption,
    required this.createdAt,
  });

  final String id;
  final String imageUrl;
  final String caption;
  final DateTime createdAt;
}
