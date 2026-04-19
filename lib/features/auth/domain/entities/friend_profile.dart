class FriendProfile {
  const FriendProfile({
    required this.id,
    required this.fullName,
    this.userCode,
    this.avatarUrl,
    this.distanceM,
    this.matchedPhoneHash,
  });

  final String id;
  final String fullName;
  final String? userCode;
  final String? avatarUrl;
  final double? distanceM;
  final String? matchedPhoneHash;
}
