import 'dart:async';

import '../models/medication.dart';

typedef ReminderCallback = void Function(
  Medication med,
  String time,
);

class InlineReminderService {
  InlineReminderService._();

  static final Map<String, Timer> _timers = {};

  // ============================================================
  // CANCEL ALL REMINDERS
  // ============================================================

  static void cancelAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }

    _timers.clear();
  }

  // ============================================================
  // START REMINDERS
  // ============================================================

  static void startForMedications(
    List<Medication> medications,
    ReminderCallback onTrigger,
  ) {
    cancelAll();

    final now = DateTime.now();

    for (final medication in medications) {
      final reminderTime = medication.reminderTime?.trim();

      if (reminderTime == null || reminderTime.isEmpty) {
        continue;
      }

      _scheduleMedication(
        medication: medication,
        time: reminderTime,
        now: now,
        onTrigger: onTrigger,
      );
    }
  }

  // ============================================================
  // SCHEDULE ONE MEDICATION
  // ============================================================

  static void _scheduleMedication({
    required Medication medication,
    required String time,
    required DateTime now,
    required ReminderCallback onTrigger,
  }) {
    final parsedTime = _parseTime(time);

    if (parsedTime == null) {
      return;
    }

    final hour = parsedTime.hour;
    final minute = parsedTime.minute;

    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If today's reminder already passed,
    // schedule it for tomorrow.
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(
        const Duration(days: 1),
      );
    }

    final key = '${medication.id}-$time';

    final delay = scheduled.difference(now);

    _timers[key]?.cancel();

    _timers[key] = Timer(
      delay,
      () {
        _handleReminder(
          medication: medication,
          time: time,
          key: key,
          onTrigger: onTrigger,
        );
      },
    );
  }

  // ============================================================
  // HANDLE REMINDER
  // ============================================================

  static void _handleReminder({
    required Medication medication,
    required String time,
    required String key,
    required ReminderCallback onTrigger,
  }) {
    try {
      onTrigger(
        medication,
        time,
      );
    } finally {
      _timers.remove(key);

      // The current Medication model does not contain
      // a repeatType field.
      //
      // reminderTime is therefore treated as a daily
      // reminder and automatically scheduled again.
      _scheduleNextDailyReminder(
        medication: medication,
        time: time,
        key: key,
        onTrigger: onTrigger,
      );
    }
  }

  // ============================================================
  // SCHEDULE NEXT DAILY REMINDER
  // ============================================================

  static void _scheduleNextDailyReminder({
    required Medication medication,
    required String time,
    required String key,
    required ReminderCallback onTrigger,
  }) {
    final parsedTime = _parseTime(time);

    if (parsedTime == null) {
      return;
    }

    final now = DateTime.now();

    final nextScheduled = DateTime(
      now.year,
      now.month,
      now.day + 1,
      parsedTime.hour,
      parsedTime.minute,
    );

    final delay = nextScheduled.difference(now);

    _timers[key] = Timer(
      delay,
      () {
        _handleReminder(
          medication: medication,
          time: time,
          key: key,
          onTrigger: onTrigger,
        );
      },
    );
  }

  // ============================================================
  // PARSE REMINDER TIME
  // ============================================================
  //
  // Supports:
  //
  //   08:00
  //   8:00
  //   18:30
  //   8:00 AM
  //   8:00 PM
  //   12:00 AM
  //   12:00 PM
  //
  // ============================================================

  static _ParsedTime? _parseTime(
    String value,
  ) {
    final input = value.trim();

    if (input.isEmpty) {
      return null;
    }

    // ----------------------------------------------------------
    // 12-hour format:
    //
    // 8:00 AM
    // 8:00 PM
    // ----------------------------------------------------------

    final twelveHourMatch = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(input);

    if (twelveHourMatch != null) {
      final hour = int.tryParse(
        twelveHourMatch.group(1)!,
      );

      final minute = int.tryParse(
        twelveHourMatch.group(2)!,
      );

      final period = twelveHourMatch.group(3)!.toUpperCase();

      if (hour == null ||
          minute == null ||
          hour < 1 ||
          hour > 12 ||
          minute < 0 ||
          minute > 59) {
        return null;
      }

      var convertedHour = hour;

      if (period == 'AM') {
        if (convertedHour == 12) {
          convertedHour = 0;
        }
      } else {
        if (convertedHour != 12) {
          convertedHour += 12;
        }
      }

      return _ParsedTime(
        hour: convertedHour,
        minute: minute,
      );
    }

    // ----------------------------------------------------------
    // 24-hour format:
    //
    // 08:00
    // 18:30
    // ----------------------------------------------------------

    final twentyFourHourMatch = RegExp(
      r'^(\d{1,2}):(\d{2})$',
    ).firstMatch(input);

    if (twentyFourHourMatch != null) {
      final hour = int.tryParse(
        twentyFourHourMatch.group(1)!,
      );

      final minute = int.tryParse(
        twentyFourHourMatch.group(2)!,
      );

      if (hour == null ||
          minute == null ||
          hour < 0 ||
          hour > 23 ||
          minute < 0 ||
          minute > 59) {
        return null;
      }

      return _ParsedTime(
        hour: hour,
        minute: minute,
      );
    }

    return null;
  }

  // ============================================================
  // CANCEL ONE MEDICATION
  // ============================================================

  static void cancelMedication(
    Medication medication,
  ) {
    final reminderTime = medication.reminderTime?.trim();

    if (reminderTime == null || reminderTime.isEmpty) {
      return;
    }

    final key = '${medication.id}-$reminderTime';

    final timer = _timers.remove(key);

    timer?.cancel();
  }

  // ============================================================
  // GET ACTIVE TIMER COUNT
  // ============================================================

  static int get activeTimerCount {
    return _timers.length;
  }
}

// ============================================================
// INTERNAL PARSED TIME MODEL
// ============================================================

class _ParsedTime {
  final int hour;
  final int minute;

  const _ParsedTime({
    required this.hour,
    required this.minute,
  });
}
