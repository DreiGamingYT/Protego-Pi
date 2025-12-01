// lib/screens/login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  bool _loading = false;

  Future<void> _loginEmail() async {
    setState(() => _loading = true);
    final provider = Provider.of<AuthProvider>(context, listen: false);
    final res = await provider.login(_emailCtl.text.trim(), _passCtl.text.trim());
    setState(() => _loading = false);
    if (res['status'] == 200) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      Fluttertoast.showToast(msg: 'Login failed: ${res['body']}');
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _loading = true);
    try {
      final GoogleSignIn _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: '445080403938-59e6a8mtfhc31o6g371bhp1akh40pbde.apps.googleusercontent.com',
      );

      final account = await _googleSignIn.signIn();
      if (account == null) {
        setState(() => _loading = false);
        return; // user cancelled
      }

      final auth = await account.authentication;
      print('DEBUG: accessToken=${auth.accessToken}');
      print('DEBUG: idToken=${auth.idToken}');
      print('DEBUG: serverAuthCode=${auth.serverAuthCode}');

      final idToken = auth.idToken;
      if (idToken == null) {
        // if idToken is null but serverAuthCode available, you can fallback to sending serverAuthCode to backend
        final serverAuthCode = auth.serverAuthCode;
        if (serverAuthCode != null) {
          // send serverAuthCode to backend and backend exchanges for idToken (requires web client secret)
          // implement backend endpoint /auth/google/exchange if you want this flow
        }

        Fluttertoast.showToast(msg: 'No idToken from Google — see debug logs');
        setState(() => _loading = false);
        return;
      }

      // send idToken to backend
      final provider = Provider.of<AuthProvider>(context, listen: false);
      final res = await provider.loginWithGoogle(idToken);
      setState(() => _loading = false);
      if (res['status'] == 200) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        Fluttertoast.showToast(msg: 'Google sign-in failed: ${res['body']}');
      }
    } catch (e) {
      setState(() => _loading = false);
      Fluttertoast.showToast(msg: 'Google sign-in error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(controller: _emailCtl, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: _passCtl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loading ? null : _loginEmail, child: _loading ? const CircularProgressIndicator() : const Text('Login')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loading ? null : _googleSignIn, child: const Text('Sign in with Google')),
          const SizedBox(height: 12),
          TextButton(onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())), child: const Text('Create account')),
        ]),
      ),
    );
  }
}
