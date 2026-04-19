import 'package:momen/features/auth/domain/entities/auth_user.dart';

enum EmailOtpType {
  signup,
  recovery,
  email,
}

abstract class AuthRepository {
  AuthUser? getCurrentUser();

  Stream<AuthUser?> authStateChanges();

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser> signUpWithPhone({
    required String phone,
    required String password,
  });

  Future<void> sendPasswordResetEmail({
    required String email,
    String? redirectTo,
  });

  Future<void> requestPhoneOtp({required String phone});

  Future<AuthUser> verifyPhoneOtp({
    required String phone,
    required String token,
  });

  Future<AuthUser> verifyEmailOtp({
    required String email,
    required String token,
    required EmailOtpType type,
  });

  Future<void> resetPasswordWithSession({required String newPassword});

  Future<AuthUser> refreshToken();

  Future<void> signInWithGoogle({String? redirectTo});

  Future<bool> requiresProfileCompletion();

  Future<void> syncCurrentUserProfileFromMetadata();

  Future<void> completeProfile({
    required String fullName,
    required String userCode,
    required String phone,
    required String email,
    required DateTime dateOfBirth,
  });

  Future<void> signOut();
}
