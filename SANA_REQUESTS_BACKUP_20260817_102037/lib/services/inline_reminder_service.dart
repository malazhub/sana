import 'dart:async';

import '../models/medication.dart';

typedef ReminderCallback = void Function(Medication med, String time);

class InlineReminderService {
  static final Map<String, Timer> _timers = {};

  static void cancelAll() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }

  static void startForMedications(
      List<Medication> meds, ReminderCallback onTrigger) {
    cancelAll();
    final now = DateTime.now();

    for (final med in meds) {
      for (final time in med.reminderTimes) {
        final parts = time.split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;

        var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
        if (scheduled.isBefore(now))
          scheduled = scheduled.add(const Duration(days: 1));

        final key = '${med.id}-$time';
        final delay = scheduled.difference(now);
        _timers[key] = Timer(delay, () {
          try {
            onTrigger(med, time);
          } finally {
            // Reschedule next occurrence if repeating daily
            if (med.repeatType == 'daily') {
              final nextKey = key;
              final nextDelay = const Duration(days: 1);
              _timers[nextKey] = Timer(nextDelay, () {
                onTrigger(med, time);
                // keep rescheduling by calling startForMedications again would be heavier;
                // we'll rely on app lifecycle to re-init timers when needed.
              });
            }
            _timers.remove(key);
          }
        });
      }
    }
  }
}
