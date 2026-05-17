import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ── INITIALIZE ────────────────────────────────────────────
  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const ios = DarwinInitializationSettings();

    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings: settings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
  }

  // ── SHOW IMMEDIATE ────────────────────────────────────────
  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();

    const android = AndroidNotificationDetails(
      'storepro_channel',
      'StorePro Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: android);

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  // ── SCHEDULE ──────────────────────────────────────────────
  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await init();

    const android = AndroidNotificationDetails(
      'storepro_scheduled',
      'StorePro Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: android);

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  // ── CANCEL ────────────────────────────────────────────────
  static Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }

  // ── CANCEL ALL ────────────────────────────────────────────
  static Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
