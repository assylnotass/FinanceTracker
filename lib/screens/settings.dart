import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings.dart';
import '../localization/app_localization.dart';
import '../helpers/pin_helper.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onMenuTap;

  const SettingsScreen({Key? key, required this.onMenuTap}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

  void _showCurrencyDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.selectCurrency),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: currencies.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final currency = currencies[index];
              return ListTile(
                title: Text(currency['label']!),
                onTap: () {
                  appSettings.setCurrency(currency['code']!);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            child: Text(loc.cancel),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    final current = appSettings.locale.languageCode;
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['ru', 'en', 'kk'].map((code) {
            final label = {
              'ru': 'Русский',
              'en': 'English',
              'kk': 'Қазақша',
            }[code];
            return RadioListTile<String>(
              value: code,
              groupValue: current,
              title: Text(label!),
              onChanged: (val) async {
                await appSettings.setLanguage(val!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            child: Text(loc.cancel),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  Future<void> _togglePin(BuildContext context, bool enable) async {
    final loc = AppLocalizations.of(context)!;

    if (!enable) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(loc.confirmDeleteTransaction),
          content: Text(loc.confirmDisablePin ?? 'Вы уверены, что хотите отключить PIN?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(loc.ok),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await PinHelper.clearPin();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.pinDisabled ?? 'PIN отключён')),
          );
          setState(() {}); // обновить UI
        }
      }
    } else {
      final controller = TextEditingController();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(loc.pinLabel),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: InputDecoration(labelText: loc.pinLabel),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                await PinHelper.setPin(controller.text);
                if (context.mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.save)),
                );
                setState(() {}); // обновить UI
              },
              child: Text(loc.save),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context);
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Builder(
        builder: (context) => Column(
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
                    Text(
                      loc.settings,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.white),
                      onPressed: () {
                        Navigator.pushNamed(context, '/notifications');
                      },
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ListTile(
                    title: Text(loc.language),
                    subtitle: Text({
                      'ru': 'Русский',
                      'en': 'English',
                      'kk': 'Қазақша',
                    }[appSettings.locale.languageCode]!),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLanguageDialog(context),
                  ),
                  const Divider(),
                  ListTile(
                    title: Text(loc.currency),
                    subtitle: Text(appSettings.currency),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showCurrencyDialog(context),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text(loc.darkMode),
                    value: appSettings.isDarkMode,
                    onChanged: (value) => appSettings.toggleTheme(value),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text(loc.notifications),
                    value: appSettings.notificationsEnabled,
                    onChanged: (value) => appSettings.toggleNotifications(value),
                  ),
                  const Divider(),

                  FutureBuilder<String?>(
                    future: PinHelper.getPin(),
                    builder: (context, snapshot) {
                      final hasPin = snapshot.data != null && snapshot.data!.isNotEmpty;
                      return SwitchListTile(
                        title: Text(loc.pinLabel),
                        value: hasPin,
                        onChanged: (value) => _togglePin(context, value),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
