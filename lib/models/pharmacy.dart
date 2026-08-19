class Pharmacy {
  final String id;
  final String name;
  final String? address;
  final String? phone;

  const Pharmacy({
    required this.id,
    required this.name,
    this.address,
    this.phone,
  });

  factory Pharmacy.fromMap(Map<String, dynamic> map) {
    return Pharmacy(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      address: _nullableString(
        map['address'] ?? map['location'],
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
      'address': address ?? '',
      'phone': phone ?? '',
    };
  }

  Map<String, dynamic> toJson() => toMap();

  Pharmacy copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
  }) {
    return Pharmacy(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
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