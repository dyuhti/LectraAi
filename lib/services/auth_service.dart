import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _baseUrl = String.fromEnvironment(
    'AUTH_BASE_URL',
    defaultValue: 'http://192.168.0.191:5001/api/auth',
  );

  String? lastError;

  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
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
        await _storeUserId(data);
        
        if (rememberMe) {
          await _storage.write(key: 'remember_email', value: email.trim());
        } else {
          await _storage.delete(key: 'remember_email');
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
        await _storeUserId(data);
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

  Future<void> _storeUserId(Map<String, dynamic>? data) async {
    final user = data?['user'];
    final userId = user is Map ? user['id'] : null;
    if (userId is String && userId.trim().isNotEmpty) {
      await _storage.write(key: 'user_id', value: userId.trim());
    }
  }

  Future<String?> getUserId() async {
    final cached = await _storage.read(key: 'user_id');
    if (cached != null && cached.trim().isNotEmpty) {
      return cached;
    }

    final token = await _storage.read(key: 'auth_token');
    if (token == null || token.trim().isEmpty) {
      return null;
    }

    final userId = _decodeUserIdFromToken(token);
    if (userId != null && userId.trim().isNotEmpty) {
      await _storage.write(key: 'user_id', value: userId.trim());
      return userId.trim();
    }
    return null;
  }

  Future<String?> getAuthToken() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null && token.trim().isNotEmpty) {
      return token.trim();
    }
    return null;
  }

  String? _decodeUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) {
        return null;
      }
      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final data = jsonDecode(decoded);
      final id = data is Map<String, dynamic> ? data['id'] : null;
      return id is String ? id : null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getRememberedEmail() async {
    return await _storage.read(key: 'remember_email');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_id');
  }
}
