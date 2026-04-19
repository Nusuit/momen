import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReportingService {
  CrashReportingService._();

  static bool _enabled = false;

  static bool get enabled => _enabled;

  static Future<void> initialize({required bool enabled}) async {
    if (!enabled || kIsWeb) {
      return;
    }

    await Firebase.initializeApp();
    _enabled = true;

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(
        FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          fatal: true,
        ),
      );
      return true;
    };
  }
}
