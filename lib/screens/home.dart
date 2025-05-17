import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings.dart';
import 'package:finance_app/localization/app_localization.dart';
import '../helpers/smart_notification_helper.dart';
import 'package:finance_app/helpers/recurring_transaction_helper.dart';


class Home extends StatefulWidget {
  final VoidCallback onMenuTap;

  const Home({Key? key, required this.onMenuTap}) : super(key: key);

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _name = '';
  String _avatarUrl = '';
  String _familyId = '';
  double _balance = 0.0;
  double _income = 0.0;
  double _expense = 0.0;

  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  final TextEditingController _searchController = TextEditingController();

  bool _didLoad = false;
  bool _showRecentOnly = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _searchController.addListener(_filterTransactions);
    _initSmartNotifications();
    _initRecurringTransactions();
  }

  void _initSmartNotifications() async {
    await SmartNotificationHelper.checkSmartNotifications();
  }

  void _initRecurringTransactions() async {
    await RecurringTransactionHelper.checkAndCreateRecurringTransactions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      loadTransactions();
      _didLoad = true;
    }
  }

  Future<void> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (!mounted) return;

    if (data != null) {
      setState(() {
        _name = data['name'] ?? '';
        _avatarUrl = data['avatarUrl'] ?? '';
        _familyId = data['familyId'] ?? '';
      });
    }
  }

Future<void> loadTransactions() async {
  final uid = _auth.currentUser?.uid;
  if (uid == null || !mounted) return;

  List<Map<String, dynamic>> allTxs = [];

  final userTxs = await _firestore
      .collection('transactions')
      .doc(uid)
      .collection('user_transactions')
      .orderBy('timestamp', descending: true)
      .get();

  allTxs.addAll(userTxs.docs.map((doc) => doc.data()));

  if (_familyId.isNotEmpty) {
    final familyTxs = await _firestore
        .collection('families')
        .doc(_familyId)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .get();

    allTxs.addAll(familyTxs.docs.map((doc) => doc.data()));
  }

  allTxs.sort((a, b) {
    final aTime = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final bTime = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    return bTime.compareTo(aTime);
  });

  final now = DateTime.now();
  final threeDaysAgo = now.subtract(const Duration(days: 3));

  // Показывать все или только последние 3 дня
  final visibleTxs = allTxs.where((tx) {
    final date = (tx['timestamp'] as Timestamp?)?.toDate();
    return !_showRecentOnly || (date != null && date.isAfter(threeDaysAgo));
  }).toList();

  double income = 0;
  double expense = 0;

  for (var tx in visibleTxs) {
    final amount = (tx['amount'] ?? 0).toDouble();
    final type = tx['type'] ?? 'Expense';
    if (type == 'Income') {
      income += amount;
    } else {
      expense += amount;
    }
  }

  if (!mounted) return;
  setState(() {
    _transactions = allTxs;
    _filteredTransactions = visibleTxs;
    _income = income;
    _expense = expense;
    _balance = income - expense;
  });
}

  void _filterTransactions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTransactions = _transactions.where((tx) {
        final cat = (tx['category'] ?? '').toString().toLowerCase();
        final desc = (tx['description'] ?? '').toString().toLowerCase();
        return cat.contains(query) || desc.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = Provider.of<AppSettings>(context).currency;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Builder(
        builder: (context) => Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: widget.onMenuTap,
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications, color: Colors.white),
                          onPressed: () {
                            Navigator.pushNamed(context, '/notifications');
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                          child: _avatarUrl.isEmpty ? const Icon(Icons.person) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${loc.welcome},',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white)),
                              Text(
                                _name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: loc.searchByTransaction,
                                hintStyle: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _summaryCard(loc.balance, _balance, colorScheme.onSurface, currency),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _summaryCard(loc.income, _income, Colors.green, currency)),
                      const SizedBox(width: 2),
                      Expanded(child: _summaryCard(loc.expense, _expense, Colors.red, currency)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(loc.lastTransactions, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const Icon(Icons.expand_more_outlined, size: 16),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showRecentOnly = !_showRecentOnly;
                        _filterTransactions();
                        loadTransactions();
                      });
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                      child: Text(
                        _showRecentOnly ? ' ${loc.recent}' : ' ${loc.all}',
                        key: ValueKey(_showRecentOnly),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),

                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
                child: _TransactionListWidget(
                  key: ValueKey(_showRecentOnly), // убедитесь, что _TransactionListWidget поддерживает key
                  transactions: _filteredTransactions,
                  currency: currency,
                  builder: _buildTransactionTile,
                ),
              ),
            ), 
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, double amount, Color color, String currency) {
    final theme = Theme.of(context);
    return Container(
      height: 70,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const Spacer(),
          Text('$currency ${amount.toStringAsFixed(0)}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx, String currency) {
    final loc = AppLocalizations.of(context)!;
    final isExpense = tx['type'] == 'Expense';
    final txDate = (tx['date'] as Timestamp?)?.toDate().toLocal().toString().split(' ')[0] ?? '';
    final amount = tx['amount'] ?? 0.0;
    final category = loc.localizeCategory(tx['category'] ?? 'Other');
    Text(category);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              isExpense ? Icons.remove_circle_outline : Icons.add_circle_outline,
              color: isExpense ? Colors.red : Colors.green,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(txDate, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isExpense ? '-' : '+'} $currency ${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isExpense ? Colors.red : Colors.green,
                  ),
                ),
                if (tx['isFamily'] == true && tx['ownerName'] != null)
                  Text(
                    '👤 ${tx['ownerName']} (семья)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final String currency;
  final Widget Function(Map<String, dynamic>, String) builder;

  const _TransactionListWidget({
    Key? key,
    required this.transactions,
    required this.currency,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      itemCount: transactions.length,
      itemBuilder: (_, index) => builder(transactions[index], currency),
    );
  }
}