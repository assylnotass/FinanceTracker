import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/localization/app_localization.dart';

class BudgetGoalsScreen extends StatefulWidget {
  final VoidCallback onMenuTap;

  const BudgetGoalsScreen({Key? key, required this.onMenuTap}) : super(key: key);

  @override
  State<BudgetGoalsScreen> createState() => _BudgetGoalsScreenState();
}

class _BudgetGoalsScreenState extends State<BudgetGoalsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _familyId = '';
  bool _loading = true;
  List<Map<String, dynamic>> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    _familyId = userDoc.data()?['familyId'] ?? '';

    if (_familyId.isEmpty) {
      setState(() {
        _loading = false;
        _goals = [];
      });
      return;
    }

    final goalsSnapshot = await _firestore
        .collection('families')
        .doc(_familyId)
        .collection('goals')
        .orderBy('deadline')
        .get();

    setState(() {
      _goals = goalsSnapshot.docs.map((e) => e.data()).toList();
      _loading = false;
    });
  }

  Future<void> _createGoal() async {
    final loc = AppLocalizations.of(context)!;
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.newGoal),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: loc.goalName),
                ),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: loc.amount),
                ),
                TextField(
                  controller: categoryCtrl,
                  decoration: InputDecoration(labelText: loc.category),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      setStateDialog(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: Text(selectedDate == null
                      ? loc.selectDate
                      : '${loc.selectedDate}: ${selectedDate!.toLocal().toString().split(' ')[0]}'),
                )
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () async {
              if (_familyId.isEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.notInFamily)),
                );
                return;
              }

              if (titleCtrl.text.isEmpty ||
                  amountCtrl.text.isEmpty ||
                  selectedDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.fillAllFields)),
                );
                return;
              }

              final uid = _auth.currentUser?.uid;
              final docRef = _firestore
                  .collection('families')
                  .doc(_familyId)
                  .collection('goals')
                  .doc();

              await docRef.set({
                'id': docRef.id,
                'title': titleCtrl.text.trim(),
                'amount': double.tryParse(amountCtrl.text.trim()) ?? 0.0,
                'current': 0.0,
                'category': categoryCtrl.text.trim(),
                'deadline': selectedDate,
                'createdBy': uid,
              });

              Navigator.pop(context);
              _loadGoals();
            },
            child: Text(loc.create),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
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
                    loc.budgetGoals,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _createGoal,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _familyId.isEmpty
                    ? Center(child: Text(loc.notInFamily))
                    : _goals.isEmpty
                        ? Center(child: Text(loc.noGoals))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _goals.length,
                            itemBuilder: (_, index) {
                              final goal = _goals[index];
                              final double amount = goal['amount'];
                              final double current = goal['current'];
                              final deadline = (goal['deadline'] as Timestamp?)?.toDate();
                              final percent = (current / amount).clamp(0.0, 1.0);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(goal['title'], style: theme.textTheme.titleMedium),
                                      const SizedBox(height: 4),
                                      Text('${loc.category}: ${goal['category']}'),
                                      if (deadline != null)
                                        Text('${loc.before}: ${deadline.toLocal().toString().split(' ')[0]}',
                                            style: const TextStyle(color: Colors.grey)),
                                      const SizedBox(height: 12),
                                      LinearProgressIndicator(
                                        value: percent,
                                        minHeight: 10,
                                        backgroundColor: Colors.grey.shade300,
                                        valueColor: AlwaysStoppedAnimation(
                                            percent >= 1 ? Colors.green : Colors.orange),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${loc.accumulated}: ${current.toStringAsFixed(0)} / ${amount.toStringAsFixed(0)} ₸',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
