import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:finance_app/screens/login_screen.dart';
import 'package:finance_app/screens/family_screen.dart';
import 'package:finance_app/localization/app_localization.dart';
import 'package:finance_app/helpers/pin_helper.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onMenuTap;

  const ProfileScreen({super.key, required this.onMenuTap});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _nameController = TextEditingController();

  String _avatarUrl = '';
  String _familyId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

Future<void> deleteAllUserTransactions() async {
  print('Удаляем все транзакции...');
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final batchSize = 500; // максимум на один batch

  final querySnapshot = await FirebaseFirestore.instance
      .collection('transactions')
      .doc(uid)
      .collection('user_transactions')
      .limit(batchSize)
      .get();

  if (querySnapshot.docs.isEmpty) {
    print('Нечего удалять — коллекция пуста.');
    return;
  }

  WriteBatch batch = FirebaseFirestore.instance.batch();
  for (final doc in querySnapshot.docs) {
    batch.delete(doc.reference);
  }

  await batch.commit();
  print('Удалено: ${querySnapshot.docs.length} транзакций.');

  // Рекурсивно удалить оставшиеся, если их больше 500
  if (querySnapshot.docs.length == batchSize) {
    await Future.delayed(Duration(milliseconds: 200));
    await deleteAllUserTransactions();
  }
}


  Future<void> deleteOldUserTransactions() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }

    print('Удалено ${snapshot.docs.length} дублированных транзакций.');
  }



  Future<void> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _avatarUrl = data['avatarUrl'] ?? '';
      _familyId = data['familyId'] ?? '';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateProfile(AppLocalizations loc) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'name': _nameController.text.trim(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.avatarUpdated)),
    );
  }

  Future<void> _uploadAvatar(AppLocalizations loc) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final file = File(image.path);
      final ref = _storage.ref().child('avatars/$uid');

      // ⚠️ Фикс: передаём пустой SettableMetadata, чтобы избежать NPE
      await ref.putFile(file, SettableMetadata());

      final url = await ref.getDownloadURL();

      await _firestore.collection('users').doc(uid).update({'avatarUrl': url});

      setState(() {
        _avatarUrl = '$url&ts=${DateTime.now().millisecondsSinceEpoch}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.avatarUpdated)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.avatarUpdateError}: $e')),
      );
    }
  }


Future<void> _logout() async {
  await PinHelper.clearPin(); // ⬅️ сбрасываем PIN при выходе
  await _auth.signOut();

  if (!mounted) return;

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}


  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Builder(
        builder: (context) => _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white),
                            onPressed: widget.onMenuTap,
                          ),
                          Text(
                            loc.profile,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.notifications, color: Colors.white),
                            onPressed: () {
                              Navigator.pushNamed(context, '/notifications');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _uploadAvatar(loc),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                              child: _avatarUrl.isEmpty ? const Icon(Icons.person, size: 50) : null,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(labelText: loc.name),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => _updateProfile(loc),
                            child: Text(loc.save),
                          ),
                          ElevatedButton(
  onPressed: deleteAllUserTransactions,
  child: Text('Удалить все транзакции'),
),

                          const SizedBox(height: 20),
                          Text('Email: ${user?.email ?? ''}'),
                          const SizedBox(height: 12),
                          Text('${loc.familyId}: ${_familyId.isNotEmpty ? _familyId : loc.noFamily}'),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyScreen()));
                            },
                            icon: const Icon(Icons.group_add),
                            label: Text(loc.joinFamily),
                          ),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout),
                            label: Text(loc.logout),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
