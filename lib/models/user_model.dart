class UserModel {

  final String id;
  final String name;
  final String email;
  final String phone;
  final String language;
  final DateTime createdAt;


  UserModel({

    required this.id,

    required this.name,

    required this.email,

    required this.phone,

    required this.language,

    required this.createdAt,

  });



  factory UserModel.fromJson(
      Map<String, dynamic> json) {

    return UserModel(

      id: json['id'] ?? '',

      name: json['name'] ?? '',

      email: json['email'] ?? '',

      phone: json['phone'] ?? '',

      language: json['language'] ?? 'en',

      createdAt:
          DateTime.parse(
            json['created_at'],
          ),

    );

  }



  Map<String, dynamic> toJson() {

    return {

      'id': id,

      'name': name,

      'email': email,

      'phone': phone,

      'language': language,

      'created_at':
          createdAt.toIso8601String(),

    };

  }

}