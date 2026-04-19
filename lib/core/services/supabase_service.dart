import 'package:momen/core/config/app_environment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  static bool get initialized => _initialized;

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    if (!AppEnvironment.hasSupabaseConfig) {
      return;
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    _initialized = true;
  }
}
