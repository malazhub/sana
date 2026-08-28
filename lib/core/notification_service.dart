import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'medication_channel';
  static const String _channelName = 'Medication Alerts';
  static const String _channelDescription = 'Medication reminder notifications';

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: settings,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
  }

  // ===========================================================================
  // SCHEDULE MEDICATION REMINDER
  // ===========================================================================

  static Future<void> scheduleMedicationReminder({
    required int id,
    required String medicineName,
    required String quantity,
    required DateTime time,
    String image = '',
  }) async {
    final scheduledDate = tz.TZDateTime.from(
      time,
      tz.local,
    );

    final now = tz.TZDateTime.now(tz.local);

    if (scheduledDate.isBefore(now)) {
      debugPrint(
        'Medication reminder not scheduled because '
        'the requested time has already passed.',
      );
      return;
    }

    final notificationDetails = await _buildNotificationDetails(image);

    await _notifications.zonedSchedule(
      id: id,
      title: 'Medication Reminder',
      body: '$medicineName - Quantity: $quantity',
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // ===========================================================================
  // NOTIFICATION DETAILS
  // ===========================================================================

  static Future<NotificationDetails> _buildNotificationDetails(
    String image,
  ) async {
    StyleInformation styleInformation;

    final imagePath = image.trim();

    if (!kIsWeb && imagePath.isNotEmpty && File(imagePath).existsSync()) {
      styleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(imagePath),
        largeIcon: FilePathAndroidBitmap(imagePath),
        contentTitle: 'Medication Reminder',
        summaryText: 'Time to take your medication',
      );
    } else {
      styleInformation = const BigTextStyleInformation(
        'Time to take your medication.',
      );
    }

    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: styleInformation,
        icon: '@mipmap/ic_launcher',
      ),
    );
  }

  // ===========================================================================
  // CANCEL ONE REMINDER
  // ===========================================================================

  static Future<void> cancelReminder(
    int id,
  ) async {
    await _notifications.cancel(
      id: id,
    );
  }

  // ===========================================================================
  // CANCEL ALL REMINDERS
  // ===========================================================================

  static Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }
}
