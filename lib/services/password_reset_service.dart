import 'dart:convert';

import 'package:http/http.dart' as http;

class PasswordResetService {
  PasswordResetService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'PASSWORD_RESET_BASE_URL',
              defaultValue: 'http://192.168.0.191:8003',
            );

  final http.Client _client;
  final String _baseUrl;

  String? lastError;

  Future<bool> sendOtp(String email) async {
    lastError = null;
    try {
      print("CALLING SEND OTP API");
      final normalizedEmail = email.trim().toLowerCase();
      print("NORMALIZED EMAIL: $normalizedEmail");
      final response = await _client.post(
        Uri.parse('$_baseUrl/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': normalizedEmail}),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {
        return true;
      }

      lastError = _extractError(response.body, 'Failed to send OTP');
      return false;
    } catch (_) {
      lastError = 'Network error. Please try again.';
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    lastError = null;
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final response = await _client.post(
        Uri.parse('$_baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': normalizedEmail,
          'otp': otp.trim(),
        }),
      );

      if (response.statusCode == 200) {
        return true;
      }

      lastError = _extractError(response.body, 'Invalid OTP');
      return false;
    } catch (_) {
      lastError = 'Network error. Please try again.';
      return false;
    }
  }

  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    lastError = null;
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final response = await _client.post(
        Uri.parse('$_baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': normalizedEmail,
          'otp': otp.trim(),
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      }

      lastError = _extractError(response.body, 'Failed to reset password');
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
    final message = data?['error'] ?? data?['msg'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }
    return fallback;
  }

  void dispose() {
    _client.close();
  }
}
