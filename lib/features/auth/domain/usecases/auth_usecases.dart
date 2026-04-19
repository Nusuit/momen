import 'package:momen/features/auth/domain/entities/auth_user.dart';
import 'package:momen/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentAuthUserUseCase {
  const GetCurrentAuthUserUseCase(this._repository);

  final AuthRepository _repository;

  AuthUser? call() {
    return _repository.getCurrentUser();
  }
}

class ObserveAuthStateUseCase {
  const ObserveAuthStateUseCase(this._repository);

  final AuthRepository _repository;

  Stream<AuthUser?> call() {
    return _repository.authStateChanges();
  }
}

class SignInWithEmailUseCase {
  const SignInWithEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({required String email, required String password}) {
    return _repository.signInWithEmail(email: email, password: password);
  }
}

class SignUpWithEmailUseCase {
  const SignUpWithEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({
    required String email,
    required String password,
  }) {
    return _repository.signUpWithEmail(
      email: email,
      password: password,
    );
  }
}

class SignUpWithPhoneUseCase {
  const SignUpWithPhoneUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({required String phone, required String password}) {
    return _repository.signUpWithPhone(phone: phone, password: password);
  }
}

class SendPasswordResetEmailUseCase {
  const SendPasswordResetEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String email, String? redirectTo}) {
    return _repository.sendPasswordResetEmail(
      email: email,
      redirectTo: redirectTo,
    );
  }
}

class RequestPhoneOtpUseCase {
  const RequestPhoneOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String phone}) {
    return _repository.requestPhoneOtp(phone: phone);
  }
}

class VerifyPhoneOtpUseCase {
  const VerifyPhoneOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({required String phone, required String token}) {
    return _repository.verifyPhoneOtp(phone: phone, token: token);
  }
}

class VerifyEmailOtpUseCase {
  const VerifyEmailOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({
    required String email,
    required String token,
    required EmailOtpType type,
  }) {
    return _repository.verifyEmailOtp(
      email: email,
      token: token,
      type: type,
    );
  }
}

class ResetPasswordWithSessionUseCase {
  const ResetPasswordWithSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String newPassword}) {
    return _repository.resetPasswordWithSession(newPassword: newPassword);
  }
}

class RefreshAuthTokenUseCase {
  const RefreshAuthTokenUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call() {
    return _repository.refreshToken();
  }
}

class SignInWithGoogleUseCase {
  const SignInWithGoogleUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({String? redirectTo}) {
    return _repository.signInWithGoogle(redirectTo: redirectTo);
  }
}

class RequiresProfileCompletionUseCase {
  const RequiresProfileCompletionUseCase(this._repository);

  final AuthRepository _repository;

  Future<bool> call() {
    return _repository.requiresProfileCompletion();
  }
}

class SyncCurrentUserProfileFromMetadataUseCase {
  const SyncCurrentUserProfileFromMetadataUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() {
    return _repository.syncCurrentUserProfileFromMetadata();
  }
}

class CompleteProfileUseCase {
  const CompleteProfileUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String fullName,
    required String userCode,
    required String phone,
    required String email,
    required DateTime dateOfBirth,
  }) {
    return _repository.completeProfile(
      fullName: fullName,
      userCode: userCode,
      phone: phone,
      email: email,
      dateOfBirth: dateOfBirth,
    );
  }
}

class SignOutUseCase {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() {
    return _repository.signOut();
  }
}
