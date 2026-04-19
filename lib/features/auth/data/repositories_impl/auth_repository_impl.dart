import 'package:momen/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:momen/features/auth/data/models/auth_user_model.dart';
import 'package:momen/features/auth/domain/entities/auth_user.dart';
import 'package:momen/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  AuthUser? getCurrentUser() {
    final user = _remoteDataSource.getCurrentUser();
    if (user == null) {
      return null;
    }
    return AuthUserModel.fromSupabaseUser(user);
  }

  @override
  Stream<AuthUser?> authStateChanges() {
    return _remoteDataSource.authStateChanges().map((user) {
      if (user == null) {
        return null;
      }
      return AuthUserModel.fromSupabaseUser(user);
    });
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final user = await _remoteDataSource.signInWithEmail(
      email: email,
      password: password,
    );
    return AuthUserModel.fromSupabaseUser(user);
  }

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final user = await _remoteDataSource.signUpWithEmail(
      email: email,
      password: password,
    );
    return AuthUserModel.fromSupabaseUser(user);
  }

  @override
  Future<AuthUser> signUpWithPhone({
    required String phone,
    required String password,
  }) async {
    final user = await _remoteDataSource.signUpWithPhone(
      phone: phone,
      password: password,
    );
    return AuthUserModel.fromSupabaseUser(user);
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    String? redirectTo,
  }) {
    return _remoteDataSource.sendPasswordResetEmail(
      email: email,
      redirectTo: redirectTo,
    );
  }

  @override
  Future<void> requestPhoneOtp({required String phone}) {
    return _remoteDataSource.requestPhoneOtp(phone: phone);
  }

  @override
  Future<AuthUser> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    final user = await _remoteDataSource.verifyPhoneOtp(
      phone: phone,
      token: token,
    );
    return AuthUserModel.fromSupabaseUser(user);
  }

  @override
  Future<AuthUser> verifyEmailOtp({
    required String email,
    required String token,
    required EmailOtpType type,
  }) async {
    final user = await _remoteDataSource.verifyEmailOtp(
      email: email,
      token: token,
      type: type,
    );
    return AuthUserModel.fromSupabaseUser(user);
  }

  @override
  Future<void> resetPasswordWithSession({required String newPassword}) {
    return _remoteDataSource.resetPasswordWithSession(newPassword: newPassword);
  }

  @override
  Future<AuthUser> refreshToken() async {
    final user = await _remoteDataSource.refreshToken();
    return AuthUserModel.fromSupabaseUser(user);
  }

  @override
  Future<void> signInWithGoogle({String? redirectTo}) {
    return _remoteDataSource.signInWithGoogle(redirectTo: redirectTo);
  }

  @override
  Future<bool> requiresProfileCompletion() {
    return _remoteDataSource.requiresProfileCompletion();
  }

  @override
  Future<void> syncCurrentUserProfileFromMetadata() {
    return _remoteDataSource.syncCurrentUserProfileFromMetadata();
  }

  @override
  Future<void> completeProfile({
    required String fullName,
    required String userCode,
    required String phone,
    required String email,
    required DateTime dateOfBirth,
  }) {
    return _remoteDataSource.completeProfile(
      fullName: fullName,
      userCode: userCode,
      phone: phone,
      email: email,
      dateOfBirth: dateOfBirth,
    );
  }

  @override
  Future<void> signOut() {
    return _remoteDataSource.signOut();
  }
}
