import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _baseUrl = 'http://10.0.2.2:5000/api/auth';

  String? lastError;

  Future<bool> login(String email, String password) async {
    lastError = null;
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = _tryDecode(response.body);
        final token = data?['token'];
        if (token is String && token.isNotEmpty) {
          await _storage.write(key: 'auth_token', value: token);
        }
        return true;
      }

      lastError = _extractError(response.body, 'Invalid credentials');
      return false;
    } catch (_) {
      lastError = 'Network error. Please try again.';
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    lastError = null;
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _tryDecode(response.body);
        final token = data?['token'];
        if (token is String && token.isNotEmpty) {
          await _storage.write(key: 'auth_token', value: token);
        }
        return true;
      }

      lastError = _extractError(response.body, 'Signup failed');
      return false;
    } catch (_) {
      lastError = 'Network error. Please try again.';
      return false;
    }
  }

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _extractError(String body, String fallback) {
    final data = _tryDecode(body);
    final message = data?['msg'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }
    return fallback;
  }
}
