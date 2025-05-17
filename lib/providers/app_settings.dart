// lib/providers/app_settings.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_app/localization/app_localization.dart';

class AppSettings extends ChangeNotifier {
  bool _darkMode = false;
  String _currency = 'KZT';
  bool _notifications = true;
  bool _isFirstLaunch = true;
  String _languageCode = 'ru';

  bool get isDarkMode => _darkMode;
  String get currency => _currency;
  bool get notificationsEnabled => _notifications;
  bool get isFirstLaunch => _isFirstLaunch;
  Locale get locale => Locale(_languageCode);

  AppSettings() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('darkMode') ?? false;
    _currency = prefs.getString('currency') ?? 'KZT';
    _notifications = prefs.getBool('notifications') ?? true;
    _isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    _languageCode = prefs.getString('languageCode') ?? 'ru';
    notifyListeners();
  }

  Future<void> toggleTheme(bool enabled) async {
    _darkMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', enabled);
    notifyListeners();
  }

  void setDarkMode(bool enabled) {
    _darkMode = enabled;
    notifyListeners();
  }

  void setLanguageCode(String code) {
    _languageCode = code;
    notifyListeners();
  }


  Future<void> toggleNotifications(bool enabled) async {
    _notifications = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', enabled);
    notifyListeners();
  }

  Future<void> setCurrency(String cur) async {
    _currency = cur;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', cur);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', code);
    notifyListeners();
  }

  Future<void> finishInitialSetup({
    required String currency,
    required bool darkTheme,
    required String languageCode,
  }) async {
    _currency = currency;
    _darkMode = darkTheme;
    _languageCode = languageCode;
    _isFirstLaunch = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
    await prefs.setBool('darkMode', darkTheme);
    await prefs.setString('languageCode', languageCode);
    await prefs.setBool('isFirstLaunch', false);

    notifyListeners();
  }

}