import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finance_app/localization/app_localization.dart';

class StatisticsScreen extends StatefulWidget {
  final VoidCallback onMenuTap;

  const StatisticsScreen({Key? key, required this.onMenuTap}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> allTxs = [];
  List<Map<String, dynamic>> filteredTxs = [];

  DateTimeRange? _selectedRange;
  String _selectedType = 'All';
  bool _loading = true;
  String _familyId = '';
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    _familyId = userDoc.data()?['familyId'] ?? '';

    final List<Map<String, dynamic>> txs = [];

    final userSnap = await _firestore
        .collection('transactions')
        .doc(uid)
        .collection('user_transactions')
        .get();

    txs.addAll(userSnap.docs.map((doc) => doc.data()));

    if (_familyId.isNotEmpty) {
      final familySnap = await _firestore
          .collection('families')
          .doc(_familyId)
          .collection('transactions')
          .get();
      txs.addAll(familySnap.docs.map((doc) => doc.data()));
    }

    setState(() {
      allTxs = txs;
      _applyFilters();
      _loading = false;
    });
  }

  void _applyFilters() {
    final filtered = allTxs.where((tx) {
      final date = ((tx['date'] ?? tx['timestamp']) as Timestamp?)?.toDate();
      if (date == null) return false;

      if (_selectedRange != null) {
        if (date.isBefore(_selectedRange!.start) || date.isAfter(_selectedRange!.end)) {
          return false;
        }
      }

      if (_selectedType != 'All' && tx['type'] != _selectedType) {
        return false;
      }

      return true;
    }).toList();

    setState(() {
      filteredTxs = filtered;
    });
  }

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedRange = picked);
      _applyFilters();
    }
  }

  void _setType(String type) {
    setState(() => _selectedType = type);
    _applyFilters();
  }

  Map<String, double> _categoryTotals() {
    final result = <String, double>{};
    for (var tx in filteredTxs.where((t) => t['type'] == 'Expense')) {
      final cat = tx['category'] ?? 'Other';
      final amt = (tx['amount'] as num).toDouble();
      result[cat] = (result[cat] ?? 0) + amt;
    }
    return result;
  }

  List<Color> pieColors = [
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.red,
    Colors.brown,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
  ];

Widget _buildPieChart(Map<String, double> data) {
  final loc = AppLocalizations.of(context)!;
  final total = data.values.fold(0.0, (a, b) => a + b);
  final keys = data.keys.toList();

  return Column(
    children: [
      SizedBox(
        height: 250,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            pieTouchData: PieTouchData(
              touchCallback: (event, response) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      response == null ||
                      response.touchedSection == null) {
                    touchedIndex = -1;
                  } else {
                    touchedIndex = response.touchedSection!.touchedSectionIndex;
                  }
                });
              },
            ),
            sections: List.generate(data.length, (i) {
              final key = keys[i];
              final value = data[key]!;
              final percent = (value / total * 100).toStringAsFixed(1);
              final isTouched = i == touchedIndex;

              return PieChartSectionData(
                color: pieColors[i % pieColors.length],
                value: value,
                radius: isTouched ? 70 : 55,
                title: isTouched ? '${value.toInt()} ₸\n($percent%)' : '',
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                titlePositionPercentageOffset: 0.55,
              );
            }),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: List.generate(data.length, (i) {
          final key = keys[i];
          final value = data[key]!;
          final percent = (value / total * 100).toStringAsFixed(1);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: pieColors[i % pieColors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${loc.localizeCategory(key)}: ${value.toInt()} ₸ ($percent%)',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
        }),
      ),
    ],
  );
}




  Widget _buildBarChart(List<Map<String, dynamic>> txs) {
    final loc = AppLocalizations.of(context)!;

    final byMonth = <int, Map<String, double>>{};
    for (var tx in txs) {
      final date = ((tx['date'] ?? tx['timestamp']) as Timestamp).toDate();
      final month = date.month;
      final amt = (tx['amount'] as num).toDouble();
      final type = tx['type'] ?? 'Expense';
      byMonth[month] ??= {'Income': 0, 'Expense': 0};
      byMonth[month]![type] = (byMonth[month]![type] ?? 0) + amt;
    }

    String formatAmount(double value) {
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(1)}M';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(0)}K';
      } else {
        return value.toStringAsFixed(0);
      }
    }

    final barGroups = byMonth.entries.map((e) {
      final month = e.key;
      final income = e.value['Income'] ?? 0;
      final expense = e.value['Expense'] ?? 0;
      return BarChartGroupData(
        x: month,
        barRods: [
          BarChartRodData(toY: income, color: Colors.green, width: 7),
          BarChartRodData(toY: expense, color: Colors.red, width: 7),
        ],
        barsSpace: 4,
      );
    }).toList();

    final monthLabels = [
      loc.January, loc.February, loc.March, loc.April,
      loc.May, loc.June, loc.July, loc.August,
      loc.September, loc.October, loc.November, loc.December
    ];

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: 50000,
              getTitlesWidget: (value, meta) => Text(
                formatAmount(value),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt() - 1;
                if (index >= 0 && index < monthLabels.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text(monthLabels[index], style: const TextStyle(fontSize: 10)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = rodIndex == 0 ? loc.income : loc.expense;
              return BarTooltipItem(
                '$label: ${formatAmount(rod.toY)} ₸',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final catTotals = _categoryTotals();
    final total = catTotals.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
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
                  Text(loc.statistics,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.filter_alt, color: Colors.white),
                    onPressed: _pickDateRange,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                FilterChip(
                  label: Text(loc.transactions),
                  selected: _selectedType == 'All',
                  onSelected: (_) => _setType('All'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(loc.income),
                  selected: _selectedType == 'Income',
                  onSelected: (_) => _setType('Income'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(loc.expense),
                  selected: _selectedType == 'Expense',
                  onSelected: (_) => _setType('Expense'),
                ),
              ],
            ),
          ),
          _loading
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (_selectedRange != null)
                        Text(
                          '${loc.from} ${_selectedRange!.start.toLocal().toString().split(' ')[0]} — ${_selectedRange!.end.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 12),
                      Text("📊 ${loc.expenseByCategory}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      _buildPieChart(catTotals),
                      const SizedBox(height: 24),
                      Text("📈 ${loc.monthlyExpenses}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 300, child: _buildBarChart(filteredTxs)),
                      const SizedBox(height: 24),
                      Text("📋 ${loc.category}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ...catTotals.entries.map((e) {
                        final percent = total > 0 ? (e.value / total * 100).toStringAsFixed(1) : "0";
                        return ListTile(
                          title: Text(loc.localizeCategory(e.key)),
                          trailing: Text('${e.value.toInt()} ₸  ($percent%)'),
                        );
                      }),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
