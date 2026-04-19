class PublicProfileView {
  const PublicProfileView({
    required this.id,
    required this.fullName,
    required this.isFriend,
    required this.hasPendingOutgoing,
    required this.hasPendingIncoming,
    this.userCode,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final bool isFriend;
  final bool hasPendingOutgoing;
  final bool hasPendingIncoming;
  final String? userCode;
  final String? avatarUrl;
}
