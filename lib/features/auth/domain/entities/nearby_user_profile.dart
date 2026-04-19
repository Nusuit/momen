class NearbyUserProfile {
  const NearbyUserProfile({
    required this.id,
    required this.fullName,
    required this.distanceM,
    this.userCode,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final double distanceM;
  final String? userCode;
  final String? avatarUrl;
}
