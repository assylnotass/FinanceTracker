import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecurringTransactionHelper {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> checkAndCreateRecurringTransactions() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final snap = await _firestore
        .collection('transactions')
        .doc(uid)
        .collection('user_transactions')
        .where('recurring', isEqualTo: true)
        .get();

    final now = DateTime.now();

    for (final doc in snap.docs) {
      final data = doc.data();
      final startDate = (data['startDate'] as Timestamp?)?.toDate();
      final recurrence = data['recurrence'] ?? 'Monthly';
      final lastDate = (data['lastGenerated'] as Timestamp?)?.toDate();

      if (startDate == null) continue;

      final nextDate = _calculateNextDate(startDate, recurrence, lastDate);
      if (nextDate == null) continue;

      if (_isSameDay(now, nextDate)) {
        final txData = Map<String, dynamic>.from(data);
        txData['timestamp'] = Timestamp.fromDate(now);
        txData['date'] = Timestamp.fromDate(now);
        txData['recurring'] = false;
        txData.remove('lastGenerated');
        txData.remove('startDate');

        await _firestore
            .collection('transactions')
            .doc(uid)
            .collection('user_transactions')
            .add(txData);

        await _firestore
            .collection('transactions')
            .doc(uid)
            .collection('user_transactions')
            .doc(doc.id)
            .update({'lastGenerated': Timestamp.fromDate(now)});
      }
    }
  }

  static DateTime? _calculateNextDate(DateTime start, String recurrence, DateTime? last) {
    final base = last ?? start;
    if (recurrence == 'Monthly') {
      return DateTime(base.year, base.month + 1, base.day);
    } else if (recurrence == 'Weekly') {
      return base.add(const Duration(days: 7));
    }
    return null;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
