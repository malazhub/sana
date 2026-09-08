class Pharmacy {
  final String id;
  final String name;
  final String? address;
  final String? phone;

  Pharmacy({
    required this.id,
    required this.name,
    this.address,
    this.phone,
  });

  factory Pharmacy.fromMap(Map<String, dynamic> map) {
    return Pharmacy(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      address: map['address']?.toString() ?? map['location']?.toString() ?? '',
      phone: map['phone']?.toString() ?? map['phoneNumber']?.toString() ?? '',
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
}
