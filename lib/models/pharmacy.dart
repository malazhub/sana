class Pharmacy {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? userId;
  final String? guestId;

  const Pharmacy({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.userId,
    this.guestId,
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
      userId: _nullableString(
        map['user_id'] ?? map['userId'],
      ),
      guestId: _nullableString(
        map['guest_id'] ?? map['guestId'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address ?? '',
      'phone': phone ?? '',
      'user_id': userId,
      'guest_id': guestId,
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'user_id': userId,
      'guest_id': guestId,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  Pharmacy copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? userId,
    String? guestId,
  }) {
    return Pharmacy(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      userId: userId ?? this.userId,
      guestId: guestId ?? this.guestId,
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;

    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }
}
