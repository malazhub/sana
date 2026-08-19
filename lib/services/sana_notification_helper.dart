import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class SanaNotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    // Updated to use the named parameter 'settings'
    await _notificationsPlugin.initialize(settings: initializationSettings);
    _initialized = true;
  }

  static Future<void> scheduleMedicationReminder({
    required int id,
    required String title,
    required String body,
    required List<String> reminderTimes,
  }) async {
    await init();
    for (int i = 0; i < reminderTimes.length; i++) {
      final timeStr = reminderTimes[i];
      final parts = timeStr.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'sana_med_channel',
        'Medication Reminders',
        channelDescription: 'Closed-app alarms for medication',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      try {
        // Updated to strictly use named parameters and removed deprecated date interpretation parameter
        await _notificationsPlugin.zonedSchedule(
          id: id * 100 + i,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {}
    }
  }

  static Future<void> cancelMedicationReminders(int id, int maxTimesCount) async {
    await init();
    for (int i = 0; i < maxTimesCount; i++) {
      try {
        // Updated to use named parameter 'id'
        await _notificationsPlugin.cancel(id: id * 100 + i);
      } catch (_) {}
    }
  }
}