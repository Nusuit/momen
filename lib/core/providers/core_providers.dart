import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momen/core/config/app_environment.dart';
import 'package:momen/core/persistence/local_database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  final service = LocalDatabaseService();
  ref.onDispose(service.close);
  return service;
});

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!AppEnvironment.hasSupabaseConfig) {
    return null;
  }

  return Supabase.instance.client;
});
