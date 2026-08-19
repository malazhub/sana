class Doctor {
  final String id;
  final String name;
  final String? specialty;
  final String? phone;

  const Doctor({
    required this.id,
    required this.name,
    this.specialty,
    this.phone,
  });

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      specialty: _nullableString(
        map['specialty'] ?? map['speciality'],
      ),
      phone: _nullableString(
        map['phone'] ?? map['phoneNumber'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty ?? '',
      'phone': phone ?? '',
    };
  }

  Map<String, dynamic> toJson() => toMap();

  Doctor copyWith({
    String? id,
    String? name,
    String? specialty,
    String? phone,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      phone: phone ?? this.phone,
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    return result.isEmpty ? null : result;
  }
}