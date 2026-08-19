class Doctor {
  final String id;
  final String name;
  final String? specialty;
  final String? phone;

  Doctor({
    required this.id,
    required this.name,
    this.specialty,
    this.phone,
  });

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      specialty:
          map['specialty']?.toString() ?? map['speciality']?.toString() ?? '',
      phone: map['phone']?.toString() ?? map['phoneNumber']?.toString() ?? '',
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
}
