import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/main.dart';
import 'package:finance_app/localization/app_localization.dart';
import 'package:finance_app/screens/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  bool loading = false;

  void _register() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => loading = true);
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
      );

      final user = userCredential.user!;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'avatarUrl': '',
        'familyId': '', // 🔹 по умолчанию пусто
      });


      // Отправить письмо с подтверждением
      await user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.verificationSent)),
      );

      // Вернуться на экран логина
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${loc.signUpError}: ${e.toString()}")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.signUp)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: loc.name)),
            TextField(controller: emailCtrl, decoration: InputDecoration(labelText: loc.email)),
            TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(labelText: loc.password)),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _register, child: Text(loc.signUp)),
          ],
        ),
      ),
    );
  }
}
