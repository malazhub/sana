import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medication_log.dart';
import '../providers/medication_provider.dart';

class MedicationHistoryScreen extends StatelessWidget {
  const MedicationHistoryScreen({super.key});

  String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _friendlyDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicationProvider>();
    final logs = List<MedicationLog>.from(provider.logs)
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));

    if (provider.isLoading && logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No history yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Every Taken / Not Taken response you log will show up here permanently',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Group by day, most recent first.
    final Map<String, List<MedicationLog>> grouped = {};
    for (final log in logs) {
      grouped.putIfAbsent(_dateKey(log.takenAt), () => []).add(log);
    }
    final orderedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orderedKeys.length,
      itemBuilder: (context, sectionIndex) {
        final key = orderedKeys[sectionIndex];
        final dayLogs = grouped[key]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4, left: 4),
              child: Text(
                _friendlyDate(dayLogs.first.takenAt),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.teal,
                ),
              ),
            ),
            ...dayLogs.map((log) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: log.status == 'taken'
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      child: Icon(
                        log.status == 'taken'
                            ? Icons.check_circle
                            : Icons.cancel,
                        color:
                            log.status == 'taken' ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(log.medicationName),
                    subtitle: Text(
                      '${log.dosage.isNotEmpty ? '${log.dosage} â€¢ ' : ''}'
                      '${log.takenAt.hour.toString().padLeft(2, '0')}:'
                      '${log.takenAt.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: Text(
                      log.status == 'taken' ? 'Taken' : 'Not Taken',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            log.status == 'taken' ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }
}
