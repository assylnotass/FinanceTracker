import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:finance_app/main.dart'; // чтобы получить доступ к plugin
import 'package:provider/provider.dart';
import 'package:finance_app/providers/app_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> showNotification(String title, String body, BuildContext context) async {
final uid = FirebaseAuth.instance.currentUser?.uid;
if (uid == null) return;

final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
final settings = userDoc.data() ?? {};
if (!(settings['notificationsEnabled'] ?? true)) return;


  const androidDetails = AndroidNotificationDetails(
    'budget_channel',
    'Budget Alerts',
    channelDescription: 'Notify about payments or budget status',
    importance: Importance.max,
    priority: Priority.high,
  );

  const platformDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(0, title, body, platformDetails);
}
