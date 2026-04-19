import 'package:momen/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final SupabaseClient? _client;

  User? getCurrentUser() {
    return _client?.auth.currentUser;
  }

  Stream<User?> authStateChanges() {
    final client = _client;
    if (client == null) {
      return const Stream<User?>.empty();
    }

    return client.auth.onAuthStateChange.map((event) => event.session?.user);
  }

  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw Exception('Sign in failed: missing user.');
    }
    return user;
  }

  Future<User> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();

    final data = <String, dynamic>{};

    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: data.isEmpty ? null : data,
    );
    final user = response.user;
    if (user == null) {
      throw Exception('Sign up failed: missing user.');
    }

    await client.from('profiles').upsert({'id': user.id});

    return user;
  }

  Future<User> signUpWithPhone({
    required String phone,
    required String password,
  }) async {
    final client = _requireClient();

    final response = await client.auth.signUp(
      phone: phone,
      password: password,
      data: null,
    );
    final user = response.user;
    if (user == null) {
      throw Exception('Sign up failed: missing user.');
    }

    await client.from('profiles').upsert({'id': user.id});

    return user;
  }

  Future<void> sendPasswordResetEmail({
    required String email,
    String? redirectTo,
  }) async {
    final client = _requireClient();
    await client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
  }

  Future<void> requestPhoneOtp({required String phone}) async {
    final client = _requireClient();
    await client.auth.signInWithOtp(phone: phone);
  }

  Future<User> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    final client = _requireClient();
    final response = await client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
    final user = response.user;
    if (user == null) {
      throw Exception('Phone OTP verification failed.');
    }
    return user;
  }

  Future<User> verifyEmailOtp({
    required String email,
    required String token,
    required EmailOtpType type,
  }) async {
    final client = _requireClient();
    final response = await client.auth.verifyOTP(
      email: email,
      token: token,
      type: _toSupabaseOtpType(type),
    );
    final user = response.user;
    if (user == null) {
      throw Exception('Email OTP verification failed.');
    }
    return user;
  }

  Future<void> resetPasswordWithSession({required String newPassword}) async {
    final client = _requireClient();
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<User> refreshToken() async {
    final client = _requireClient();
    final session = client.auth.currentSession;
    final refreshToken = session?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('No refresh token available.');
    }

    final response = await client.auth.refreshSession(refreshToken);
    final user = response.user;
    if (user == null) {
      throw Exception('Refresh token failed: missing user.');
    }
    return user;
  }

  Future<void> signInWithGoogle({String? redirectTo}) async {
    final client = _requireClient();
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
    );
  }

  Future<bool> requiresProfileCompletion() async {
    final client = _requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      return false;
    }

    final rows = await client
        .from('profiles')
        .select('full_name,date_of_birth,user_code')
        .eq('id', user.id)
        .limit(1);

    if (rows.isEmpty) {
      return true;
    }

    final row = rows.first;
    final fullName = ((row['full_name'] as String?) ?? '').trim();
    final dateOfBirth = _parseDateOnly((row['date_of_birth'] as String?) ?? '');
    final userCode = ((row['user_code'] as String?) ?? '').trim();
    final metadata = user.userMetadata;
    final email = (user.email?.trim().isNotEmpty ?? false)
      ? user.email!.trim()
      : ((_firstMetadataString(metadata, const ['contact_email'])) ?? '');
    return fullName.isEmpty ||
      dateOfBirth == null ||
      userCode.isEmpty ||
      email.isEmpty;
  }

  Future<void> syncCurrentUserProfileFromMetadata() async {
    final client = _requireClient();
    final user = client.auth.currentUser;
    if (user == null) return;

    final metadata = user.userMetadata;
    final metadataName = _firstMetadataString(metadata, const [
      'full_name',
      'name',
      'user_name',
      'preferred_username',
    ]);
    final metadataAvatar = _firstMetadataString(metadata, const [
      'avatar_url',
      'picture',
    ]);

    if (metadataName == null && metadataAvatar == null) return;

    final rows = await client
        .from('profiles')
        .select('full_name,avatar_path')
        .eq('id', user.id)
        .limit(1);

    final current = rows.isEmpty ? null : rows.first;
    final currentName = ((current?['full_name'] as String?) ?? '').trim();
    final currentAvatar = ((current?['avatar_path'] as String?) ?? '').trim();

    final payload = <String, dynamic>{'id': user.id};
    if (currentName.isEmpty && metadataName != null) {
      payload['full_name'] = metadataName;
    }
    if (currentAvatar.isEmpty && metadataAvatar != null) {
      payload['avatar_path'] = metadataAvatar;
    }

    if (payload.length == 1) return;
    await client.from('profiles').upsert(payload);
  }

  Future<void> completeProfile({
    required String fullName,
    required String userCode,
    required String phone,
    required String email,
    required DateTime dateOfBirth,
  }) async {
    final client = _requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in before updating profile.');
    }

    final normalizedFullName = fullName.trim();
    final normalizedUserCode = userCode.trim().toUpperCase();
    final normalizedPhone = phone.trim();
    final normalizedEmail = email.trim();
    final dobIsoDate = _toIsoDate(dateOfBirth);

    if (normalizedFullName.isEmpty) {
      throw Exception('Name is required.');
    }
    if (normalizedUserCode.isEmpty) {
      throw Exception('ID is required.');
    }
    if (normalizedEmail.isEmpty) {
      throw Exception('Email is required.');
    }

    final metadata = <String, dynamic>{
      'contact_email': normalizedEmail,
    };
    if (normalizedPhone.isNotEmpty) {
      metadata['contact_phone'] = normalizedPhone;
    }

    // Persist contact info in metadata immediately, even when auth-level
    // email/phone update requires out-of-band verification.
    await client.auth.updateUser(UserAttributes(data: metadata));

    final authPhone = user.phone?.trim() ?? '';
    final isAuthPhone = authPhone.isNotEmpty && authPhone == normalizedPhone;

    final payload = <String, dynamic>{
      'id': user.id,
      'full_name': normalizedFullName,
      'date_of_birth': dobIsoDate,
      'user_code': normalizedUserCode,
      'phone_number': normalizedPhone.isEmpty ? null : normalizedPhone,
      'is_phone_verified': normalizedPhone.isNotEmpty && isAuthPhone,
      'phone_verified_at': normalizedPhone.isNotEmpty && isAuthPhone
          ? DateTime.now().toUtc().toIso8601String()
          : null,
    };

    await client.from('profiles').upsert(payload);
  }

  DateTime? _parseDateOnly(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return null;
    }

    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  String _toIsoDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  String? _firstMetadataString(
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

  Future<void> signOut() async {
    final client = _requireClient();
    await client.auth.signOut();
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw Exception(
        'Supabase is not configured. Start app with --dart-define-from-file=.env or provide SUPABASE_URL/SUPABASE_ANON_KEY.',
      );
    }
    return client;
  }

  OtpType _toSupabaseOtpType(EmailOtpType type) {
    return switch (type) {
      EmailOtpType.signup => OtpType.signup,
      EmailOtpType.recovery => OtpType.recovery,
      EmailOtpType.email => OtpType.email,
    };
  }
}
