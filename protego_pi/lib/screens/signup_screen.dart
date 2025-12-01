// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  bool _loading = false;

  Future<void> _signup() async {
    setState(() => _loading = true);
    final provider = Provider.of<AuthProvider>(context, listen: false);
    final res = await provider.signup(_emailCtl.text.trim(), _passCtl.text.trim());
    setState(() => _loading = false);
    if (res['status'] == 200) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      Fluttertoast.showToast(msg: 'Signup failed: ${res['body']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(controller: _emailCtl, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: _passCtl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loading ? null : _signup, child: _loading ? const CircularProgressIndicator() : const Text('Create account')),
        ]),
      ),
    );
  }
}
