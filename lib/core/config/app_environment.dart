class AppEnvironment {
  AppEnvironment._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const bool enableFirebaseCrashlytics = bool.fromEnvironment(
    'ENABLE_FIREBASE_CRASHLYTICS',
  );

  static const String googleOAuthRedirectUri = String.fromEnvironment(
    'GOOGLE_OAUTH_REDIRECT_URI',
    defaultValue: 'momen://auth-callback',
  );

  static const String passwordResetRedirectUri = String.fromEnvironment(
    'PASSWORD_RESET_REDIRECT_URI',
    defaultValue: 'momen://reset-password',
  );

  static const String apkDownloadUrl = String.fromEnvironment(
    'APK_DOWNLOAD_URL',
    defaultValue: '',
  );

  static bool get hasSupabaseConfig {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }
}
