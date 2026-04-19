class AuthUser {
  const AuthUser({
    required this.id,
    this.email,
    this.phone,
    this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String? email;
  final String? phone;
  final String? displayName;
  final String? avatarUrl;
}
