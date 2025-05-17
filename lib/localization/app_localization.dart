// lib/localization/app_localizations.dart
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('en'),
    Locale('ru'),
    Locale('kk'),
  ];

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  String localizeCategory(String category) {
  switch (category) {
    case 'Food':
      return food;
    case 'Transport':
      return transport;
    case 'Shopping':
      return shopping;
    case 'Salary':
      return salary;
    case 'Subscription':
      return subscription;
    case 'Health':
      return health;
    case 'Utilities':
      return utilities;
    case 'Groceries':
      return groceries;
    case 'Entertainment':
      return entertainment;
    case 'Transfer':
      return transfer;
    case 'Cash':
      return cash;
    case 'Top up':
      return topup;
    case 'Other':
      return other;
    default:
      return category;
  }
}

  static const _localizedStrings = {
    'en': {
      'importing': 'Importing...',
      'import': 'Import',
      'export': 'Export',
      'importError': 'Import error',
      'exportError': 'Export error',
      'importConfirm': 'Are you sure you want to import this file? Found transactions:',
      'importSuccess': 'Import successful! Imported transactions:',
      'error': 'Error',
      'ok': 'OK',
      'select': 'Select',
      'cancel': 'Cancel',
      'selectAll': 'Select All',
      'unselectAll': 'Unselect All',
      'menu': 'Menu',
      'noData': 'No data available',
      'expenseByCategory': 'Expense by category',
      'monthlyExpenses': 'Monthly expenses',
      'January': 'Jan',
      'February': 'Feb',
      'March': 'Mar',
      'April': 'Apr',
      'May': 'May',
      'June': 'Jun',
      'July': 'Jul',
      'August': 'Aug',
      'September': 'Sep',
      'October': 'Oct',
      'November': 'Nov',
      'December': 'Dec',
      'deleteMember': 'Delete member',
      'confirmDeleteMember': 'Are you sure you want to delete this member?',
      'createFamily': 'Create family',
      'inviteCode': 'Invite code',
      'familyMembers': 'Family members',
      'leaveFamily': 'Leave family',
      'confirmLeaveFamily': 'Are you sure you want to leave this family?',
      'confirmLeaveFamilyMessage': 'You will no longer be able to see family members and their transactions.',
      'leave': 'Leave',
      'join': 'Join',
      'alreadyInFamily': 'Already in family',
      'invalidInviteCode': 'Invalid invite code',
      'user': 'User',
      'uncategorized': 'Uncategorized',
      'lastTransactions': 'Last Transactions',
      'balance': 'Balance',
      'settings': 'Settings',
      'language': 'Language',
      'currency': 'Currency',
      'theme': 'Theme',
      'dark_theme': 'Dark Theme',
      'notifications': 'Notifications',
      'select_currency': 'Select currency',
      'select_language': 'Select language',
      'save': 'Save',
      'login': 'Login',
      'logout': 'Logout',
      'profile': 'Profile',
      'email': 'Email',
      'password': 'Password',
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'home': 'Home',
      'transactions': 'Transactions',
      'budgets': 'Budgets',
      'statistics': 'Statistics',
      'add_transaction': 'Add Transaction',
      'continue': 'Continue',
      'welcome': 'Welcome',
      'choose_language': 'Choose your language',
      'name': 'Name',
      'family': 'Family',
      'noFamily': 'No family',
      'familyId': 'Family ID',
      'joinFamily': 'Join family',
      'avatarUpdated': 'Avatar updated successfully',
      'avatarUpdateError': 'Failed to update avatar',
      'profileUpdated': 'Profile updated successfully',
      'transactionHistory': 'Transaction History',
      'budgetGoals': 'Budget Goals',
      "transactionDetails": "Transaction Details",
      "type": "Type",
      "expense": "Expense",
      "income": "Income",
      "category": "Category",
      "subscription": "Subscription",
      "amount": "Amount",
      "date": "Date",
      "description": "Description",
      "close": "Close",
      "sortByAmount": "Sort by Amount",
      "ascending": "Ascending",
      "descending": "Descending",
      "deleteTransaction": "Delete Transaction",
      "confirmDeleteTransaction": "Are you sure you want to delete this transaction?",
      "delete": "Delete",
      "byDate": "By Date",
      "byAmount": "By Amount",
      "exportPdf": "Export PDF",
      "exportCsv": "Export CSV",
      "noTransactions": "No transactions found",
      "darkMode": "Dark Mode",
      "signUpError": "Sign Up Error",
      "notLoggedIn": "You are not logged in",
      "noNotifications": "No notifications",
      "empty": "No data available",
      'loginError': 'Login Error',
      'userNotFound': 'User not found',
      'wrongPassword': 'Wrong password',
      'searchByTransaction': 'Search by transaction',
      'other': 'Other',
      'budgetLimitExceeded': 'Budget limit exceeded',
      'budgetLimitExceededMessage': 'You have exceeded your budget limit for this category:',
      'changeLimit': 'Change limit',
      'noBudgets': 'No budgets available',
      'spended': 'Spent',
      'newGoal': 'New Goal',
      'goalName': 'Goal Name',
      'selectDate': 'Select Date',
      'selectedDate': 'Selected Date',
      'notInFamily': 'Not in family',
      'fillAllFields': 'Please fill all fields',
      'create': 'Create',
      'noGoals': 'No goals available',
      'before': 'Before',
      'accumulated': 'Accumulated',
      'transport': 'Transport',
      'shopping': 'Shopping',
      'salary': 'Salary',
      'customCategory': 'Custom Category',
      'inputCategory': 'Input Category',
      'subscriptionName': 'Subscription Name',
      'inputAmount': 'Input Amount',
      'familyTransaction': 'Family Transaction',
      'transactionReport': 'Transaction Report',
      'verificationSent': 'Verification email sent',
      'emailNotVerified': 'Email not verified',
      'resetEmailSent': 'Reset email sent',
      'resetFailed': 'Reset failed',
      'enterEmailToReset': 'Enter your email to reset password',
      'forgotPassword': 'Forgot Password?',
      'googleSignIn': 'Sign in with Google',
      'dontHaveAccount': 'Don\'t have an account?',
      'from': 'From',
      'recurring': 'Recurring',
      'recurrence': 'Recurrence',
      'add': 'Add',
      'food': 'Food',
      'health': 'Health',
      'utilities': 'Utilities',
      'groceries': 'Groceries',
      'entertainment': 'Entertainment',
      'transfer': 'Transfer',
      'cash': 'Cash',
      'topup': 'Top up',
      'all': 'All',
      'recent': 'Recent',
      'pinTitle': 'Enter PIN or use biometrics',
      'pinLabel': 'PIN code',
      'pinUnlock': 'Unlock',
      'pinError': 'Invalid PIN',
      'forgotPin': 'Forgot PIN?',
      'resetEmailSentPin': 'Reset email sent to your account',
      'resetEmailError': 'Unable to send reset email',
      'confirmDisablePin': 'Are you sure you want to disable PIN lock?',
      'pinDisabled': 'PIN disabled',

    },
    'ru': {
      'importing': 'Импортируем...',
      'all': 'Все',
      'recent': 'Недавние',
      "import": "Импорт",
      "export": "Экспорт",
      "importError": "Ошибка импорта",
      "exportError": "Ошибка экспорта",
      "importConfirm": "Вы уверены, что хотите импортировать этот файл? Найдено транзакции:",
      "importSuccess": "Импорт успешен! Импортировано транзакций:",
      "imported": "Импортировано",
      "error": "Ошибка",
      "ok": "ОК",
      "select": "Выбрать",
      "cancel": "Отмена",
      "selectAll": "Выбрать все",
      "unselectAll": "Отменить все",
      'menu': 'Меню',
      'noData': 'Нет доступных данных',
      'expenseByCategory': 'Расходы по категориям',
      'monthlyExpenses': 'Ежемесячные расходы',
      'January': 'Янв',
      'February': 'Фев',
      'March': 'Мар',
      'April': 'Апр',
      'May': 'Май',
      'June': 'Июн',
      'July': 'Июл',
      'August': 'Авг',
      'September': 'Сен',
      'October': 'Окт',
      'November': 'Ноя',
      'December': 'Дек',
      'deleteMember': 'Удалить участника',
      'confirmDeleteMember': 'Вы уверены, что хотите удалить этого участника?',
      'createFamily': 'Создать семью',
      'inviteCode': 'Код приглашения',
      'familyMembers': 'Члены семьи',
      'leaveFamily': 'Покинуть семью',
      'confirmLeaveFamily': 'Вы уверены, что хотите покинуть эту семью?',
      'confirmLeaveFamilyMessage': 'Вы больше не сможете видеть членов семьи и их транзакции.',
      'leave': 'Покинуть',
      'join': 'Присоединиться',
      'alreadyInFamily': 'Уже в семье',
      'invalidInviteCode': 'Недействительный код приглашения',
      'user': 'Пользователь',
      'uncategorized': 'Без категории',
      'lastTransactions': 'Последние транзакции',
      'balance': 'Баланс',
      'settings': 'Настройки',
      'language': 'Язык',
      'currency': 'Валюта',
      'theme': 'Тема',
      'dark_theme': 'Тёмная тема',
      'notifications': 'Уведомления',
      'select_currency': 'Выберите валюту',
      'select_language': 'Выберите язык',
      'save': 'Сохранить',
      'login': 'Войти',
      'logout': 'Выйти',
      'profile': 'Профиль',
      'email': 'Email',
      'password': 'Пароль',
      'sign_in': 'Войти',
      'sign_up': 'Регистрация',
      'home': 'Главная',
      'transactions': 'Транзакции',
      'budgets': 'Бюджеты',
      'statistics': 'Статистика',
      'add_transaction': 'Добавить транзакцию',
      'continue': 'Продолжить',
      'welcome': 'Добро пожаловать',
      'choose_language': 'Выберите язык',
      'name': 'Имя',
      'family': 'Семья',
      'noFamily': 'Не состоит в семье',
      'familyId': 'ID семьи',
      'joinFamily': 'Присоединиться к семье',
      'avatarUpdated': 'Аватар успешно обновлён',
      'avatarUpdateError': 'Ошибка обновления аватара',
      'profileUpdated': 'Профиль успешно обновлён',
      'transactionHistory': 'История транзакций',
      'budgetGoals': 'Цели бюджета',
      "transactionDetails": "Детали транзакции",
      "type": "Тип",
      "expense": "Расход",
      "income": "Доход",
      "category": "Категория",
      "subscription": "Подписка",
      "amount": "Сумма",
      "date": "Дата",
      "description": "Описание",
      "close": "Закрыть",
      "sortByAmount": "Сортировка по сумме",
      "ascending": "По возрастанию",
      "descending": "По убыванию",
      "deleteTransaction": "Удалить транзакцию",
      "confirmDeleteTransaction": "Вы уверены, что хотите удалить эту транзакцию?",
      "delete": "Удалить",
      "byDate": "По дате",
      "byAmount": "По сумме",
      "exportPdf": "Экспорт PDF",
      "exportCsv": "Экспорт CSV",
      "noTransactions": "Нет транзакций",
      "darkMode": "Тёмный режим",
      "signUpError": "Ошибка регистрации",
      "notLoggedIn": "Вы не вошли в систему",
      "noNotifications": "Нет уведомлений",
      "empty": "Нет доступных данных",
      'loginError': 'Ошибка входа',
      'userNotFound': 'Пользователь не найден',
      'wrongPassword': 'Неверный пароль',
      'searchByTransaction': 'Поиск по транзакции',
      'other': 'Другое',
      'budgetLimitExceeded': 'Превышен лимит бюджета',
      'budgetLimitExceededMessage': 'Вы превысили лимит бюджета для этой категории:',
      'changeLimit': 'Изменить лимит',
      'noBudgets': 'Нет доступных бюджетов',
      'spended': 'Потрачено',
      'newGoal': 'Новая цель',
      'goalName': 'Имя цели',
      'selectDate': 'Выберите дату',
      'selectedDate': 'Выбранная дата',
      'notInFamily': 'Не состоит в семье',
      'fillAllFields': 'Пожалуйста, заполните все поля',
      'create': 'Создать',
      'noGoals': 'Нет доступных целей',
      'before': 'До',
      'accumulated': 'Накоплено',
      'food': 'Еда',
      'transport': 'Транспорт',
      'shopping': 'Шопинг',
      'salary': 'Зарплата',
      'customCategory': 'Пользовательская категория',
      'inputCategory': 'Введите категорию',
      'subscriptionName': 'Имя подписки',
      'inputAmount': 'Введите сумму',
      'familyTransaction': 'Семейная транзакция',
      'transactionReport': 'Отчет о транзакциях',
      'verificationSent': 'Письмо с подтверждением отправлено',
      'emailNotVerified': 'Email не подтвержден',
      'resetEmailSent': 'Письмо для сброса пароля отправлено',
      'resetFailed': 'Сброс не удался',
      'enterEmailToReset': 'Введите ваш email для сброса пароля',
      'forgotPassword': 'Забыли пароль?',
      'googleSignIn': 'Войти с помощью Google',
      'dontHaveAccount': 'Нет аккаунта?',
      'from': 'От',
      'recurring': 'Повторяющийся платеж',
      'recurrence': 'Периодичность',
      'add': 'Добавить',
      'health': 'Здоровье',
      'utilities': 'Коммуналка',
      'groceries': 'Продукты',
      'entertainment': 'Развлечения',
      'transfer': 'Перевод',
      'cash': 'Наличные',
      'topup': 'Пополнение',
      'pinTitle': 'Введите PIN или используйте отпечаток',
      'pinLabel': 'PIN-код',
      'pinUnlock': 'Разблокировать',
      'pinError': 'Неверный PIN',
      'forgotPin': 'Забыли PIN?',
      'resetEmailSentPin': 'Письмо для сброса отправлено на ваш email',
      'resetEmailError': 'Не удалось отправить письмо для сброса PIN',
      'confirmDisablePin': 'Вы точно хотите отключить PIN-код?',
      'pinDisabled': 'PIN отключён',

    },
    'kk': {
      'importing': 'Импорттау...',
      "import": "Импорт",
      "export": "Экспорт",
      "importError": "Импорттау қатесі",
      "exportError": "Экспорттау қатесі",
      "importConfirm": "Сіз осы файлды импорттағыңыз келетініне сенімдісіз бе? Табылған транзакциялар:",
      "importSuccess": "Импорттау сәтті! Импортталған транзакциялар:",
      "imported": "Импортталған",
      "error": "Қате",
      "ok": "ОК",
      "select": "Таңдау",
      "cancel": "Бас тарту",
      "selectAll": "Барлығын таңдау",
      "unselectAll": "Барлығын алып тастау",
      'menu': 'Мәзір',
      'noData': 'Деректер жоқ',
      'expenseByCategory': 'Категория бойынша шығындар',
      'monthlyExpenses': 'Айлық шығындар',
      'January': 'Қаң',
      'February': 'Ақп',
      'March': 'Нау',
      'April': 'Сәу',
      'May': 'Мам',
      'June': 'Маус',
      'July': 'Шіл',
      'August': 'Там',
      'September': 'Қыр',
      'October': 'Қаз',
      'November': 'Қар',
      'December': 'Жел',
      'deleteMember': 'Мүшені жою',
      'confirmDeleteMember': 'Сіз осы мүшені жойғыңыз келетініне сенімдісіз бе?',
      'createFamily': 'Отбасы құру',
      'inviteCode': 'Шақыру коды',
      'familyMembers': 'Отбасы мүшелері',
      'leaveFamily': 'Отбасынан шығу',
      'confirmLeaveFamily': 'Сіз осы отбасынан шығуға сенімдісіз бе?',
      'confirmLeaveFamilyMessage': 'Сіз отбасы мүшелерін және олардың транзакцияларын көре алмайсыз.',
      'leave': 'Шығу',
      'join': 'Қосылу',
      'alreadyInFamily': 'Отбасыда бар',
      'invalidInviteCode': 'Жарамсыз шақыру коды',
      'user': 'Пайдаланушы',
      'uncategorized': 'Санатталмаған',
      'lastTransactions': 'Соңғы транзакциялар',
      'balance': 'Теңгерім',
      'settings': 'Параметрлер',
      'language': 'Тіл',
      'currency': 'Валюта',
      'theme': 'Тақырып',
      'dark_theme': 'Қараңғы тақырып',
      'notifications': 'Хабарламалар',
      'select_currency': 'Валютаны таңдаңыз',
      'select_language': 'Тілді таңдаңыз',
      'save': 'Сақтау',
      'login': 'Кіру',
      'logout': 'Шығу',
      'profile': 'Профиль',
      'email': 'Email',
      'password': 'Құпиясөз',
      'sign_in': 'Кіру',
      'sign_up': 'Тіркелу',
      'home': 'Басты бет',
      'transactions': 'Транзакциялар',
      'budgets': 'Бюджеттер',
      'statistics': 'Статистика',
      'add_transaction': 'Транзакция қосу',
      'continue': 'Жалғастыру',
      'welcome': 'Қош келдіңіз',
      'choose_language': 'Тілді таңдаңыз',
      'name': 'Аты',
      'family': 'Отбасы',
      'noFamily': 'Отбасыда жоқ',
      'familyId': 'Отбасы ID',
      'joinFamily': 'Отбасыға қосылу',
      'avatarUpdated': 'Аватар сәтті жаңартылды',
      'avatarUpdateError': 'Аватарды жаңартылмады',
      'profileUpdated': 'Профиль сәтті жаңартылды',
      'transactionHistory': 'Транзакция тарихы',
      'budgetGoals': 'Бюджет мақсаттары',
      "transactionDetails": "Транзакцияның егжей-тегжейлері",
      "type": "Түрі",
      "expense": "Шығын",
      "income": "Табыс",
      "category": "Категория",
      "subscription": "Жазылым",
      "amount": "Сома",
      "date": "Күні",
      "description": "Сипаттама",
      "close": "Жабу",
      "sortByAmount": "Сомасы бойынша сұрыптау",
      "ascending": "Өсу ретімен",
      "descending": "Кему ретімен",
      "deleteTransaction": "Транзакцияны жою",
      "confirmDeleteTransaction": "Сіз осы транзакцияны жойғыңыз келетініне сенімдісіз бе?",
      "delete": "Жою",
      "byDate": "Күні бойынша",
      "byAmount": "Сома бойынша",
      "exportPdf": "PDF-ке экспорттау",
      "exportCsv": "CSV-ке экспорттау",
      "noTransactions": "Транзакциялар табылмады",
      "darkMode": "Қараңғы режим",
      "signUpError": "Тіркелу қатесі",
      "notLoggedIn": "Сіз жүйеге кірмегенсіз",
      "noNotifications": "Хабарламалар жоқ",
      "empty": "Деректер жоқ",
      'loginError': 'Кіру қатесі',
      'userNotFound': 'Пайдаланушы табылмады',
      'wrongPassword': 'Құпиясөз қате',
      'searchByTransaction': 'Транзакция бойынша іздеу',
      'other': 'Басқа',
      'budgetLimitExceeded': 'Бюджет лимиті асырылды',
      'budgetLimitExceededMessage': 'Сіз осы категория үшін бюджет лимитін асырдыңыз:',
      'changeLimit': 'Лимитті өзгерту',
      'noBudgets': 'Бюджеттер жоқ',
      'spended': 'Шығындалған',
      'newGoal': 'Жаңа мақсат',
      'goalName': 'Мақсат атауы',
      'selectDate': 'Күнді таңдаңыз',
      'selectedDate': 'Таңдалған күн',
      'notInFamily': 'Отбасында жоқ',
      'fillAllFields': 'Барлық өрістерді толтырыңыз',
      'create': 'Жасау',
      'noGoals': 'Мақсаттар жоқ',
      'before': 'Алдында',
      'accumulated': 'Жинақталған',
      'food': 'Азық-түлік',
      'transport': 'Транспорт',
      'shopping': 'Сатып алу',
      'salary': 'Жалақы',
      'customCategory': 'Пайдаланушы категориясы',
      'inputCategory': 'Категорияны енгізіңіз',
      'subscriptionName': 'Жазылым атауы',
      'inputAmount': 'Соманы енгізіңіз',
      'familyTransaction': 'Отбасылық транзакция',
      'transactionReport': 'Транзакция есебі',
      'verificationSent': 'Тексеру электрондық поштасы жіберілді',
      'emailNotVerified': 'Электрондық пошта расталмаған',
      'resetEmailSent': 'Қалпына келтіру электрондық поштасы жіберілді',
      'resetFailed': 'Қалпына келтіру сәтсіз аяқталды',
      'enterEmailToReset': 'Құпиясөзді қалпына келтіру үшін электрондық поштаңызды енгізіңіз',
      'forgotPassword': 'Құпиясөзді ұмыттыңыз ба?',
      'googleSignIn': 'Google арқылы кіру',
      'dontHaveAccount': 'Есептік жазбаңыз жоқ па?',
      'from': 'Кімнен',
      'recurring': 'Тұрақты төлем',
      'recurrence': 'Периодичность',
      'add': 'Қосу',
      'health': 'Денсаулық',
      'utilities': 'Коммуналдық',
      'groceries': 'Азық-түлік',
      'entertainment': 'Ойын-сауық',
      'transfer': 'Аударым',
      'cash': 'Қолма-қол',
      'topup': 'Толықтыру',
      'all': 'Барлығы',
      'recent': 'Соңғы',
      'pinTitle': 'PIN код немесе саусақ ізі',
      'pinLabel': 'PIN код',
      'pinUnlock': 'Бұғаттан босату',
      'pinError': 'Қате PIN',
      'forgotPin': 'PIN кодты ұмыттыңыз ба?',
      'resetEmailSentPin': 'Қалпына келтіру хаты поштаға жіберілді',
      'resetEmailError': 'Қалпына келтіру хатын жіберу мүмкін емес',
      'confirmDisablePin': 'PIN кодты өшіргіңіз келетініне сенімдісіз бе?',
      'pinDisabled': 'PIN өшірілді',

    },
  };

  String _tr(String key) {
    return _localizedStrings[locale.languageCode]?[key] ??
        _localizedStrings['en']![key] ??
        key;
  }

  String get confirmDisablePin => _tr('confirmDisablePin');
  String get pinDisabled => _tr('pinDisabled');
  String get forgotPin => _tr('forgotPin');
  String get resetEmailSentPin => _tr('resetEmailSentPin');
  String get resetEmailError => _tr('resetEmailError');
  String get pinTitle => _tr('pinTitle');
  String get pinLabel => _tr('pinLabel');
  String get pinUnlock => _tr('pinUnlock');
  String get pinError => _tr('pinError');
  String get importing => _tr('importing');
  String get all => _tr('all');
  String get recent => _tr('recent');
  String get import => _tr('import');
  String get export => _tr('export');
  String get importError => _tr('importError');
  String get exportError => _tr('exportError');
  String get importConfirm => _tr('importConfirm');
  String get importSuccess => _tr('importSuccess');
  String get imported => _tr('imported');
  String get error => _tr('error');
  String get ok => _tr('ok');
  String get add => _tr('add');
  String get recurring => _tr('recurring');
  String get recurrence => _tr('recurrence');
  String get from => _tr('from');
  String get verificationSent => _tr('verificationSent');
  String get emailNotVerified => _tr('emailNotVerified');
  String get resetEmailSent => _tr('resetEmailSent');
  String get resetFailed => _tr('resetFailed');
  String get enterEmailToReset => _tr('enterEmailToReset');
  String get forgotPassword => _tr('forgotPassword');
  String get googleSignIn => _tr('googleSignIn');
  String get dontHaveAccount => _tr('dontHaveAccount');
  String get transactionReport => _tr('transactionReport');
  String get select => _tr('select');
  String get selectAll => _tr('selectAll');
  String get unselectAll => _tr('unselectAll');
  String get menu => _tr('menu');
  String get noData => _tr('noData');
  String get expenseByCategory => _tr('expenseByCategory');
  String get monthlyExpenses => _tr('monthlyExpenses');
  String get January => _tr('January');
  String get February => _tr('February');
  String get March => _tr('March');
  String get April => _tr('April');
  String get May => _tr('May');
  String get June => _tr('June');
  String get July => _tr('July');
  String get August => _tr('August');
  String get September => _tr('September');
  String get October => _tr('October');
  String get November => _tr('November');
  String get December => _tr('December');
  String get subscriptionName => _tr('subscriptionName');
  String get inputAmount => _tr('inputAmount');
  String get familyTransaction => _tr('familyTransaction');
  String get inputCategory => _tr('inputCategory');
  String get food => _tr('food');
  String get transport => _tr('transport');
  String get shopping => _tr('shopping');
  String get salary => _tr('salary');
  String get customCategory => _tr('customCategory');
  String get newGoal => _tr('newGoal');
  String get goalName => _tr('goalName');
  String get selectDate => _tr('selectDate');
  String get selectedDate => _tr('selectedDate');
  String get notInFamily => _tr('notInFamily');
  String get fillAllFields => _tr('fillAllFields');
  String get create => _tr('create');
  String get noGoals => _tr('noGoals');
  String get before => _tr('before');
  String get accumulated => _tr('accumulated');
  String get changeLimit => _tr('changeLimit');
  String get noBudgets => _tr('noBudgets');
  String get spended => _tr('spended');
  String get budgetLimitExceeded => _tr('budgetLimitExceeded');
  String get budgetLimitExceededMessage => _tr('bugetLimitExceededMessage');
  String get other => _tr('other');
  String get deleteMember => _tr('deleteMember');
  String get confirmDeleteMember => _tr('confirmDeleteMember');
  String get createFamily => _tr('createFamily');
  String get inviteCode => _tr('inviteCode');
  String get familyMembers => _tr('familyMembers');
  String get leaveFamily => _tr('leaveFamily');
  String get confirmLeaveFamily => _tr('confirmLeaveFamily');
  String get confirmLeaveFamilyMessage => _tr('confirmLeaveFamilyMessage');
  String get leave => _tr('leave');
  String get join => _tr('join');
  String get alreadyInFamily => _tr('alreadyInFamily');
  String get invalidInviteCode => _tr('invalidInviteCode');
  String get user => _tr('user');
  String get uncategorized => _tr('uncategorized');
  String get lastTransactions => _tr('lastTransactions');
  String get balance => _tr('balance');
  String get settings => _tr('settings');
  String get language => _tr('language');
  String get currency => _tr('currency');
  String get theme => _tr('theme');
  String get darkTheme => _tr('dark_theme');
  String get notifications => _tr('notifications');
  String get selectCurrency => _tr('select_currency');
  String get selectLanguage => _tr('select_language');
  String get cancel => _tr('cancel');
  String get save => _tr('save');
  String get login => _tr('login');
  String get logout => _tr('logout');
  String get profile => _tr('profile');
  String get email => _tr('email');
  String get password => _tr('password');
  String get signIn => _tr('sign_in');
  String get signUp => _tr('sign_up');
  String get home => _tr('home');
  String get transactions => _tr('transactions');
  String get budgets => _tr('budgets');
  String get statistics => _tr('statistics');
  String get addTransaction => _tr('add_transaction');
  String get continueLabel => _tr('continue');
  String get welcome => _tr('welcome');
  String get chooseLanguage => _tr('choose_language');
  String get name => _tr('name');
  String get family => _tr('family');
  String get noFamily => _tr('noFamily');
  String get familyId => _tr('familyId');
  String get joinFamily => _tr('joinFamily');
  String get avatarUpdated => _tr('avatarUpdated');
  String get avatarUpdateError => _tr('avatarUpdateError');
  String get profileUpdated => _tr('profileUpdated');
  String get transactionHistory => _tr('transactionHistory');
  String get budgetGoals => _tr('budgetGoals');
  String get transactionDetails => _tr('transactionDetails');
  String get type => _tr('type');
  String get expense => _tr('expense');
  String get income => _tr('income');
  String get category => _tr('category');
  String get subscription => _tr('subscription');
  String get amount => _tr('amount');
  String get date => _tr('date');
  String get description => _tr('description');
  String get close => _tr('close');
  String get sortByAmount => _tr('sortByAmount');
  String get ascending => _tr('ascending');
  String get descending => _tr('descending');
  String get deleteTransaction => _tr('deleteTransaction');
  String get confirmDeleteTransaction => _tr('confirmDeleteTransaction');
  String get delete => _tr('delete');
  String get byDate => _tr('byDate');
  String get byAmount => _tr('byAmount');
  String get exportPdf => _tr('exportPdf');
  String get exportCsv => _tr('exportCsv');
  String get noTransactions => _tr('noTransactions');
  String get darkMode => _tr('darkMode');
  String get signUpError => _tr('signUpError');
  String get notLoggedIn => _tr('notLoggedIn');
  String get noNotifications => _tr('noNotifications');
  String get empty => _tr('empty');
  String get loginError => _tr('loginError');
  String get userNotFound => _tr('userNotFound');
  String get wrongPassword => _tr('wrongPassword');
  String get searchByTransaction => _tr('searchByTransaction');
  String get health => _tr('health');
  String get utilities => _tr('utilities');
  String get groceries => _tr('groceries');
  String get entertainment => _tr('entertainment');
  String get transfer => _tr('transfer');
  String get cash => _tr('cash');
  String get topup => _tr('topup');

}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ru', 'kk'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}