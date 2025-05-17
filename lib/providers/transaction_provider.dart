import 'package:flutter/material.dart';
import 'package:finance_app/models/transaction_model.dart';

class TransactionProvider extends ChangeNotifier {
  final List<TransactionModel> _transactions = [];

  List<TransactionModel> get transactions => _transactions;

  void addTransaction(TransactionModel transaction) {
    _transactions.add(transaction);
    notifyListeners();
  }

  double get totalBalance => income - expenses;

  double get income => _transactions
      .where((t) => t.type == 'Income')
      .fold(0, (sum, t) => sum + t.amount);

  double get expenses => _transactions
      .where((t) => t.type == 'Expense')
      .fold(0, (sum, t) => sum + t.amount);
}
