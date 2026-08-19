class MedicationLog {
  final String? id;
  final String medicationId;
  final String medicationName;
  final String dosage;
  final String status;
  final DateTime takenAt;

  const MedicationLog({
    this.id,
    required this.medicationId,
    required this.medicationName,
    this.dosage = '',
    required this.status,
    required this.takenAt,
  });

  factory MedicationLog.fromMap(
    Map<String, dynamic> map,
  ) {
    return MedicationLog(
      id: _nullableString(map['id']),
      medicationId:
          map['medication_id']?.toString() ??
          map['medicationId']?.toString() ??
          '',
      medicationName:
          map['medication_name']?.toString() ??
          map['medicationName']?.toString() ??
          'Medication',
      dosage:
          map['dosage']?.toString() ?? '',
      status:
          map['status']?.toString().trim().toLowerCase() ??
          'not_taken',
      takenAt: _parseDateTime(
        map['taken_at'] ?? map['takenAt'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'medication_id': medicationId,
      'medication_name': medicationName,
      'dosage': dosage,
      'status': status,
      'taken_at': takenAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  MedicationLog copyWith({
    String? id,
    String? medicationId,
    String? medicationName,
    String? dosage,
    String? status,
    DateTime? takenAt,
  }) {
    return MedicationLog(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      status: status ?? this.status,
      takenAt: takenAt ?? this.takenAt,
    );
  }

  bool get isTaken => status == 'taken';

  bool get isNotTaken => status == 'not_taken';

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    final parsed = DateTime.tryParse(
      value?.toString() ?? '',
    );

    return parsed ?? DateTime.now();
  }

  static String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    return result.isEmpty ? null : result;
  }
}