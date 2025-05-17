import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finance_app/localization/app_localization.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String _familyId = '';
  String _inviteCode = '';
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  bool _isAdmin = false;
  bool _didLoad = false;

  final _joinCodeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _loadFamilyData();
      _didLoad = true;
    }
  }

  Future<void> _loadFamilyData() async {
    final uid = _auth.currentUser?.uid;
    final loc = AppLocalizations.of(context)!;
    if (uid == null) return;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    _familyId = userDoc.data()?['familyId'] ?? '';

    if (_familyId.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    final familyDoc = await _firestore.collection('families').doc(_familyId).get();
    _inviteCode = familyDoc.data()?['inviteCode'] ?? '';

    final membersSnap = await _firestore
        .collection('families')
        .doc(_familyId)
        .collection('members')
        .get();

    final members = <Map<String, dynamic>>[];

    for (final doc in membersSnap.docs) {
      final memberData = doc.data();
      final uid = memberData['uid'];

      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data();

      members.add({
        'uid': uid,
        'role': memberData['role'],
        'name': userData?['name'] ?? loc.user,
        'avatarUrl': userData?['avatarUrl'] ?? '',
      });
    }

    _isAdmin = members.any((m) => m['uid'] == uid && m['role'] == 'admin');

    setState(() {
      _members = members;
      _loading = false;
    });
  }

  Future<void> _createFamily() async {
    final loc = AppLocalizations.of(context)!;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final newFamilyId = _firestore.collection('families').doc().id;
    final inviteCode = newFamilyId.substring(0, 6);

    await _firestore.collection('families').doc(newFamilyId).set({
      'inviteCode': inviteCode,
    });

    await _firestore
        .collection('families')
        .doc(newFamilyId)
        .collection('members')
        .doc(uid)
        .set({
      'uid': uid,
      'role': 'admin',
      'name': _auth.currentUser?.email ?? loc.user,
    });

    final userRef = _firestore.collection('users').doc(uid);
    final userDoc = await userRef.get();

    if (userDoc.exists) {
      await userRef.update({'familyId': newFamilyId});
    } else {
      await userRef.set({
        'name': _auth.currentUser?.email ?? '',
        'email': _auth.currentUser?.email ?? '',
        'avatarUrl': '',
        'familyId': newFamilyId,
      });
    }

    setState(() {
      _familyId = newFamilyId;
    });

    _loadFamilyData();
  }

  Future<void> _joinFamilyByCode(String code) async {
    final loc = AppLocalizations.of(context)!;
    final uid = _auth.currentUser?.uid;
    if (uid == null || code.isEmpty) return;

    final query = await _firestore
        .collection('families')
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.invalidInviteCode)),
      );
      return;
    }

    final newFamilyId = query.docs.first.id;

    if (newFamilyId == _familyId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.alreadyInFamily)),
      );
      return;
    }

    await _firestore
        .collection('families')
        .doc(newFamilyId)
        .collection('members')
        .doc(uid)
        .set({
      'uid': uid,
      'role': 'member',
      'name': _auth.currentUser?.email ?? loc.user,
    });

    final userRef = _firestore.collection('users').doc(uid);
    final userDoc = await userRef.get();

    if (userDoc.exists) {
      await userRef.update({'familyId': newFamilyId});
    } else {
      await userRef.set({
        'name': _auth.currentUser?.email ?? '',
        'email': _auth.currentUser?.email ?? '',
        'avatarUrl': '',
        'familyId': newFamilyId,
      });
    }

    _familyId = newFamilyId;
    _joinCodeCtrl.clear();
    await _loadFamilyData();
  }

  Future<void> _leaveFamily() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({'familyId': ''});
    _familyId = '';
    _inviteCode = '';
    _members.clear();
    setState(() {});
  }

  Future<void> _confirmRemoveMember(String uid, String name) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.deleteMember),
        content: Text(loc.confirmDeleteMember),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(loc.delete)),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestore.collection('families').doc(_familyId).collection('members').doc(uid).delete();
      await _firestore.collection('users').doc(uid).update({'familyId': ''});
      _loadFamilyData();
    }
  }

@override
Widget build(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Scaffold(
    backgroundColor: theme.colorScheme.background,
    body: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
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
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text(
                  loc.family,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: _familyId.isEmpty
                      ? Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _createFamily,
                              icon: const Icon(Icons.group_add),
                              label: Text(loc.createFamily),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _joinCodeCtrl,
                              decoration: InputDecoration(
                                labelText: loc.inviteCode,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey[850] : Colors.white,
                              ),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _joinFamilyByCode(_joinCodeCtrl.text.trim()),
                              child: Text(loc.joinFamily),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            )
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${loc.familyId}: $_familyId', style: theme.textTheme.bodyLarge),
                            const SizedBox(height: 8),
                            Text('${loc.inviteCode}: $_inviteCode',
                                style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            Text('${loc.familyMembers}:', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _members.length,
                                itemBuilder: (_, i) {
                                  final m = _members[i];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: (m['avatarUrl'] as String).isNotEmpty
                                          ? NetworkImage(m['avatarUrl'])
                                          : null,
                                      child: (m['avatarUrl'] as String).isEmpty
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    title: Text(m['name'] ?? ''),
                                    subtitle: Text(m['uid']),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(m['role'] ?? ''),
                                        if (_isAdmin &&
                                            m['uid'] != _auth.currentUser?.uid)
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle,
                                                color: Colors.red),
                                            tooltip: loc.deleteMember,
                                            onPressed: () =>
                                                _confirmRemoveMember(m['uid'], m['name']),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.logout),
                              label: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  loc.leaveFamily,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text(loc.confirmLeaveFamily),
                                    content: Text(loc.confirmLeaveFamilyMessage),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text(loc.cancel)),
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: Text(loc.leave)),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  await _leaveFamily();
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                ),
        ),
      ],
    ),
  );
}
  
}
