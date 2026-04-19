import 'package:flutter/widgets.dart';
import 'package:momen/core/config/app_environment.dart';
import 'package:momen/core/observability/local_notification_service.dart';
import 'package:momen/core/observability/crash_reporting_service.dart';
import 'package:momen/core/services/supabase_service.dart';

class AppBootstrap {
  const AppBootstrap._();

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    await SupabaseService.initialize(
      url: AppEnvironment.supabaseUrl,
      anonKey: AppEnvironment.supabaseAnonKey,
    );

    await CrashReportingService.initialize(
      enabled: AppEnvironment.enableFirebaseCrashlytics,
    );

    await LocalNotificationService.initialize();
  }
}
