import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'medication_alarm_channel';

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Medication alarm selected: ${response.id}');
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      await android?.requestFullScreenIntentPermission();
    }
  }

  static Future<void> scheduleMedicationReminder({
    required int id,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    String? imagePathOrUrl,
    bool alarmEnabled = true,
  }) async {
    if (!alarmEnabled) {
      debugPrint('Medication alarm disabled for $medicationName');
      return;
    }

    try {
      if (kIsWeb || !Platform.isAndroid) {
        debugPrint('Native medication alarm skipped on this platform.');
        return;
      }

      final scheduled = tz.TZDateTime.from(scheduledTime, tz.local);

      if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) {
        debugPrint('Medication alarm time is in the past.');
        return;
      }

      BigPictureStyleInformation? pictureStyle;

      if (imagePathOrUrl != null &&
          imagePathOrUrl.trim().isNotEmpty &&
          File(imagePathOrUrl).existsSync()) {
        final image = FilePathAndroidBitmap(imagePathOrUrl);

        pictureStyle = BigPictureStyleInformation(
          image,
          largeIcon: image,
          contentTitle: '⏰ $medicationName',
          summaryText: dosage,
          showBigPictureWhenCollapsed: true,
        );
      }

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        'Medication Alarms',
        channelDescription: 'Medication reminders and alarms.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: false,
        ongoing: true,
        autoCancel: false,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        styleInformation: pictureStyle,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      );

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: '⏰ $medicationName',
        body: 'Dosage: $dosage',
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: 'medication:$id',
      );

      debugPrint(
        'Medication alarm scheduled: $id at $scheduled',
      );
    } catch (e, stackTrace) {
      debugPrint('Error scheduling medication alarm: $e');
      debugPrint('$stackTrace');
    }
  }

  static Future<void> cancelForMedication(int id) async {
    await _notificationsPlugin.cancel(id: id);
    debugPrint('Medication alarm cancelled: $id');
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
