import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class SanaNotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const String _payloadType = 'sana_medication_alarm';

  static const Map<String, Map<String, String>> _alarmTranslations = {
    'en': {
      'title': 'SANA — Medication Time',
      'body': 'Time to take',
      'action': 'Take medication',
    },
    'ar': {
      'title': 'سانا — موعد الدواء',
      'body': 'حان وقت تناول',
      'action': 'تناول الدواء',
    },
    'es': {
      'title': 'SANA — Hora de la medicación',
      'body': 'Hora de tomar',
      'action': 'Tomar medicamento',
    },
    'fr': {
      'title': 'SANA — Heure du médicament',
      'body': 'Il est temps de prendre',
      'action': 'Prendre le médicament',
    },
    'de': {
      'title': 'SANA — Medikamentenzeit',
      'body': 'Zeit für die Einnahme von',
      'action': 'Medikament einnehmen',
    },
    'tr': {
      'title': 'SANA — İlaç Zamanı',
      'body': 'İlaç alma zamanı:',
      'action': 'İlacı al',
    },
    'hi': {
      'title': 'SANA — दवा का समय',
      'body': 'दवा लेने का समय:',
      'action': 'दवा लें',
    },
    'zh': {
      'title': 'SANA — 服药时间',
      'body': '该服药了：',
      'action': '服药',
    },
  };

  static Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );

    _initialized = true;
  }

  static Future<void> scheduleMedicationReminder({
    required int id,
    required String title,
    required String body,
    required List<String> reminderTimes,
    String language = 'en',
  }) async {
    await init();

    final Map<String, String> langData =
        _alarmTranslations[language.toLowerCase()] ?? _alarmTranslations['en']!;

    final String alarmTitle = langData['title']!;
    final String actionLabel = langData['action']!;
    final String bodyPrefix = langData['body']!;

    final String bodyText = body.trim().isEmpty
        ? '$bodyPrefix $title'
        : '$bodyPrefix $title — $body';

    for (int i = 0; i < reminderTimes.length; i++) {
      final String timeStr = reminderTimes[i];

      final List<String> parts = timeStr.split(':');

      if (parts.length != 2) continue;

      final int hour = int.tryParse(parts[0]) ?? 0;
      final int minute = int.tryParse(parts[1]) ?? 0;

      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(
          const Duration(days: 1),
        );
      }

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'sana_med_channel',
        'Medication Reminders',
        channelDescription: 'Closed-app alarms for medication',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        autoCancel: false,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'SANA_TAKE_MEDICATION',
            actionLabel,
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      try {
        await _notificationsPlugin.zonedSchedule(
          id: id * 100 + i,
          title: alarmTitle,
          body: bodyText,
          scheduledDate: scheduledDate,
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {}
    }
  }

  static Future<void> syncMedications(
    List<Map<String, dynamic>> medications, {
    String language = 'en',
  }) async {
    await init();

    for (final Map<String, dynamic> medication in medications) {
      final String id = medication['id']?.toString().trim() ?? '';

      if (id.isEmpty) continue;

      final dynamic rawTimes = medication['reminder_times'] ??
          medication['reminderTimes'] ??
          medication['reminder_time'];

      List<String> times = <String>[];

      if (rawTimes is List) {
        times = rawTimes
            .map(
              (dynamic value) => value.toString().trim(),
            )
            .where(
              (String value) => value.isNotEmpty,
            )
            .toList();
      } else if (rawTimes != null) {
        final String value = rawTimes.toString().trim();

        if (value.isNotEmpty) {
          times = <String>[value];
        }
      }

      if (times.isEmpty) continue;

      await cancelMedicationReminders(
        id.hashCode,
        times.length,
      );

      await scheduleMedicationReminder(
        id: id.hashCode,
        title: medication['name']?.toString() ?? 'Medication',
        body: medication['dosage']?.toString() ?? '',
        reminderTimes: times,
        language: language,
      );
    }
  }

  static Future<void> cancelMedicationReminders(
    int id,
    int maxTimesCount,
  ) async {
    await init();

    for (int i = 0; i < maxTimesCount; i++) {
      try {
        await _notificationsPlugin.cancel(
          id: id * 100 + i,
        );
      } catch (_) {}
    }
  }
}
