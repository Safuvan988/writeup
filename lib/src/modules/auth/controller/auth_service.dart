import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:write_up/app/utils/apiurls.dart';
import 'package:write_up/src/modules/auth/model/login_model.dart';
import 'package:write_up/src/modules/auth/model/register_model.dart';
import 'package:write_up/src/modules/auth/model/user_model.dart';
import 'package:write_up/src/core/services/storage_service.dart';

class AuthService {
  final _storage = StorageService();

  /// POST /api/auth/register
  /// Body: { "name": "string", "email": "string", "password": "string" }
  Future<RegisterResponseModel> register(RegisterRequestModel request) async {
    final response = await http.post(
      Uri.parse(Apiurls.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw Exception(
        'Server error (${response.statusCode}): unexpected response from server.',
      );
    }

    final Map<String, dynamic> json = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final model = RegisterResponseModel.fromJson(json);
      if (model.token != null) {
        await _storage.saveToken(model.token!);
        final userToSave = model.user ?? User.fromJson(json);
        if (userToSave.name.isNotEmpty || userToSave.email.isNotEmpty) {
          await _storage.saveUser(userToSave);
        }
      }
      return model;
    } else {
      throw Exception(
        json['message'] ?? 'Registration failed (${response.statusCode})',
      );
    }
  }

  /// POST /api/auth/login
  /// Body: { "email": "string", "password": "string" }
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    final response = await http.post(
      Uri.parse(Apiurls.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw Exception(
        'Server error (${response.statusCode}): unexpected response from server.',
      );
    }

    final Map<String, dynamic> json = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final model = LoginResponseModel.fromJson(json);
      if (model.token != null) {
        await _storage.saveToken(model.token!);
        final userToSave = model.user ?? User.fromJson(json);
        if (userToSave.name.isNotEmpty || userToSave.email.isNotEmpty) {
          await _storage.saveUser(userToSave);
        }
      }
      return model;
    } else {
      throw Exception(
        json['message'] ?? 'Login failed (${response.statusCode})',
      );
    }
  }
}
