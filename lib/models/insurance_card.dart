class InsuranceCard {
  final String? id;
  final String providerName;
  final String policyNumber;
  final String? frontImageUrl;
  final String? backImageUrl;
  final String? userId;
  final String? createdAt;

  const InsuranceCard({
    this.id,
    required this.providerName,
    required this.policyNumber,
    this.frontImageUrl,
    this.backImageUrl,
    this.userId,
    this.createdAt,
  });

  factory InsuranceCard.fromMap(Map<String, dynamic> map) {
    return InsuranceCard(
      id: _nullableString(map['id']),
      providerName: _stringValue(
        map['providerName'] ??
            map['provider_name'] ??
            map['provider'] ??
            map['name'] ??
            map['title'],
        fallback: 'Insurance Provider',
      ),
      policyNumber: _stringValue(
        map['policyNumber'] ??
            map['policy_number'] ??
            map['cardNumber'] ??
            map['card_number'] ??
            map['policyNo'],
        fallback: 'N/A',
      ),
      frontImageUrl: _nullableString(
        map['frontImageUrl'] ?? map['front_image_url'],
      ),
      backImageUrl: _nullableString(
        map['backImageUrl'] ?? map['back_image_url'],
      ),
      userId: _nullableString(
        map['userId'] ?? map['user_id'],
      ),
      createdAt: _nullableString(
        map['createdAt'] ?? map['created_at'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'provider_name': providerName,
      'providerName': providerName,
      'policy_number': policyNumber,
      'policyNumber': policyNumber,
      'front_image_url': frontImageUrl ?? '',
      'frontImageUrl': frontImageUrl ?? '',
      'back_image_url': backImageUrl ?? '',
      'backImageUrl': backImageUrl ?? '',
      'user_id': userId ?? '',
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'provider_name': providerName,
      'policy_number': policyNumber,
      'front_image_url': frontImageUrl ?? '',
      'back_image_url': backImageUrl ?? '',
      'user_id': userId,
      'created_at': createdAt,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  InsuranceCard copyWith({
    String? id,
    String? providerName,
    String? policyNumber,
    String? frontImageUrl,
    String? backImageUrl,
    String? userId,
    String? createdAt,
  }) {
    return InsuranceCard(
      id: id ?? this.id,
      providerName: providerName ?? this.providerName,
      policyNumber: policyNumber ?? this.policyNumber,
      frontImageUrl: frontImageUrl ?? this.frontImageUrl,
      backImageUrl: backImageUrl ?? this.backImageUrl,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String _stringValue(
    dynamic value, {
    required String fallback,
  }) {
    final result = value?.toString().trim();

    if (result == null || result.isEmpty) {
      return fallback;
    }

    return result;
  }

  static String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    return result.isEmpty ? null : result;
  }
}