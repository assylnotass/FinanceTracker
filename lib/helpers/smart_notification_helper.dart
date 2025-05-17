import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SmartNotificationHelper {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> checkSmartNotifications() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final settings = userDoc.data() ?? {};
    final notificationsEnabled = settings['notificationsEnabled'] ?? true;
    if (!notificationsEnabled) return;

    final now = DateTime.now();
    final since = now.subtract(const Duration(days: 30));

    final txSnap = await _firestore
        .collection('transactions')
        .doc(uid)
        .collection('user_transactions')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(since))
        .get();

    final txs = txSnap.docs.map((d) => d.data()).toList();

    double income = 0, expense = 0;
    final categoryTotals = <String, double>{};
    final subscriptions = <Map<String, dynamic>>[];

    for (var tx in txs) {
      final amount = (tx['amount'] as num).toDouble();
      final type = tx['type'];
      final cat = tx['category'] ?? '';
      final time = (tx['timestamp'] as Timestamp?)?.toDate();
      final desc = tx['description'] ?? '';

      if (time == null) continue;

      if (type == 'Expense') {
        expense += amount;
        categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amount;
        if (cat == 'Subscription' &&
            now.difference(time).inDays % 30 == 29) {
          subscriptions.add({'name': desc, 'amount': amount});
        }
      } else if (type == 'Income') {
        income += amount;
      }
    }

    final messages = <String>[];

    // 1. Лимиты
    final limits = {
      'Food': 50000,
      'Transport': 20000,
      'Subscription': 10000,
    };

    limits.forEach((cat, limit) {
      final spent = categoryTotals[cat] ?? 0;
      if (spent >= limit) {
        messages.add('❗ Превышен лимит $limit ₸ на $cat. Потрачено: ${spent.toInt()} ₸');
      } else if (spent > 0.8 * limit) {
        messages.add('⚠️ Вы потратили ${spent.toInt()} ₸ на $cat — ${(spent / limit * 100).toStringAsFixed(0)}% от лимита.');
      }
    });

    // 2. Подписки
    for (var sub in subscriptions) {
      messages.add('📅 Завтра списание подписки "${sub['name']}" — ${sub['amount']} ₸');
    }

    // 3. Скачки
    if ((categoryTotals['Entertainment'] ?? 0) > 40000) {
      messages.add('💸 Вы потратили на развлечения больше обычного. Проверьте траты.');
    }

    // 4. Итог недели
    messages.add('📊 Неделя: Доход ${income.toInt()} ₸, Расход ${expense.toInt()} ₸. Баланс: ${(income - expense).toInt()} ₸');

    // 5. Обработка: без спама
    for (final text in messages) {
      final exists = await _firestore
          .collection('notifications')
          .doc(uid)
          .collection('items')
          .where('message', isEqualTo: text)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 12))))
          .get();

      if (exists.docs.isEmpty) {
        await _firestore
            .collection('notifications')
            .doc(uid)
            .collection('items')
            .add({
          'message': text,
          'timestamp': Timestamp.now(),
          'read': false,
        });

        await _showPushNotification('Finance App', text);
      }
    }
  }

  static Future<void> _showPushNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'smart_channel',
      'Smart Assistant',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
    );
  }
}
