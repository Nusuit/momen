enum AppRoute {
  onboarding,
  signIn,
  signUp,
  forgotPassword,
  resetPassword,
  otpVerification,
  authCallback,
  friendProfile,
  mainTab,
  editProfile,
  detail,
}

extension AppRouteName on AppRoute {
  String get name => switch (this) {
        AppRoute.onboarding => 'onboarding',
        AppRoute.signIn => 'sign-in',
        AppRoute.signUp => 'sign-up',
        AppRoute.forgotPassword => 'forgot-password',
        AppRoute.resetPassword => 'reset-password',
        AppRoute.otpVerification => 'otp-verification',
        AppRoute.authCallback => 'auth-callback',
        AppRoute.friendProfile => 'friend-profile',
        AppRoute.mainTab => 'main-tab',
        AppRoute.editProfile => 'edit-profile',
        AppRoute.detail => 'detail',
      };
}
