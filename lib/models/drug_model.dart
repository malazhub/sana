class DrugModel {
  final String id;

  final String name;

  final String category;

  final String description;

  final String photoUrl;

  final String dosage;

  final String unit;

  final DateTime createdAt;

  DrugModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.photoUrl,
    required this.dosage,
    required this.unit,
    required this.createdAt,
  });

  factory DrugModel.fromJson(Map<String, dynamic> json) {
    return DrugModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      dosage: json['dosage'] ?? '',
      unit: json['unit'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'photo_url': photoUrl,
      'dosage': dosage,
      'unit': unit,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
