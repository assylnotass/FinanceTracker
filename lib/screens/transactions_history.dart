import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:finance_app/helpers/export_helper.dart';
import '../providers/app_settings.dart';
import 'package:finance_app/localization/app_localization.dart';
import 'add_transaction.dart';

class TransactionsHistory extends StatefulWidget {
  final VoidCallback onMenuTap;

  const TransactionsHistory({Key? key, required this.onMenuTap}) : super(key: key);

  @override
  State<TransactionsHistory> createState() => TransactionsHistoryState();
}

class TransactionsHistoryState extends State<TransactionsHistory> {
  String? _familyId;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _sortType;
  List<Map<String, dynamic>> _allTransactions = [];
  bool _loading = true;

  bool _selectionMode = false;
  Set<Map<String, dynamic>> _selectedTransactions = {};

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    _familyId = userDoc.data()?['familyId'];

    List<Map<String, dynamic>> txs = [];

    final userSnap = await FirebaseFirestore.instance
        .collection('transactions')
        .doc(uid)
        .collection('user_transactions')
        .orderBy('timestamp', descending: true)
        .get();

    txs.addAll(userSnap.docs.map((e) => e.data()));

    if (_familyId != null && _familyId!.isNotEmpty) {
      final familySnap = await FirebaseFirestore.instance
          .collection('families')
          .doc(_familyId)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .get();

      txs.addAll(familySnap.docs.map((e) => e.data()));
    }

    txs.sort((a, b) {
      final aTime = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      final bTime = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      return bTime.compareTo(aTime);
    });

    setState(() {
      _allTransactions = txs;
      _loading = false;
      _selectionMode = false;
      _selectedTransactions.clear();
    });
  }

Future<void> _deleteSelected() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final familyId = userDoc.data()?['familyId'] ?? '';

  bool isAdmin = false;

  // Проверка роли, если есть семья
  if (familyId.isNotEmpty) {
    final memberDoc = await FirebaseFirestore.instance
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(uid)
        .get();

    isAdmin = memberDoc.data()?['role'] == 'admin';
  }

  for (final tx in _selectedTransactions) {
    final id = tx['id'];
    final isFamily = tx['isFamily'] == true;

    if (id == null) continue;

    if (isFamily && !isAdmin) {
      debugPrint('⛔ Не админ — нельзя удалить семейную транзакцию: $id');
      continue;
    }

    final docRef = isFamily
        ? FirebaseFirestore.instance
            .collection('families')
            .doc(familyId)
            .collection('transactions')
            .doc(id)
        : FirebaseFirestore.instance
            .collection('transactions')
            .doc(uid)
            .collection('user_transactions')
            .doc(id);

    try {
      await docRef.delete();
      debugPrint('✅ Удалено: $id');
    } catch (e) {
      debugPrint('❌ Ошибка при удалении $id: $e');
    }
  }

  _selectedTransactions.clear();
  loadTransactions();
}


  bool _isInRange(DateTime date) {
    if (_startDate == null || _endDate == null) return true;
    return date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
        date.isBefore(_endDate!.add(const Duration(days: 1)));
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _showSortDialog() async {
    final loc = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(loc.sortByAmount),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'asc'),
            child: Text(loc.ascending),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'desc'),
            child: Text(loc.descending),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _sortType = result);
    }
  }

  void _showExportOptions(List<Map<String, dynamic>> data) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text("Экспорт в PDF"),
              onTap: () {
                Navigator.pop(context);
                ExportHelper.exportToPDF(context, data);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text("Экспорт в CSV"),
              onTap: () {
                Navigator.pop(context);
                ExportHelper.exportToCSV(context, data);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text("Экспорт в Excel"),
              onTap: () {
                Navigator.pop(context);
                ExportHelper.exportToExcel(context, data);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currency = Provider.of<AppSettings>(context).currency;
    final theme = Theme.of(context);

    final txs = _allTransactions.where((tx) {
      final date = (tx['date'] as Timestamp?)?.toDate();
      return date != null && _isInRange(date);
    }).toList();

    if (_sortType == 'asc') {
      txs.sort((a, b) => (a['amount'] as num).compareTo(b['amount'] as num));
    } else if (_sortType == 'desc') {
      txs.sort((a, b) => (b['amount'] as num).compareTo(a['amount'] as num));
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
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
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: widget.onMenuTap,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.white),
                        onPressed: () => _showExportOptions(txs),
                      ),
                      if (_selectionMode)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedTransactions.length == txs.length) {
                                _selectedTransactions.clear();
                              } else {
                                _selectedTransactions = txs.toSet();
                              }
                            });
                          },
                          child: Text(loc.selectAll, style: const TextStyle(color: Colors.white)),
                        ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectionMode = !_selectionMode;
                            _selectedTransactions.clear();
                          });
                        },
                        child: Text(
                          _selectionMode ? loc.cancel : loc.select,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      loc.transactionHistory,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _pickDateRange,
                  child: Text(loc.byDate),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _showSortDialog,
                  child: Text(loc.byAmount),
                ),
              ],
            ),
          ),
          _loading
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : txs.isEmpty
                  ? Expanded(child: Center(child: Text(loc.noTransactions)))
                  : Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: txs.length,
                        itemBuilder: (context, i) {
                          final tx = txs[i];
                          final isExpense = tx['type'] == 'Expense';
                          final txDate = (tx['date'] as Timestamp).toDate();
                          final selected = _selectedTransactions.contains(tx);

                          return GestureDetector(
                            onTap: () {
                              if (_selectionMode) {
                                setState(() {
                                  selected ? _selectedTransactions.remove(tx) : _selectedTransactions.add(tx);
                                });
                              } else {
                                _showTransactionDetails(tx);
                              }
                            },
                            onLongPress: () async {
                              if (!_selectionMode) {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddTransactionScreen(editingTx: tx),
                                  ),
                                );
                                if (result == true) {
                                  loadTransactions();
                                }
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.white12
                                        : Colors.black26,
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  if (_selectionMode)
                                    Checkbox(
                                      value: selected,
                                      onChanged: (_) {
                                        setState(() {
                                          selected
                                              ? _selectedTransactions.remove(tx)
                                              : _selectedTransactions.add(tx);
                                        });
                                      },
                                    )
                                  else
                                    Icon(
                                      isExpense ? Icons.remove_circle : Icons.add_circle,
                                      color: isExpense ? Colors.red : Colors.green,
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          loc.localizeCategory(tx['category'] ?? 'Other'),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          txDate.toLocal().toString().split(' ')[0],
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${isExpense ? '-' : '+'} $currency ${tx['amount'].toStringAsFixed(0)}',
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
                        },
                      ),
                    ),
          if (_selectionMode && _selectedTransactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                icon: const Icon(Icons.delete),
                label: Text('${loc.delete} (${_selectedTransactions.length})'),
                onPressed: _deleteSelected,
              ),
            ),
        ],
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> tx) {
    final date = (tx['date'] as Timestamp).toDate().toLocal();
    final isExpense = tx['type'] == 'Expense';
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.transactionDetails),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${loc.type}: ${isExpense ? loc.expense : loc.income}'),
            const SizedBox(height: 6),
            Text('${loc.category}: ${loc.localizeCategory(tx['category'] ?? 'Other')}'),
            if (tx['subscriptionName'] != null)
              Text('${loc.subscription}: ${tx['subscriptionName']}'),
            const SizedBox(height: 6),
            Text('${loc.amount}: ${tx['amount'].toStringAsFixed(2)}'),
            const SizedBox(height: 6),
            Text('${loc.date}: ${date.toString().split(' ')[0]}'),
            if ((tx['description'] ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('${loc.description}: ${tx['description']}'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.close),
          )
        ],
      ),
    );
  }
}
