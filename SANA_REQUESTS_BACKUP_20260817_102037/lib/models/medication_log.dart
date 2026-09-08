class MedicationLog {
  final String? id;
  final String medicationId;

  /// Snapshot of the medication's name/dosage at the moment this log was
  /// created, so history entries stay meaningful and unchanged even if the
  /// medication itself is edited, its schedule changes, or it's deleted.
  final String medicationName;
  final String dosage;

  /// 'taken' | 'not_taken'
  final String status;
  final DateTime takenAt;

  MedicationLog({
    this.id,
    required this.medicationId,
    required this.medicationName,
    this.dosage = '',
    required this.status,
    required this.takenAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'medication_name': medicationName,
      'dosage': dosage,
      'status': status,
      'taken_at': takenAt.toIso8601String(),
    };
  }

  factory MedicationLog.fromMap(Map<String, dynamic> map) {
    return MedicationLog(
      id: map['id'],
      medicationId: map['medication_id'],
      medicationName: map['medication_name'] ?? 'Medication',
      dosage: map['dosage'] ?? '',
      status: map['status'],
      takenAt: DateTime.parse(map['taken_at']),
    );
  }
}
