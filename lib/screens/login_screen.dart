import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finance_app/screens/register_screen.dart';
import 'package:finance_app/main.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/localization/app_localization.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool loading = false;

  void _login() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => loading = true);
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
      );
      final user = userCredential.user;

      if (user != null) {
        if (!user.emailVerified) {
          await FirebaseAuth.instance.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.emailNotVerified)),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => NavigationController()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = loc.loginError;
      if (e.code == 'user-not-found') message = loc.userNotFound;
      if (e.code == 'wrong-password') message = loc.wrongPassword;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => loading = true);
    final loc = AppLocalizations.of(context)!;
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final uid = user!.uid;
        final email = user.email ?? '';
        final name = user.displayName ?? '';

        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
        await userRef.set({
          'name': name,
          'email': email,
          'avatarUrl': user.photoURL ?? '',
          'familyId': '',
        });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => NavigationController()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.loginError}: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  void _resetPassword(String email) async {
    final loc = AppLocalizations.of(context)!;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.resetEmailSent)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.resetFailed}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.login)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailCtrl, decoration: InputDecoration(labelText: 'Email')),
            TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(labelText: loc.password)),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _login, child: Text(loc.login)),
            TextButton(
              onPressed: () {
                if (emailCtrl.text.isNotEmpty) {
                  _resetPassword(emailCtrl.text.trim());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.enterEmailToReset)),
                  );
                }
              },
              child: Text(loc.forgotPassword),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: Text(loc.googleSignIn),
              onPressed: _signInWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
                elevation: 2,
                side: const BorderSide(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
              },
              child: Text(loc.dontHaveAccount),
            )
          ],
        ),
      ),
    );
  }
}
