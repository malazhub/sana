import 'dart:convert';

class Medication {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final int quantity;
  final List<String> reminderTimes;
  final String repeatType;
  final String? photoUrl;

  const Medication({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.quantity,
    required this.reminderTimes,
    required this.repeatType,
    this.photoUrl,
  });

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ??
          map['userId']?.toString() ??
          '',
      name: map['name']?.toString() ?? '',
      dosage: map['dosage']?.toString() ?? '',
      quantity: _parseQuantity(map['quantity']),
      reminderTimes: _parseReminderTimes(
        map['reminder_times'] ?? map['reminderTimes'],
      ),
      repeatType: map['repeat_type']?.toString() ??
          map['repeatType']?.toString() ??
          'Daily',
      photoUrl: _nullableString(
        map['photo_url'] ?? map['photoUrl'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'dosage': dosage,
      'quantity': quantity,
      'reminder_times': reminderTimes,
      'repeat_type': repeatType,
      'photo_url': photoUrl,
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'dosage': dosage,
      'quantity': quantity,
      'reminder_times': reminderTimes,
      'repeat_type': repeatType,
      'photo_url': photoUrl,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  Medication copyWith({
    String? id,
    String? userId,
    String? name,
    String? dosage,
    int? quantity,
    List<String>? reminderTimes,
    String? repeatType,
    String? photoUrl,
  }) {
    return Medication(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      quantity: quantity ?? this.quantity,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      repeatType: repeatType ?? this.repeatType,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  static int _parseQuantity(dynamic value) {
    final parsed = int.tryParse(value?.toString() ?? '');

    if (parsed == null || parsed < 0) {
      return 0;
    }

    return parsed;
  }

  static List<String> _parseReminderTimes(dynamic raw) {
    if (raw == null) {
      return const [];
    }

    if (raw is List) {
      return raw
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (raw is String) {
      final value = raw.trim();

      if (value.isEmpty) {
        return const [];
      }

      try {
        final decoded = jsonDecode(value);

        if (decoded is List) {
          return decoded
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList();
        }
      } catch (_) {
        // Fall through and treat it as a single value.
      }

      return [value];
    }

    return const [];
  }

  static String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    return result.isEmpty ? null : result;
  }
}