import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings.dart';
import 'package:finance_app/helpers/notification_helper.dart';
import 'package:finance_app/localization/app_localization.dart';

class BudgetsScreen extends StatefulWidget {
  final VoidCallback onMenuTap;

  const BudgetsScreen({Key? key, required this.onMenuTap}) : super(key: key);

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Map<String, double> _limits = {};
  Map<String, double> _spent = {};
  String _familyId = '';
  bool _loading = true;
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _loadBudgets();
      _didLoad = true;
    }
  }

  Future<void> _loadBudgets() async {
    final loc = AppLocalizations.of(context)!;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final appSettings = Provider.of<AppSettings>(context, listen: false);

    final userDoc = await _firestore.collection('users').doc(uid).get();
    _familyId = userDoc.data()?['familyId'] ?? '';

    final Map<String, double> tempSpent = {};

    final userTxSnapshot = await _firestore
        .collection('transactions')
        .doc(uid)
        .collection('user_transactions')
        .get();

    for (var doc in userTxSnapshot.docs) {
      final data = doc.data();
      if (data['type'] == 'Expense') {
        final cat = data['category'] ?? loc.other;
        final amt = (data['amount'] as num).toDouble();
        tempSpent[cat] = (tempSpent[cat] ?? 0) + amt;
      }
    }

    if (_familyId.isNotEmpty) {
      final familyTxSnapshot = await _firestore
          .collection('families')
          .doc(_familyId)
          .collection('transactions')
          .get();

      for (var doc in familyTxSnapshot.docs) {
        final data = doc.data();
        if (data['type'] == 'Expense') {
          final cat = data['category'] ?? loc.other;
          final amt = (data['amount'] as num).toDouble();
          tempSpent[cat] = (tempSpent[cat] ?? 0) + amt;
        }
      }
    }

    final Map<String, double> tempLimits = {};
    final limitsCollection = _familyId.isNotEmpty
        ? _firestore.collection('families').doc(_familyId).collection('category_limits')
        : _firestore.collection('budgets').doc(uid).collection('category_limits');

    final limitsSnap = await limitsCollection.get();

    for (var doc in limitsSnap.docs) {
      final data = doc.data();
      final limit = (data['limit'] as num).toDouble();
      final notified = data['notified'] == true;
      final spent = tempSpent[doc.id] ?? 0.0;

      tempLimits[doc.id] = limit;

      if (limit > 0 && spent > limit && !notified && appSettings.notificationsEnabled) {
        await showNotification(
          loc.budgetLimitExceeded,
          '${loc.budgetLimitExceededMessage} ${doc.id}',
          context,
        );

        await limitsCollection.doc(doc.id).update({'notified': true});
      }
    }

    setState(() {
      _spent = tempSpent;
      _limits = tempLimits;
      _loading = false;
    });
  }

  Future<void> _editLimit(String category) async {
    final loc = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _limits[category]?.toStringAsFixed(0) ?? '');
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final limitsRef = _familyId.isNotEmpty
        ? _firestore.collection('families').doc(_familyId).collection('category_limits')
        : _firestore.collection('budgets').doc(uid).collection('category_limits');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${loc.changeLimit}: $category'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: loc.amount),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () async {
              final value = double.tryParse(controller.text);
              if (value != null) {
                await limitsRef.doc(category).set({'limit': value, 'notified': false});
                Navigator.pop(context);
                _loadBudgets();
              }
            },
            child: Text(loc.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final allCategories = {..._limits.keys, ..._spent.keys}.toList();
    final currency = Provider.of<AppSettings>(context).currency;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Builder(
        builder: (context) => Column(
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
                      loc.budgets,
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : allCategories.isEmpty
                      ? Center(child: Text(loc.noBudgets))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: allCategories.length,
                          itemBuilder: (context, index) {
                            final cat = allCategories[index];
                            final spent = _spent[cat] ?? 0.0;
                            final limit = _limits[cat] ?? 0.0;
                            final percent = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
                            final isOver = spent > limit && limit > 0;

                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            cat,
                                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _editLimit(cat),
                                          icon: const Icon(Icons.edit, size: 20),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: percent,
                                        minHeight: 10,
                                        backgroundColor: colorScheme.surfaceVariant,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isOver ? Colors.red : Colors.green,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${loc.spended}: $currency ${spent.toStringAsFixed(0)} / $currency ${limit.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: isOver ? Colors.red : colorScheme.onSurface,
                                        fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            TextButton(
              onPressed: () => showNotification(
                'Тест уведомления',
                'Это проверка уведомлений!',
                context,
              ),
              child: const Text('Проверить уведомление'),
            ),
          ],
        ),
      ),
    );
  }
}
