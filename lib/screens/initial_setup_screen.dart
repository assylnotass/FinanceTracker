import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/app_settings.dart';
import '../main.dart';

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  String _selectedLanguage = 'Русский';
  String _selectedCurrency = 'KZT';
  bool _darkTheme = false;

  final List<Map<String, String>> currencies = const [
    {'code': 'USD', 'label': '🇺🇸 Доллар США'},
    {'code': 'AED', 'label': '🇦🇪 Дирхам (Дубай)'},
    {'code': 'RUB', 'label': '🇷🇺 Российский рубль'},
    {'code': 'KZT', 'label': '🇰🇿 Казахстанский тенге'},
    {'code': 'UZS', 'label': '🇺🇿 Узбекский сум'},
    {'code': 'TJS', 'label': '🇹🇯 Таджикский сомони'},
    {'code': 'UAH', 'label': '🇺🇦 Украинская гривна'},
    {'code': 'BYN', 'label': '🇧🇾 Белорусский рубль'},
    {'code': 'GEL', 'label': '🇬🇪 Грузинский лари'},
    {'code': 'EUR', 'label': '🇪🇺 Евро'},
    {'code': 'GBP', 'label': '🇬🇧 Фунт стерлингов'},
    {'code': 'TRY', 'label': '🇹🇷 Турецкая лира'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    final media = await Permission.photos.request();
    final notif = await Permission.notification.request();

    if (media.isDenied || notif.isDenied) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Разрешения'),
          content: const Text('Приложению нужно разрешение на доступ к медиа и уведомлениям.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ОК'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _completeSetup() async {
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    String langCode;
    switch (_selectedLanguage) {
      case 'English':
        langCode = 'en';
        break;
      case 'Қазақша':
        langCode = 'kk';
        break;
      default:
        langCode = 'ru';
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).collection('settings').doc('prefs').set({
      'currency': _selectedCurrency,
      'theme': _darkTheme ? 'dark' : 'light',
      'language': langCode,
    });

    await appSettings.finishInitialSetup(
      currency: _selectedCurrency,
      darkTheme: _darkTheme,
      languageCode: langCode,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const NavigationController()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey<bool>(_darkTheme),
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF81C784), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView(
                  children: [
                    const Text('1. Какой язык вам удобен?', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedLanguage,
                      items: const ['Русский', 'English', 'Қазақша'].map((lang) {
                        return DropdownMenuItem(value: lang, child: Text(lang));
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedLanguage = value!);
                        appSettings.setLanguage(
                          value == 'English'
                              ? 'en'
                              : value == 'Қазақша'
                                  ? 'kk'
                                  : 'ru',
                        );
                      },
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),

                    const Text('2. Какую валюту поставить?', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      items: currencies.map((item) {
                        return DropdownMenuItem(
                          value: item['code'],
                          child: Text(item['label']!),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedCurrency = value!),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),

                    const Text('3. Какую тему хотите?', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Тёмная тема'),
                      value: _darkTheme,
                      onChanged: (val) {
                        setState(() => _darkTheme = val);
                        appSettings.setDarkMode(val);
                      },
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _completeSetup,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: const Color(0xFF4CAF50),
                      ),
                      child: const Text(
                        'Продолжить',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
