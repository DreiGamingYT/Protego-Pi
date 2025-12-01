// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  String? _token;
  Map<String, dynamic>? user;

  bool get isAuth => _token != null;

  String? get token => _token;

  Future<void> tryAutoLogin() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      _token = token;
      // optionally decode user from token or call /me endpoint
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> signup(String email, String password) async {
    final res = await AuthService.register(email, password);
    if (res['status'] == 200) {
      final body = jsonDecode(res['body']);
      _token = body['token'];
      user = body['user'];
      await _storage.write(key: 'jwt_token', value: _token);
      notifyListeners();
    }
    return {'status': res['status'], 'body': res['body']};
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await AuthService.login(email, password);
    if (res['status'] == 200) {
      final body = jsonDecode(res['body']);
      _token = body['token'];
      user = body['user'];
      await _storage.write(key: 'jwt_token', value: _token);
      notifyListeners();
    }
    return {'status': res['status'], 'body': res['body']};
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final res = await AuthService.googleSignIn(idToken);
    if (res['status'] == 200) {
      final body = jsonDecode(res['body']);
      _token = body['token'];
      user = body['user'];
      await _storage.write(key: 'jwt_token', value: _token);
      notifyListeners();
    }
    return {'status': res['status'], 'body': res['body']};
  }

  Future<void> logout() async {
    _token = null;
    user = null;
    await _storage.delete(key: 'jwt_token');
    notifyListeners();
  }
}
