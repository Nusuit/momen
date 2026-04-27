import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momen/app/routing/app_route.dart';
import 'package:momen/app/routing/main_tab.dart';
import 'package:momen/app/shell/main_shell.dart';
import 'package:momen/core/models/memory_item.dart';
import 'package:momen/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:momen/features/auth/presentation/pages/edit_profile_page.dart';
import 'package:momen/features/auth/presentation/pages/onboarding_page.dart';
import 'package:momen/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:momen/features/auth/presentation/pages/public_profile_page.dart';
import 'package:momen/features/auth/presentation/pages/reset_password_page.dart';
import 'package:momen/features/auth/presentation/pages/sign_in_page.dart';
import 'package:momen/features/auth/presentation/pages/sign_up_page.dart';
import 'package:momen/features/auth/presentation/state/auth_controller.dart';
import 'package:momen/features/feed/presentation/pages/detail_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateNotifier = ValueNotifier<AuthStatus>(AuthStatus.unknown);
  ref.onDispose(authStateNotifier.dispose);

  ref.listen(authControllerProvider, (_, state) {
    authStateNotifier.value = state.status;
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authStateNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      const guestPaths = {
        '/',
        '/sign-in',
        '/sign-up',
        '/forgot-password',
        '/reset-password',
        '/otp-verification',
        '/auth-callback',
      };

      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isGuestPath = guestPaths.contains(location);

      if (!isAuthenticated && !isGuestPath) {
        return '/sign-in';
      }

      if (isAuthenticated && authState.requiresProfileCompletion) {
        if (location != '/sign-in' && location != '/otp-verification') {
          return '/sign-in';
        }
        return null;
      }

      if (isAuthenticated && (location == '/' || location == '/sign-in')) {
        return '/main/camera';
      }

      return null;
    },
    routes: [
      GoRoute(
        name: AppRoute.onboarding.name,
        path: '/',
        builder: (context, state) => OnboardingPage(
          onComplete: () => context.goNamed(AppRoute.signIn.name),
          onSignUp: () => context.goNamed(AppRoute.signUp.name),
        ),
      ),
      GoRoute(
        name: AppRoute.signIn.name,
        path: '/sign-in',
        builder: (context, state) => SignInPage(
          onBack: () => context.goNamed(AppRoute.onboarding.name),
          onSignUp: () => context.goNamed(AppRoute.signUp.name),
          onForgotPassword: () => context.goNamed(AppRoute.forgotPassword.name),
          onOpenOtpVerification: (phone) => context.goNamed(
            AppRoute.otpVerification.name,
            queryParameters: {
              'channel': 'phone',
              'phone': phone,
            },
          ),
          onSignedIn: () => context.goNamed(
            AppRoute.mainTab.name,
            pathParameters: MainTab.camera.pathParameters,
          ),
        ),
      ),
      GoRoute(
        name: AppRoute.signUp.name,
        path: '/sign-up',
        builder: (context, state) => SignUpPage(
          onBack: () => context.goNamed(AppRoute.onboarding.name),
          onRequireOtpVerification: (channel, value) => context.goNamed(
            AppRoute.otpVerification.name,
            queryParameters: {
              'channel': channel == OtpChannel.phone ? 'phone' : 'email',
              if (channel == OtpChannel.phone) 'phone': value,
              if (channel == OtpChannel.email) 'email': value,
            },
          ),
          onSignIn: () => context.goNamed(AppRoute.signIn.name),
        ),
      ),
      GoRoute(
        name: AppRoute.forgotPassword.name,
        path: '/forgot-password',
        builder: (context, state) => ForgotPasswordPage(
          onBack: () => context.goNamed(AppRoute.signIn.name),
          onContinueToReset: (email) => context.goNamed(
            AppRoute.resetPassword.name,
            queryParameters: {'email': email},
          ),
        ),
      ),
      GoRoute(
        name: AppRoute.resetPassword.name,
        path: '/reset-password',
        builder: (context, state) => ResetPasswordPage(
          initialEmail: state.uri.queryParameters['email'],
          onBack: () => context.goNamed(AppRoute.forgotPassword.name),
          onCompleted: () => context.goNamed(AppRoute.signIn.name),
        ),
      ),
      GoRoute(
        name: AppRoute.otpVerification.name,
        path: '/otp-verification',
        builder: (context, state) {
          final channelParam = state.uri.queryParameters['channel'];
          final channel = channelParam == 'phone'
              ? OtpChannel.phone
              : OtpChannel.email;

          return OtpVerificationPage(
            initialEmail: state.uri.queryParameters['email'],
            initialPhone: state.uri.queryParameters['phone'],
            initialChannel: channel,
            onBack: () => context.goNamed(AppRoute.signIn.name),
            onVerified: () => context.goNamed(
              AppRoute.mainTab.name,
              pathParameters: MainTab.camera.pathParameters,
            ),
          );
        },
      ),
      GoRoute(
        name: AppRoute.authCallback.name,
        path: '/auth-callback',
        builder: (context, state) => SignInPage(
          onBack: () => context.goNamed(AppRoute.onboarding.name),
          onSignUp: () => context.goNamed(AppRoute.signUp.name),
          onForgotPassword: () => context.goNamed(AppRoute.forgotPassword.name),
          onOpenOtpVerification: (phone) => context.goNamed(
            AppRoute.otpVerification.name,
            queryParameters: {
              'channel': 'phone',
              'phone': phone,
            },
          ),
          onSignedIn: () => context.goNamed(
            AppRoute.mainTab.name,
            pathParameters: MainTab.camera.pathParameters,
          ),
        ),
      ),
      GoRoute(
        name: AppRoute.friendProfile.name,
        path: '/friend-profile',
        builder: (context, state) => PublicProfilePage(
          userId: state.uri.queryParameters['uid'] ?? '',
          onBack: () => context.goNamed(
            AppRoute.mainTab.name,
            pathParameters: MainTab.profile.pathParameters,
          ),
        ),
      ),
      GoRoute(
        name: AppRoute.mainTab.name,
        path: '/main/:tab',
        builder: (context, state) {
          final tab = MainTabX.fromRouteName(state.pathParameters['tab']);
          return MainShell(tab: tab);
        },
      ),
      GoRoute(
        name: AppRoute.editProfile.name,
        path: '/edit-profile',
        builder: (context, state) => EditProfilePage(
          onBack: () => context.goNamed(
            AppRoute.mainTab.name,
            pathParameters: MainTab.profile.pathParameters,
          ),
        ),
      ),
      GoRoute(
        name: AppRoute.detail.name,
        path: '/detail',
        builder: (context, state) {
          final extra = state.extra;
          return DetailPage(
            memory: extra is MemoryItem ? extra : null,
            onBack: () => context.goNamed(
              AppRoute.mainTab.name,
              pathParameters: MainTab.camera.pathParameters,
            ),
          );
        },
      ),
    ],
  );
});
