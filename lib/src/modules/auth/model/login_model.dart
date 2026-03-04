import 'package:write_up/src/modules/auth/model/user_model.dart';

class LoginRequestModel {
  final String email;
  final String password;

  LoginRequestModel({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class LoginResponseModel {
  final bool success;
  final String message;
  final String? token;
  final User? user;

  LoginResponseModel({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    // Check for user data in multiple possible keys
    final userData = json['data'] ?? json['user'];

    // Look for token at top level or inside data/user
    String? token = json['token']?.toString();
    if (token == null && userData is Map<String, dynamic>) {
      token = userData['token']?.toString();
    }

    // Determine if there's enough data to attempt creating a User object
    // This could be from 'data'/'user' keys, or if the top-level json itself contains user-like fields
    final bool hasUserData =
        userData != null ||
        json.containsKey('id') ||
        json.containsKey('email') ||
        json.containsKey('name'); // Add other common user fields as needed

    return LoginResponseModel(
      success: json['success'] ?? (token != null),
      message: json['message'] ?? '',
      token: token,
      user: hasUserData
          ? User.fromJson(userData is Map<String, dynamic> ? userData : json)
          : null,
    );
  }
}
