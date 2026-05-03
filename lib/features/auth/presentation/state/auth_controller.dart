import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momen/core/providers/core_providers.dart';
import 'package:momen/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:momen/features/auth/data/repositories_impl/auth_repository_impl.dart';
import 'package:momen/features/auth/domain/entities/auth_user.dart';
import 'package:momen/features/auth/domain/repositories/auth_repository.dart';
import 'package:momen/features/auth/domain/usecases/auth_usecases.dart';

enum AuthStatus {
  unknown,
  loading,
  authenticated,
  unauthenticated,
}

class AuthControllerState {
  const AuthControllerState({
    required this.status,
    this.user,
    this.errorMessage,
    this.requiresProfileCompletion = false,
  });

  const AuthControllerState.unknown() : this(status: AuthStatus.unknown);

  const AuthControllerState.loading({AuthUser? previousUser})
      : this(status: AuthStatus.loading, user: previousUser);

  const AuthControllerState.authenticated(
    AuthUser user, {
    bool requiresProfileCompletion = false,
  }) : this(
          status: AuthStatus.authenticated,
          user: user,
          requiresProfileCompletion: requiresProfileCompletion,
        );

  const AuthControllerState.unauthenticated({String? errorMessage})
      : this(
          status: AuthStatus.unauthenticated,
          errorMessage: errorMessage,
        );

  final AuthStatus status;
  final AuthUser? user;
  final String? errorMessage;
  final bool requiresProfileCompletion;
}

final _authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.watch(supabaseClientProvider)),
);

final _authRepositoryProvider = Provider<AuthRepositoryImpl>(
  (ref) => AuthRepositoryImpl(ref.watch(_authRemoteDataSourceProvider)),
);

final _getCurrentAuthUserUseCaseProvider = Provider<GetCurrentAuthUserUseCase>(
  (ref) => GetCurrentAuthUserUseCase(ref.watch(_authRepositoryProvider)),
);

final _observeAuthStateUseCaseProvider = Provider<ObserveAuthStateUseCase>(
  (ref) => ObserveAuthStateUseCase(ref.watch(_authRepositoryProvider)),
);

final _signInWithEmailUseCaseProvider = Provider<SignInWithEmailUseCase>(
  (ref) => SignInWithEmailUseCase(ref.watch(_authRepositoryProvider)),
);

final _signUpWithEmailUseCaseProvider = Provider<SignUpWithEmailUseCase>(
  (ref) => SignUpWithEmailUseCase(ref.watch(_authRepositoryProvider)),
);

final _signUpWithPhoneUseCaseProvider = Provider<SignUpWithPhoneUseCase>(
  (ref) => SignUpWithPhoneUseCase(ref.watch(_authRepositoryProvider)),
);

final _sendPasswordResetEmailUseCaseProvider =
    Provider<SendPasswordResetEmailUseCase>(
  (ref) => SendPasswordResetEmailUseCase(ref.watch(_authRepositoryProvider)),
);

final _requestPhoneOtpUseCaseProvider = Provider<RequestPhoneOtpUseCase>(
  (ref) => RequestPhoneOtpUseCase(ref.watch(_authRepositoryProvider)),
);

final _verifyPhoneOtpUseCaseProvider = Provider<VerifyPhoneOtpUseCase>(
  (ref) => VerifyPhoneOtpUseCase(ref.watch(_authRepositoryProvider)),
);

final _verifyEmailOtpUseCaseProvider = Provider<VerifyEmailOtpUseCase>(
  (ref) => VerifyEmailOtpUseCase(ref.watch(_authRepositoryProvider)),
);

final _resetPasswordWithSessionUseCaseProvider =
    Provider<ResetPasswordWithSessionUseCase>(
  (ref) =>
      ResetPasswordWithSessionUseCase(ref.watch(_authRepositoryProvider)),
);

final _refreshAuthTokenUseCaseProvider = Provider<RefreshAuthTokenUseCase>(
  (ref) => RefreshAuthTokenUseCase(ref.watch(_authRepositoryProvider)),
);

final _signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase>(
  (ref) => SignInWithGoogleUseCase(ref.watch(_authRepositoryProvider)),
);

final _requiresProfileCompletionUseCaseProvider =
    Provider<RequiresProfileCompletionUseCase>(
  (ref) => RequiresProfileCompletionUseCase(ref.watch(_authRepositoryProvider)),
);

final _syncCurrentUserProfileFromMetadataUseCaseProvider =
    Provider<SyncCurrentUserProfileFromMetadataUseCase>(
  (ref) => SyncCurrentUserProfileFromMetadataUseCase(
    ref.watch(_authRepositoryProvider),
  ),
);

final _completeProfileUseCaseProvider = Provider<CompleteProfileUseCase>(
  (ref) => CompleteProfileUseCase(ref.watch(_authRepositoryProvider)),
);

final _signOutUseCaseProvider = Provider<SignOutUseCase>(
  (ref) => SignOutUseCase(ref.watch(_authRepositoryProvider)),
);

final authControllerProvider =
    NotifierProvider<AuthController, AuthControllerState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthControllerState> {
  StreamSubscription<AuthUser?>? _authSubscription;

  @override
  AuthControllerState build() {
    ref.onDispose(() async {
      await _authSubscription?.cancel();
    });

    _authSubscription ??= ref
        .read(_observeAuthStateUseCaseProvider)
        .call()
        .listen(_handleAuthStateChange);

    final currentUser = ref.read(_getCurrentAuthUserUseCaseProvider).call();
    if (currentUser == null) {
      return const AuthControllerState.unauthenticated();
    }
    _applyAuthenticatedState(currentUser);
    return AuthControllerState.authenticated(currentUser);
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = AuthControllerState.loading(previousUser: state.user);
    try {
      final user = await ref.read(_signInWithEmailUseCaseProvider).call(
            email: email.trim(),
            password: password,
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Request timed out. Check your connection.'),
          );
      await _applyAuthenticatedState(user);
      return true;
    } catch (error) {
      state = AuthControllerState.unauthenticated(errorMessage: '$error');
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = AuthControllerState.loading(previousUser: state.user);
    try {
      await ref.read(_signUpWithEmailUseCaseProvider).call(
            email: email.trim(),
            password: password,
          );

      final currentUser = ref.read(_getCurrentAuthUserUseCaseProvider).call();
      if (currentUser != null) {
        await _applyAuthenticatedState(currentUser);
      } else {
        state = const AuthControllerState.unauthenticated();
      }
      return true;
    } catch (error) {
      state = AuthControllerState.unauthenticated(errorMessage: '$error');
      return false;
    }
  }

  Future<bool> signUpWithPhone({
    required String phone,
    required String password,
  }) async {
    state = AuthControllerState.loading(previousUser: state.user);
    try {
      await ref.read(_signUpWithPhoneUseCaseProvider).call(
            phone: phone.trim(),
            password: password,
          );

      final currentUser = ref.read(_getCurrentAuthUserUseCaseProvider).call();
      if (currentUser != null) {
        await _applyAuthenticatedState(currentUser);
      } else {
        state = const AuthControllerState.unauthenticated();
      }
      return true;
    } catch (error) {
      state = AuthControllerState.unauthenticated(errorMessage: '$error');
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail({
    required String email,
    String? redirectTo,
  }) async {
    state = AuthControllerState.loading(previousUser: state.user);
    try {
      await ref.read(_sendPasswordResetEmailUseCaseProvider).call(
            email: email.trim(),
            redirectTo: redirectTo,
          );
      state = const AuthControllerState.unauthenticated();
      return true;
    } catch (error) {
      state = AuthControllerState.unauthenticated(errorMessage: '$error');
      return false;
    }
  }

  Future<bool> requestPhoneOtp({required String phone}) async {
    state = AuthControllerState.loading(previousUser: state.user);
    try {
      await ref.read(_requestPhoneOtpUseCaseProvider).call(phone: phone.trim());
      state = const AuthControllerState.unauthenticated();
      return true;
    } catch (error) {
      state = AuthControllerState.unauthenticated(errorMessage: '$error');
      return false;
    }
  }

  Future<bool> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    state = AuthControllerState.loading(previousUser: state.user);
    try {
      final user = await ref.read(_verifyPhoneOtpUseCaseProvider).call(
            phone: phone.trim(),
            token: token.trim(),
          );
      await _applyAuthenticatedState(user);
      return true;
    } catch (error) {
      state = AuthControllerState.unauthenticated(errorMessage: '$error');
      return false;
    }
  }

  Future<bool> verifyEmailOtp({
    required String email,
    required String token,
    required EmailOtpType type,
  }) async {
    state = AuthControllerState.loading(previousUser: state.user);
    try {
      final user = await ref.read(_verifyEmailOtpUseCaseProvider).call(
            email: email.trim(),
            token: token.trim(),
            type: type,
          );
      await _applyAuthenticatedState(user);
      return true;
    } catch (error) {
      state = AuthControllerState.unauthenticated(errorMessage: '$error');
      return false;
    }
  }

  Future<bool> verifyRecoveryOtpAndResetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    state = AuthControllerState.loading(previousUser: state.user);
    try {
      await ref.read(_verifyEmailOtpUseCaseProvider).call(
            email: email.trim(),
            token: token.trim(),
            type: EmailOtpType.recovery,
          );

      await ref.read(_resetPasswordWithSessionUseCaseProvider).call(
            newPassword: newPassword,
          );

      final currentUser = ref.read(_getCurrentAuthUserUseCaseProvider).call();
      if (currentUser == null) {
        state = const AuthControllerState.unauthenticated();
      } else {
        await _applyAuthenticatedState(currentUser);
      }
      return true;
    } catch (error) {
      state = AuthControllerState.unauthenticated(errorMessage: '$error');
      return false;
    }
  }

  Future<bool> refreshToken() async {
    state = AuthControllerState.loading(previousUser: state.user);
    try {
      final user = await ref.read(_refreshAuthTokenUseCaseProvider).call();
      await _applyAuthenticatedState(user);
      return true;
    } catch (error) {
      state = AuthControllerState.unauthenticated(errorMessage: '$error');
      return false;
    }
  }

  Future<bool> signInWithGoogle({String? redirectTo}) async {
    state = AuthControllerState.loading(previousUser: state.user);
    try {
      await ref.read(_signInWithGoogleUseCaseProvider).call(
            redirectTo: redirectTo,
          );

      final currentUser = ref.read(_getCurrentAuthUserUseCaseProvider).call();
      if (currentUser == null) {
        state = const AuthControllerState.unauthenticated();
      } else {
        await _applyAuthenticatedState(currentUser);
      }
      return true;
    } catch (error) {
      state = AuthControllerState.unauthenticated(errorMessage: '$error');
      return false;
    }
  }

  Future<bool> requiresProfileCompletion() async {
    try {
      return await ref.read(_requiresProfileCompletionUseCaseProvider).call();
    } catch (_) {
      return false;
    }
  }

  Future<bool> completeProfile({
    required String fullName,
    required String userCode,
    required String phone,
    required String email,
    required DateTime dateOfBirth,
  }) async {
    try {
      await ref.read(_completeProfileUseCaseProvider).call(
            fullName: fullName,
            userCode: userCode,
            phone: phone,
            email: email,
            dateOfBirth: dateOfBirth,
          );
      final currentUser = ref.read(_getCurrentAuthUserUseCaseProvider).call();
      if (currentUser != null) {
        state = AuthControllerState.authenticated(
          currentUser,
          requiresProfileCompletion: false,
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void resetToUnauthenticated() {
    if (state.status == AuthStatus.loading) {
      state = const AuthControllerState.unauthenticated();
    }
  }

  Future<void> signOut() async {
    state = AuthControllerState.loading(previousUser: state.user);
    try {
      await ref.read(_signOutUseCaseProvider).call();
      state = const AuthControllerState.unauthenticated();
    } catch (error) {
      state = AuthControllerState.unauthenticated(errorMessage: '$error');
    }
  }

  void _handleAuthStateChange(AuthUser? user) {
    if (user == null) {
      state = const AuthControllerState.unauthenticated();
      return;
    }
    _applyAuthenticatedState(user);
  }

  Future<void> _applyAuthenticatedState(AuthUser user) async {
    state = AuthControllerState.authenticated(user);
    await ref.read(_syncCurrentUserProfileFromMetadataUseCaseProvider).call();
    final requiresCompletion = await requiresProfileCompletion();

    if (!ref.mounted) {
      return;
    }

    state = AuthControllerState.authenticated(
      user,
      requiresProfileCompletion: requiresCompletion,
    );
  }
}
