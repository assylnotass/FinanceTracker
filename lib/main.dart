import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/localization/app_localization.dart';

import 'package:finance_app/screens/home.dart';
import 'package:finance_app/screens/transactions_history.dart';
import 'package:finance_app/screens/add_transaction.dart';
import 'package:finance_app/screens/budgets.dart';
import 'package:finance_app/screens/statistics.dart';
import 'package:finance_app/screens/settings.dart';
import 'package:finance_app/screens/login_screen.dart';
import 'package:finance_app/screens/profile_screen.dart';
import 'package:finance_app/screens/notification_screen.dart';
import 'package:finance_app/screens/budget_goals.dart';
import 'package:finance_app/screens/initial_setup_screen.dart';
import 'package:finance_app/screens/pin_lock_screen.dart';

import 'package:finance_app/providers/app_settings.dart';
import 'package:finance_app/providers/transaction_provider.dart';
import 'package:finance_app/helpers/pin_helper.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Уведомления
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Проверка PIN
  final pin = await PinHelper.getPin();
  final startWithPin = pin != null && pin.isNotEmpty;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppSettings()),
        ChangeNotifierProvider(create: (context) => TransactionProvider()),
      ],
      child: MyApp(startWithPin: startWithPin),
    ),
  );
}


class MyApp extends StatelessWidget {
  final bool startWithPin;

  const MyApp({super.key, required this.startWithPin});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finance App',
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light().copyWith(
        textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Montserrat'),
      ),
      darkTheme: ThemeData.dark().copyWith(
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Montserrat'),
      ),
      locale: settings.locale,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: FirebaseAuth.instance.currentUser == null
          ? const LoginScreen()
          : settings.isFirstLaunch
              ? const InitialSetupScreen()
              : startWithPin
                  ? const PinLockScreen()
                  : const NavigationController(),
      initialRoute: '/',
      routes: {
        '/add_transaction': (context) => const AddTransactionScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }
}


class NavigationController extends StatefulWidget {
  const NavigationController({super.key});

  @override
  State<NavigationController> createState() => _NavigationControllerState();
}

class _NavigationControllerState extends State<NavigationController> {
  int _selectedIndex = 0;
  String _userName = '';
  String _avatarUrl = '';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<HomeState> _homeKey = GlobalKey<HomeState>();
  final GlobalKey<TransactionsHistoryState> _historyKey = GlobalKey<TransactionsHistoryState>();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (!mounted) return;
    if (data != null) {
      setState(() {
        _userName = data['name'] ?? '';
        _avatarUrl = data['avatarUrl'] ?? '';
      });
    }
  }

  void _onDrawerItemTap(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context);
    });
  }

  void _onAddPressed() async {
    final result = await Navigator.pushNamed(context, '/add_transaction');
    if (result == true && mounted) {
      if (_selectedIndex == 0) {
        _homeKey.currentState?.loadTransactions();
      } else if (_selectedIndex == 1) {
        _historyKey.currentState?.loadTransactions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final List<Widget> pages = [
      Home(
        key: _homeKey,
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      TransactionsHistory(
        key: _historyKey,
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      BudgetsScreen(
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      StatisticsScreen(
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      SettingsScreen(
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      ProfileScreen(
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      BudgetGoalsScreen(
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
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
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                      child: _avatarUrl.isEmpty
                          ? const Icon(Icons.account_circle, size: 40, color: Colors.green)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _userName.isNotEmpty ? _userName : loc.menu,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(loc.home),
              onTap: () => _onDrawerItemTap(0),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(loc.transactionHistory),
              onTap: () => _onDrawerItemTap(1),
            ),
            ListTile(
              leading: const Icon(Icons.pie_chart),
              title: Text(loc.budgets),
              onTap: () => _onDrawerItemTap(2),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text(loc.statistics),
              onTap: () => _onDrawerItemTap(3),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(loc.settings),
              onTap: () => _onDrawerItemTap(4),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(loc.profile),
              onTap: () => _onDrawerItemTap(5),
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: Text(loc.budgetGoals),
              onTap: () => _onDrawerItemTap(6),
            ),
          ],
        ),
      ),
      body: pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: FloatingActionButton.extended(
                onPressed: _onAddPressed,
                backgroundColor: const Color(0xFF4CAF50),
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  loc.add,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

