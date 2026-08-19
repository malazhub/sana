import 'dart:convert';

class Medication {
  final String id;
  final String name;
  final String dosage;
  final int quantity;
  final List<String> reminderTimes;
  final String repeatType;
  final String? photoUrl;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.quantity,
    required this.reminderTimes,
    required this.repeatType,
    this.photoUrl,
  });

  factory Medication.fromMap(Map<String, dynamic> map) {
    List<String> parseTimes(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw is String) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      return [];
    }

    return Medication(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      dosage: map['dosage']?.toString() ?? '',
      quantity: int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
      reminderTimes: parseTimes(map['reminder_times'] ?? map['reminderTimes']),
      repeatType: map['repeat_type']?.toString() ??
          map['repeatType']?.toString() ??
          'Daily',
      photoUrl: map['photo_url']?.toString() ?? map['photoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'quantity': quantity,
      'reminder_times': reminderTimes,
      'reminderTimes': reminderTimes,
      'repeat_type': repeatType,
      'repeatType': repeatType,
      'photo_url': photoUrl ?? '',
      'photoUrl': photoUrl ?? '',
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'quantity': quantity,
      'reminder_times': reminderTimes,
      'repeat_type': repeatType,
      'photo_url': photoUrl ?? '',
    };
  }

  Map<String, dynamic> toJson() => toMap();
}
