import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'main.dart';
import 'createAccount.dart';

class LoginScreen extends HookWidget {
  LoginScreen({super.key, required this.email, required this.password});

  final String email, password;

  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController(text: email);
    final passwordController = useTextEditingController(text: password);
    final authError = useState<String?>(null);

    Future<void> _login() async {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        authError.value = 'Login Completed!';
        // Navigate to home screen or handle login success
      } on FirebaseAuthException catch (e) {
        authError.value = e.message;
      }

      final snackBar = SnackBar(
          content: Text(authError.value ??
              'An error has occured during the login procedure.'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    return Scaffold(
      appBar: AppBar(title: Text('Login to Simbureum!')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
