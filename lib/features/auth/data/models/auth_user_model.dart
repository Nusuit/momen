import 'package:momen/features/auth/domain/entities/auth_user.dart' as domain;
import 'package:supabase_flutter/supabase_flutter.dart' show User;

class AuthUserModel extends domain.AuthUser {
  const AuthUserModel({
    required super.id,
    super.email,
    super.phone,
    super.displayName,
    super.avatarUrl,
  });

  factory AuthUserModel.fromSupabaseUser(User user) {
    final metadata = user.userMetadata;
    final displayName = _firstString(metadata, const [
      'full_name',
      'name',
      'user_name',
      'preferred_username',
    ]);
    final avatarUrl = _firstString(metadata, const [
      'avatar_url',
      'picture',
    ]);
    return AuthUserModel(
      id: user.id,
      email: (user.email?.trim().isNotEmpty ?? false)
          ? user.email
          : _firstString(metadata, const ['contact_email']),
      phone: (user.phone?.trim().isNotEmpty ?? false)
          ? user.phone
          : _firstString(metadata, const ['contact_phone']),
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }

  static String? _firstString(
    Map<String, dynamic>? metadata,
    List<String> keys,
  ) {
    if (metadata == null) return null;
    for (final key in keys) {
      final value = (metadata[key] as String?)?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}
