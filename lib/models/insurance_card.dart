class InsuranceCard {
  final String? id;
  final String providerName;
  final String policyNumber;
  final String? frontImageUrl;
  final String? backImageUrl;
  final String? userId;
  final String? createdAt;

  InsuranceCard({
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
      id: map['id']?.toString(),
      providerName: map['providerName']?.toString() ??
          map['provider_name']?.toString() ??
          map['provider']?.toString() ??
          map['name']?.toString() ??
          map['title']?.toString() ??
          'Insurance Provider',
      policyNumber: map['policyNumber']?.toString() ??
          map['policy_number']?.toString() ??
          map['cardNumber']?.toString() ??
          map['card_number']?.toString() ??
          map['policyNo']?.toString() ??
          'N/A',
      frontImageUrl: map['frontImageUrl']?.toString() ?? map['front_image_url']?.toString(),
      backImageUrl: map['backImageUrl']?.toString() ?? map['back_image_url']?.toString(),
      userId: map['userId']?.toString() ?? map['user_id']?.toString(),
      createdAt: map['createdAt']?.toString() ?? map['created_at']?.toString(),
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
      'user_id': userId ?? 'guest',
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
    };
  }

  Map<String, dynamic> toJson() => toMap();
}
