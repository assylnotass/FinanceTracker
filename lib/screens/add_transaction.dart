import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';
import 'package:finance_app/localization/app_localization.dart';
import 'package:finance_app/localization/app_localization.dart';

class AddTransactionScreen extends StatefulWidget {
  final Map<String, dynamic>? editingTx;
  const AddTransactionScreen({super.key, this.editingTx});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool _isImporting = false;
  bool _cancelImport = false;
  final _formKey = GlobalKey<FormState>();

  String _type = 'Expense';
  String _category = 'Food';
  String _description = '';
  String _subscriptionName = '';
  double _amount = 0.0;
  DateTime _selectedDate = DateTime.now();
  bool _isFamily = false;
  bool _isRecurring = false;
  String _recurrence = 'Monthly';
  String? _editingId;

  final List<String> _categories = [
    'Food', 'Transport', 'Shopping', 'Salary', 'Subscription', 'Custom...'
  ];

  String localizeType(AppLocalizations loc, String type) {
    switch (type) {
      case 'Income':
        return loc.income;
      case 'Expense':
        return loc.expense;
      default:
        return type;
    }
  }

  @override
  void initState() {
    super.initState();
    final tx = widget.editingTx;
    if (tx != null) {
      _editingId = tx['id'];
      _type = tx['type'] ?? _type;
      _category = tx['category'] ?? _category;
      _description = tx['description'] ?? '';
      _subscriptionName = tx['subscriptionName'] ?? '';
      _amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      _selectedDate = (tx['date'] as Timestamp?)?.toDate() ?? DateTime.now();
      _isFamily = tx['isFamily'] ?? false;
      _isRecurring = tx['recurring'] ?? false;
      _recurrence = tx['recurrence'] ?? 'Monthly';
    }
  }

  InputDecoration roundedInputDecoration(String label, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: theme.cardColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _importKaspiPdf() async {
  final loc = AppLocalizations.of(context)!;
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;

    setState(() {
      _isImporting = true;
      _cancelImport = false;
    });

    final file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();
    final pdf = PdfDocument(inputBytes: bytes);

    String fullText = '';
    for (int i = 0; i < pdf.pages.count; i++) {
      if (_cancelImport) {
        pdf.dispose();
        setState(() => _isImporting = false);
        return;
      }
      final pageText = PdfTextExtractor(pdf).extractText(startPageIndex: i, endPageIndex: i);
      fullText += '\n$pageText';
      if (i % 3 == 0) await Future.delayed(Duration.zero);
    }

    pdf.dispose();

    final parsed = _parseKaspiText(fullText);
    if (parsed.isEmpty) {
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.importError)));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.import),
        content: Text('${loc.importConfirm} (${parsed.length})'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc.cancel,)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(loc.import)),
        ],
      ),
    );

    if (confirm != true) {
      setState(() => _isImporting = false);
      return;
    }

    await _saveParsedTransactions(parsed);

    setState(() => _isImporting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${loc.importSuccess} ${parsed.length}')),
    );
  } catch (e) {
    setState(() => _isImporting = false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.error),
        content: Text(loc.importError),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.ok,))],
      ),
    );
  }
}

  String _detectCategory(String details) {
    final lower = details.toLowerCase();

    final keywords = {
      'Food': [
        // Фастфуд и заведения
        'еда', 'фастфуд', 'бургер', 'донер', 'шаурма', 'kfc', 'мак', 'mcdonalds', 'burger', 'burger king',
        'hardee\'s', 'papa johns', 'dominos', 'tarragon', 'lotus', 'tasty', 'hotdog',
        // Кофе и десерты
        'кофе', 'кофейня', 'coffee', 'starbucks', 'cofix', 'gloria jeans', 'lavazza', 'какао', 'капучино',
        'маффин', 'десерт', 'пирог', 'торт', 'выпечка', 'donuts', 'dunkin', 'круассан',
        // Суши и японская кухня
        'sushi', 'суши', 'роллы', 'сашими', 'японская кухня', 'sushiwok', 'sushitime', 'tanuki', 'sushihouse',
        // Пицца и итальянская кухня
        'пицца', 'pizza', 'дон пицца', 'доминос', 'пиццерия', 'итальянская кухня', 'паста',
        // Казахская и восточная кухня
        'плов', 'самса', 'лагман', 'манты', 'казахская кухня', 'шашлык', 'бешбармак', 'ханский двор',
        // Сети и доставка
        'wolt', 'glovo', 'yandex еда', 'yanGO', 'доставка еды', 'еда на дом', 'кальян кафе', 'cafe', 'ресторан',
        // Прочее
        'закуски', 'напитки', 'безалкогольные', 'вода', 'сок', 'чай', 'обед', 'ужин', 'завтрак'
      ],
      'Transport': ['такси', 'bus', 'onay', 'автобус', 'yandex', 'avtobys', 'транспорт', 'тс', 'транспортное средство'],
      'Shopping': [
        // Онлайн-платформы и маркетплейсы
        'ozon', 'wildberries', 'алиэкспресс', 'aliexpress', 'kaspi магазин', 'kaspi store',
        'yandex market', 'trendyol', 'shein', 'lamoda', 'satu.kz', 'technodom', 'sulpak',
        'mechta.kz', 'shop.kz', 'dar mart', 'small.kz', 'flip.kz', 'pulser.kz',
        // Торговые центры
        'тц', 'трц', 'торговый центр', 'mega silk way', 'mega center', 'mega almaty', 'mega park',
        'dostyk plaza', 'esentai mall', 'forum almaty', 'astana mall', 'tsum', 'цум', 'arbat',
        // Одежда, обувь, мода
        'bershka', 'pull&bear', 'zara', 'h&m', 'lc waikiki', 'defacto', 'stradivarius', 'reserved',
        'mango', 'massimo dutti', 'new yorker', 'house', 'cropp', 'colin\'s', 'sela', 'tom tailor',
        // Обувь и спорт
        'adidas', 'nike', 'reebok', 'puma', 'спортмастер', 'street beat', 'intertop', 'sneaker box',
        // Косметика и парфюмерия
        'парфюмерия', 'perfume', 'косметика', 'cosmetics', 'beauty', 'letu.kz', 'letu', 'sephora',
        'rivgosh', 'gold apple', 'l\'etoile', 'mac', 'nyx', 'beauty bar',
        // Универсальные магазины и товары
        'одежда', 'женская одежда', 'мужская одежда', 'аксессуары', 'часы', 'сумки', 'одежда для детей',
        'игрушки', 'товары для дома', 'бытовая техника', 'электроника', 'мебель', 'ikea',
        // Казахстанские магазины
        'arbuz.kz', 'kenmart', 'a-store', 'smartstore', 'marwin', 'meloman', 'buka', 'kino.kz', 'airba'
        // Турецкие/восточные бренды
        'waikiki', 'defacto', 'koton', 'collezione', 'madame coco',
        // Общие ключевые слова
        'shopping', 'магазин', 'fashion', 'look', 'style', 'butik'
      ],
      'Groceries': ['magnum', 'small', 'маркет', 'qurmet', 'супермаркет', 'магазин', 'продукты', 'гипермаркет', 'гипер', 'ip', 'ип'],
      'Entertainment': ['кино', 'театр', 'concert', 'развлечение', 'event', 'развлекуха', 'клуб', 'party', 'chaplin', 'kinopark', 'билеты', 'билет', 'развлекательный', 'развлекательный центр', 'развлечения'],
      'Subscription': ['netflix', 'spotify', 'подписка', 'apple', 'google', 'подписка на сервис', 'подписка на контент', 'yandex.plus'],
      'Health': [
        // Аптеки
        'аптека', 'apteka', 'pharmacy', 'e-apteka', 'аптека жан', 'таблетка', 'фарм', 'dari kz', 'аптека.ру',
        'pharmstore', 'таблетки', 'лекарство', 'лекарства', 'витамины', 'парацетамол', 'анальгин', 'аспирин',
        // Медицинские центры и услуги
        'health', 'медицинский центр', 'медцентр', 'медицинская', 'медицина', 'психолог', 'психотерапевт',
        'стоматология', 'стоматолог', 'dental', 'клиника', 'clinic', 'медосмотр', 'анализы', 'лаборатория', 'лаборатория инвитро',
        'invivo', 'olymp', 'synlab', 'mediker', 'sunkar', 'megacenter clinic', 'cmc', 'inmed', 'zhan clinic',
        // Страховки
        'медицинская страховка', 'страховка', 'health insurance', 'дмс', 'омс', 'страхование здоровья',
        // Оборудование и услуги
        'массаж', 'аппарат', 'реабилитация', 'терапия', 'физиотерапия', 'инъекция', 'укол', 'узи', 'мрт',
        'рентген', 'анализ крови', 'экг', 'энмг', 'пцр', 'вакцинация', 'прививка', 'глюкометр', 'тонометр',
        // Бренды и сети
        'asna', 'sos doctor', 'aptekaplus', 'planetapharm', 'europharma', 'pharmadel', '1001 аптека',
        'аптека авиценна', 'аптека астана', 'биосфера'
      ],
      'Salary': ['зп', 'зарплата', 'salary', 'премия', 'bonus', 'вознаграждение', 'вознаграждение за работу', 'заработная плата', 'вознаграждение за труд'],
      'Utilities': [
        // Интернет и связь
        'интернет', 'wi-fi', 'wifi', 'телеком', 'kazakhtelecom', 'казахтелеком', 'kcell',
        'beeline', 'tele2', 'altel', 'activ', 'izi', 'almatv', 'inet', 'megacom', 'netto',
        'провайдер', 'скорость интернета', 'домашний интернет',
        // Мобильная связь и операторы
        'тариф', 'оплата телефона', 'мобильная связь', 'баланс телефона', 'мобсвязь',
        'мобильный оператор', 'перевод на номер', 'баланс activ', 'пополнение altel',
        // Коммунальные услуги
        'коммунальные', 'коммуналка', 'жкх', 'электричество', 'газ', 'вода', 'тепло', 'отопление',
        'водоснабжение', 'электроэнергия', 'вода кан', 'водоканал', 'техобслуживание',
        // Единые сервисы оплаты
        'кск', 'ерц', 'epay', 'qpay', 'оплата услуг', 'счет за услуги', 'оплата счетов', 'услуги',
        // Телевидение и кабель
        'tv', 'iptv', 'телевидение', 'цифровое тв', 'кабельное тв', 'телевидение от', 'интернет + тв',
        // Другие провайдеры и бренды
        'alma tv', 'id tv', 'sevensky', 'ott', 'интерсвязь', 'connect', 'home tv', 'arsat', 'akhynet'
      ],
      'Transfer': ['перевод', 'kaspi перевод', 'p2p', 'перевод на карту', 'перевод между картами'],
      'Cash': ['наличные', 'снятие наличных', 'cash', 'снятие', 'банкомат', 'ATM'],
      'Top up': ['пополнение', 'top up', 'пополнение счета', 'пополнение карты', 'пополнение баланса', 'с карты другого банка'],
    };

    for (final entry in keywords.entries) {
      if (entry.value.any((kw) => lower.contains(kw))) {
        return entry.key;
      }
    }

    return 'Other';
  }

List<Map<String, dynamic>> _parseKaspiText(String text) {
  final regex = RegExp(
    r'(\d{2}\.\d{2}\.\d{2})\s+([+-])\s*([\d\s.,]+)[^\d]+?(Покупка|Перевод|Пополнение|Снятие|Разное)\s+(.*)',
  );

  final matches = regex.allMatches(text);

  return matches.map((m) {
    final date = m.group(1)!;
    final sign = m.group(2)!;
    final amount = double.parse(m.group(3)!.replaceAll(' ', '').replaceAll(',', '.'));
    final operation = m.group(4)!; // "Покупка", "Перевод", ...
    final details = m.group(5)!;   // например: "Magnum", "Kaspi", "Алия"

    final type = sign == '+' ? 'Income' : 'Expense';

    final category = operation == 'Покупка'
        ? _detectCategory(details.toLowerCase())
        : _mapToInternalCategory(operation);


    return {
      'id': const Uuid().v4(),
      'date': DateTime.parse('20${date.split('.').reversed.join('-')}'),
      'amount': amount,
      'type': type,
      'category': category,
      'description': details,
      'isFamily': false,
    };
  }).toList();
}


  Future<void> _saveParsedTransactions(List<Map<String, dynamic>> txs) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    for (final tx in txs) {
      final ref = FirebaseFirestore.instance
          .collection('transactions')
          .doc(uid)
          .collection('user_transactions')
          .doc(tx['id']);

      await ref.set({
        'id': tx['id'],
        'amount': tx['amount'],
        'type': tx['type'],
        'category': tx['category'],
        'description': tx['description'],
        'details': tx['details'],
        'isFamily': tx['isFamily'],
        'date': tx['date'],
        'timestamp': Timestamp.fromDate(tx['date']),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  String _mapToInternalCategory(String cat) {
    final loc = AppLocalizations.of(context)!;
    if (cat == loc.localizeCategory('Food')) return 'Food';
    if (cat == loc.localizeCategory('Transport')) return 'Transport';
    if (cat == loc.localizeCategory('Shopping')) return 'Shopping';
    if (cat == loc.localizeCategory('Salary')) return 'Salary';
    if (cat == loc.localizeCategory('Subscription')) return 'Subscription';
    if (cat == loc.localizeCategory('Health')) return 'Health';
    if (cat == loc.localizeCategory('Utilities')) return 'Utilities';
    if (cat == loc.localizeCategory('Groceries')) return 'Groceries';
    if (cat == loc.localizeCategory('Entertainment')) return 'Entertainment';
    if (cat == loc.localizeCategory('Transfer')) return 'Transfer';
    if (cat == loc.localizeCategory('Cash')) return 'Cash';
    if (cat == loc.localizeCategory('Top up')) return 'Top up';
    if (cat == loc.localizeCategory('Other')) return 'Other';
    if (cat.toLowerCase() == 'пополнение') return 'Top up';
    if (cat.toLowerCase() == 'перевод') return 'Transfer';
    return cat;
  }

  Future<void> _saveTransaction() async {
  if (!_formKey.currentState!.validate()) return;
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final id = _editingId ?? const Uuid().v4();

  final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final userData = userDoc.data();
  final familyId = userData?['familyId'];

  final tx = {
    'id': id,
    'amount': _amount,
    'type': _type,
    'category': _mapToInternalCategory(_category),
    'description': _description,
    'subscriptionName': _subscriptionName,
    'date': _selectedDate,
    'timestamp': Timestamp.fromDate(_selectedDate),
    'isFamily': _isFamily,
    'recurring': _isRecurring,
    'recurrence': _isRecurring ? _recurrence : null,
    'startDate': _isRecurring ? _selectedDate : null,
    'createdAt': FieldValue.serverTimestamp(),
    'owner': uid,
    'ownerName': userData?['name'] ?? '—',
  };

  DocumentReference ref;

  if (_isFamily && familyId != null && familyId.isNotEmpty) {
    ref = FirebaseFirestore.instance
        .collection('families')
        .doc(familyId)
        .collection('transactions')
        .doc(id);
  } else {
    ref = FirebaseFirestore.instance
        .collection('transactions')
        .doc(uid)
        .collection('user_transactions')
        .doc(id);
  }

  await ref.set(tx);

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context)!.save)),
  );
  Navigator.maybePop(context, true);
}



  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
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
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        loc.addTransaction,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                        onPressed: _importKaspiPdf,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _type,
                          decoration: roundedInputDecoration(loc.type, theme),
                          items: ['Income', 'Expense']
                              .map((v) => DropdownMenuItem(value: v, child: Text(localizeType(loc, v))))
                              .toList(),
                          onChanged: (val) => setState(() => _type = val!),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _category,
                          decoration: roundedInputDecoration(loc.category, theme),
                          items: _categories
                              .map((v) => DropdownMenuItem(value: v, child: Text(loc.localizeCategory(v)))) 
                              .toList(),
                          onChanged: (val) => setState(() => _category = val!),
                        ),
                        if (_category == 'Custom...')
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: TextFormField(
                              decoration: roundedInputDecoration(loc.inputCategory, theme),
                              onChanged: (val) => _category = val,
                            ),
                          ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: roundedInputDecoration(loc.description, theme),
                          onChanged: (val) => _description = val,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: roundedInputDecoration(loc.inputAmount, theme),
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            final parsed = double.tryParse(val ?? '');
                            if (parsed == null) return 'Введите число';
                            if (parsed <= 0) return 'Сумма должна быть больше нуля';
                            return null;
                          },
                          onChanged: (val) => _amount = double.tryParse(val) ?? 0.0,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}'),
                            const Spacer(),
                            TextButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) setState(() => _selectedDate = picked);
                              },
                              child: Text(loc.selectDate),
                            ),
                          ],
                        ),
                        SwitchListTile(
                          title: Text(loc.familyTransaction),
                          value: _isFamily,
                          onChanged: (val) => setState(() => _isFamily = val),
                        ),
                        SwitchListTile(
                          title: Text(loc.recurring),
                          value: _isRecurring,
                          onChanged: (val) => setState(() => _isRecurring = val),
                        ),
                        if (_isRecurring)
                          DropdownButtonFormField<String>(
                            value: _recurrence,
                            decoration: roundedInputDecoration(loc.recurrence, theme),
                            items: ['Weekly', 'Monthly']
                                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                                .toList(),
                            onChanged: (val) => setState(() => _recurrence = val!),
                          ),
                        if (_category == 'Subscription')
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: TextFormField(
                              decoration: roundedInputDecoration(loc.subscriptionName, theme),
                              onChanged: (val) => _subscriptionName = val,
                            ),
                          ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _saveTransaction,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(loc.save, style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isImporting)
            Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.black.withOpacity(0.3)),
                ),
                Center(
                  child: AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text(loc.importing),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
