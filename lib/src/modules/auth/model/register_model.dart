import 'package:write_up/src/modules/auth/model/user_model.dart';

class RegisterRequestModel {
  final String name;
  final String email;
  final String password;

  RegisterRequestModel({
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'password': password,
  };
}

class RegisterResponseModel {
  final bool success;
  final String message;
  final String? token;
  final User? user;

  RegisterResponseModel({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    // Check for user data in multiple possible keys
    final userData = json['data'] ?? json['user'];

    // Look for token at top level or inside data/user
    String? token = json['token']?.toString();
    if (token == null && userData is Map<String, dynamic>) {
      token = userData['token']?.toString();
    }

    return RegisterResponseModel(
      success: json['success'] ?? (token != null),
      message: json['message'] ?? '',
      token: token,
      user: User.fromJson(userData is Map<String, dynamic> ? userData : json),
    );
  }
}
