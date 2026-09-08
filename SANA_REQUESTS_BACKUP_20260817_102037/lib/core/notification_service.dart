import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await plugin.initialize(settings: settings);

    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> scheduleMedicationReminder({
    required int id,
    required String medicineName,
    required String quantity,
    required DateTime time,
    required String image,
  }) async {
    final scheduledDate = tz.TZDateTime.from(
      time,
      tz.local,
    );

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_channel',
        'Medication Alerts',
        channelDescription: 'Medication reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await plugin.zonedSchedule(
      id: id,
      title: 'Medication Reminder',
      body: '$medicineName - Quantity: $quantity',
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelReminder(int id) async {
    await plugin.cancel(id: id);
  }
}
