// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'https://surveillance-robot.onrender.com';

  static Future<Map<String, dynamic>> register(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({
      'email': email,
      'password': password,
    }));
    return {'status': res.statusCode, 'body': res.body};
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({
      'email': email,
      'password': password,
    }));
    return {'status': res.statusCode, 'body': res.body};
  }

  static Future<Map<String, dynamic>> googleSignIn(String idToken) async {
    final url = Uri.parse('$baseUrl/auth/google');
    final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({
      'idToken': idToken,
    }));
    return {'status': res.statusCode, 'body': res.body};
  }
}
