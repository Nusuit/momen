import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _revealChannel =
      AndroidNotificationChannel(
    'reveal_reminder_channel',
    'Reveal Reminders',
    description: 'Reminders to reveal posts after 3 days',
    importance: Importance.high,
  );

  static const String _sentReminderIdsKey = 'sent_reveal_notification_ids';
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(_revealChannel);

    _initialized = true;
  }

  static Future<void> notifyRevealReminder({
    required String reminderId,
    required String title,
    required String body,
  }) async {
    await initialize();

    final sentIds = await _getSentIds();
    if (sentIds.contains(reminderId)) {
      return;
    }

    final notificationId = _toNotificationId(reminderId);
    await _plugin.show(
      notificationId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reveal_reminder_channel',
          'Reveal Reminders',
          channelDescription: 'Reminders to reveal posts after 3 days',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );

    sentIds.add(reminderId);
    await _saveSentIds(sentIds);
  }

  static Future<void> markReminderResolved(String reminderId) async {
    await initialize();
    await _plugin.cancel(_toNotificationId(reminderId));

    final sentIds = await _getSentIds();
    if (!sentIds.remove(reminderId)) {
      return;
    }
    await _saveSentIds(sentIds);
  }

  static int _toNotificationId(String reminderId) {
    return reminderId.hashCode & 0x7fffffff;
  }

  static Future<Set<String>> _getSentIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sentReminderIdsKey);
    if (raw == null || raw.isEmpty) {
      return <String>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <String>{};
      }
      return decoded.whereType<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<void> _saveSentIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sentReminderIdsKey, jsonEncode(ids.toList()));
  }
}
