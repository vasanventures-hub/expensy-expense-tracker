import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppState.instance.initialize();

  runApp(const PersonalExpenseTracker());
}

// ============================================================
// APP
// ============================================================

class PersonalExpenseTracker extends StatelessWidget {
  const PersonalExpenseTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Personal Expense Tracker',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF6F8FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976F3),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

// ============================================================
// MODELS
// ============================================================

class Expense {
  String title;
  double amount;
  String category;
  DateTime date;
  String note;
  String account;

  Expense({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
    this.account = 'Wallet',
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
      'account': account,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      title: json['title'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? 'Others',
      date: DateTime.tryParse(
            json['date'] ?? '',
          ) ??
          DateTime.now(),
      note: json['note'] ?? '',
      account: json['account']?.toString() ?? 'Wallet',
    );
  }
}
class ExpenseCategory {
  String name;
  IconData icon;
  Color color;

  ExpenseCategory({
    required this.name,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color.toARGB32(),
      'icon': icon.codePoint,
    };
  }

  factory ExpenseCategory.fromJson(
  Map<String, dynamic> json,
) {
  final iconCode = (json['icon'] as num?)?.toInt();

  final IconData icon;

  switch (iconCode) {
    case 58727:
      icon = Icons.restaurant_rounded;
      break;
    case 57882:
      icon = Icons.shopping_bag_rounded;
      break;
    case 58913:
      icon = Icons.directions_car_rounded;
      break;
    case 58729:
      icon = Icons.movie_rounded;
      break;
    case 58130:
      icon = Icons.receipt_long_rounded;
      break;
    case 59504:
      icon = Icons.medical_services_rounded;
      break;
    case 58183:
      icon = Icons.school_rounded;
      break;
    case 59519:
      icon = Icons.home_rounded;
      break;
    case 58325:
      icon = Icons.flight_rounded;
      break;
    default:
      icon = Icons.label_rounded;
  }

  final colorValue = (json['color'] as num?)?.toInt();

  return ExpenseCategory(
    name: json['name']?.toString() ?? 'Others',
    icon: icon,
    color: Color(
      colorValue ?? Colors.grey.toARGB32(),
    ),
  );
}
}

class MonthlyData {
  double budget;
  List<Expense> expenses;

  MonthlyData({
    required this.budget,
    required this.expenses,
  });
}
// ============================================================
// GLOBAL APP STATE
// ============================================================

class AppState {
  static final AppState instance = AppState._();

  AppState._();
  final StorageService storage = StorageService();

  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final ValueNotifier<String> selectedAccountNotifier =
      ValueNotifier<String>('Account');

  String get selectedAccount => selectedAccountNotifier.value;

  set selectedAccount(String value) {
    if (value == 'Wallet' || value == 'Account') {
      selectedAccountNotifier.value = value;
    }
  }

  final Map<String, Map<String, double>> accountBudgets = {};

  final Map<String, MonthlyData> months = {
    'September 2026': MonthlyData(
      budget: 50000,
      expenses: [
        Expense(
          title: 'House Rent',
          amount: 9000,
          category: 'House Rent',
          date: DateTime(2026, 9, 6),
          account: 'Account',
        ),
        Expense(
          title: 'Groceries',
          amount: 8952,
          category: 'Groceries',
          date: DateTime(2026, 9, 7),
          account: 'Account',
        ),
        Expense(
          title: 'Pocket Money',
          amount: 3000,
          category: 'Personal',
          date: DateTime(2026, 9, 7),
          account: 'Account',
        ),
        Expense(
          title: 'Anniversary Gift',
          amount: 4400,
          category: 'Gifts',
          date: DateTime(2026, 9, 9),
          account: 'Account',
        ),
        Expense(
          title: 'Dairy Products & Snacks',
          amount: 1186,
          category: 'Food & Drinks',
          date: DateTime(2026, 9, 7),
          account: 'Account',
        ),
        Expense(
          title: 'Print Out',
          amount: 730,
          category: 'Education',
          date: DateTime(2026, 9, 6),
          account: 'Account',
        ),
        Expense(
          title: 'Binding Record',
          amount: 300,
          category: 'Education',
          date: DateTime(2026, 9, 6),
          account: 'Account',
        ),
      ],
    ),
    'August 2026': MonthlyData(
      budget: 45000,
      expenses: [
        Expense(
          title: 'House Rent',
          amount: 9000,
          category: 'House Rent',
          date: DateTime(2026, 8, 5),
          account: 'Account',
        ),
        Expense(
          title: 'Groceries',
          amount: 7200,
          category: 'Groceries',
          date: DateTime(2026, 8, 8),
          account: 'Account',
        ),
        Expense(
          title: 'Transport',
          amount: 1800,
          category: 'Transport',
          date: DateTime(2026, 8, 12),
          account: 'Account',
        ),
      ],
    ),
  };

  List<ExpenseCategory> categories = [
    ExpenseCategory(
      name: 'House Rent',
      icon: Icons.home_rounded,
      color: const Color(0xFF1976F3),
    ),
    ExpenseCategory(
      name: 'Groceries',
      icon: Icons.shopping_cart_rounded,
      color: const Color(0xFF35A66F),
    ),
    ExpenseCategory(
      name: 'Food & Drinks',
      icon: Icons.restaurant_rounded,
      color: const Color(0xFFF2994A),
    ),
    ExpenseCategory(
      name: 'Transport',
      icon: Icons.directions_car_rounded,
      color: const Color(0xFF26A9C9),
    ),
    ExpenseCategory(
      name: 'Education',
      icon: Icons.school_rounded,
      color: const Color(0xFFE5A900),
    ),
    ExpenseCategory(
      name: 'Gifts',
      icon: Icons.card_giftcard_rounded,
      color: const Color(0xFF8D5CE6),
    ),
    ExpenseCategory(
      name: 'Health',
      icon: Icons.favorite_rounded,
      color: const Color(0xFFE85D75),
    ),
    ExpenseCategory(
      name: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      color: const Color(0xFFE88922),
    ),
    ExpenseCategory(
      name: 'Bills',
      icon: Icons.receipt_long_rounded,
      color: const Color(0xFF437BE8),
    ),
    ExpenseCategory(
      name: 'Entertainment',
      icon: Icons.movie_rounded,
      color: const Color(0xFFD6419D),
    ),
    ExpenseCategory(
      name: 'Personal',
      icon: Icons.person_rounded,
      color: const Color(0xFF12A59A),
    ),
    ExpenseCategory(
      name: 'Others',
      icon: Icons.more_horiz_rounded,
      color: const Color(0xFF6F7B8D),
    ),
  ];

  MonthlyData get currentMonthData {
    return months[selectedMonthName] ??=
        MonthlyData(budget: 50000, expenses: []);
  }

  String get selectedMonthName {
    return monthName(selectedMonth);
  }
  List<Expense> get activeExpenses {
  return currentMonthData.expenses
      .where((expense) => expense.account == selectedAccount)
      .toList();
  }
  double get totalSpent {
    return currentMonthData.expenses
      .where((expense) => expense.account == selectedAccount)
      .fold(
        0,
        (sum, expense) => sum + expense.amount,
      );
  }
  double get currentBudget {
    return budgetForAccount(selectedAccount);
  }

  double budgetForAccount(String account) {
    final budgets = accountBudgets[selectedMonthName];
    return budgets?[account] ?? currentMonthData.budget;
  }

  Future<void> setCurrentBudget(double value) async {
    await setBudgetForAccount(selectedAccount, value);
  }

  Future<void> setBudgetForAccount(
    String account,
    double value,
  ) async {
    accountBudgets.putIfAbsent(
      selectedMonthName,
      () => {
        'Wallet': currentMonthData.budget,
        'Account': currentMonthData.budget,
      },
    );

    accountBudgets[selectedMonthName]![account] = value;

    // Keep the legacy month budget synchronized with the Account budget
    // for compatibility with existing stored month data.
    if (account == 'Account') {
      currentMonthData.budget = value;
    }

    await _saveAccountBudgets();
    await storage.saveMonths(months);
  }

  Future<void> _loadAccountBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('account_budgets_v1');

    accountBudgets.clear();

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            if (entry.value is Map) {
              final map = <String, double>{};
              for (final budgetEntry in (entry.value as Map).entries) {
                final value = budgetEntry.value;
                if (value is num) {
                  map[budgetEntry.key.toString()] = value.toDouble();
                }
              }
              if (map.isNotEmpty) {
                accountBudgets[entry.key.toString()] = map;
              }
            }
          }
        }
      } catch (_) {
        accountBudgets.clear();
      }
    }

    for (final entry in months.entries) {
      accountBudgets.putIfAbsent(
        entry.key,
        () => {
          'Account': entry.value.budget,
          'Wallet': entry.value.budget,
        },
      );
      accountBudgets[entry.key]!.putIfAbsent(
        'Account',
        () => entry.value.budget,
      );
      accountBudgets[entry.key]!.putIfAbsent(
        'Wallet',
        () => entry.value.budget,
      );
    }
  }

  Future<void> _saveAccountBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'account_budgets_v1',
      jsonEncode(accountBudgets),
    );
  }

  double get walletSpent {
    return currentMonthData.expenses
      .where((expense) => expense.account == 'Wallet')
      .fold(
        0,
        (sum, expense) => sum + expense.amount,
      );
  }
  double get accountSpent {
    return currentMonthData.expenses
      .where((expense) => expense.account == 'Account')
      .fold(
        0,
        (sum, expense) => sum + expense.amount,
      );
  }

  double get balance {
    return currentBudget - totalSpent;
  }

  double get spendingPercentage {
    if (currentBudget == 0) return 0;
    return (totalSpent / currentBudget).clamp(0, 1);
  }

  Future<void> addExpense(
  Expense expense,
) async {
  currentMonthData.expenses.insert(
    0,
    expense,
  );

  await storage.saveMonths(months);
}

  Future<void> deleteExpense(
  Expense expense,
) async {
  currentMonthData.expenses.remove(
    expense,
  );

  await storage.saveMonths(months);
}

  Future<void> updateExpense(
  Expense oldExpense,
  Expense newExpense,
) async {
  final index =
      currentMonthData.expenses.indexOf(oldExpense);

  if (index != -1) {
    currentMonthData.expenses[index] =
        newExpense;

    await storage.saveMonths(months);
  }
}

  Future<void> addCategory(
  String name,
) async {
  if (name.trim().isEmpty) return;

  categories.add(
    ExpenseCategory(
      name: name.trim(),
      icon: Icons.label_rounded,
      color: Colors.primaries[
          categories.length %
              Colors.primaries.length
      ],
    ),
  );

  await storage.saveCategories(
    categories,
  );
}

  Future<void> _migrateWalletDataToAccount() async {
  final prefs = await SharedPreferences.getInstance();
  const migrationKey = 'wallet_to_account_migration_v1';

  if (prefs.getBool(migrationKey) == true) {
    selectedAccountNotifier.value = 'Account';
    return;
  }

  var changed = false;

  // Move all existing Wallet expenses to Account once.
  // Wallet remains available for new expenses after this migration.
  for (final month in months.values) {
    for (final expense in month.expenses) {
      if (expense.account == 'Wallet') {
        expense.account = 'Account';
        changed = true;
      }
    }
  }

  if (changed) {
    await storage.saveMonths(months);
  }

  selectedAccountNotifier.value = 'Account';
  await prefs.setBool(migrationKey, true);
}

  Future<void> initialize() async {
  await storage.init();

  final savedCategories =
      storage.loadCategories();

  if (savedCategories != null) {
    categories = savedCategories;
  }

  final savedMonths =
      storage.loadMonths();

  if (savedMonths != null) {
    months
      ..clear()
      ..addAll(savedMonths);
  }

  final savedMonth =
      storage.loadSelectedMonth();

  if (savedMonth != null) {
    selectedMonth = savedMonth;
  }

  await _loadAccountBudgets();
  await _migrateWalletDataToAccount();
  await _saveAccountBudgets();

  selectedAccountNotifier.value = 'Account';
}

  static String monthName(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }
}
// ============================================================
// MAIN NAVIGATION
// ============================================================

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  void goToExpenses() {
    setState(() {
      currentIndex = 1;
    });
  }

  final GlobalKey<_HomePageState> homeKey =
      GlobalKey<_HomePageState>();

  final GlobalKey<_ExpensesPageState> expensesKey =
      GlobalKey<_ExpensesPageState>();

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(key: homeKey),
      ExpensesPage(key: expensesKey),
      const SettingsPage(),
    ];

    return ValueListenableBuilder<String>(
      valueListenable: AppState.instance.selectedAccountNotifier,
      builder: (context, _, _) {
        return Scaffold(
          body: SafeArea(
            child: IndexedStack(
              index: currentIndex,
              children: pages,
            ),
          ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: Colors.white,
        elevation: 8,
        height: 72,
        indicatorColor: const Color(0xFFE5F0FF),
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: currentIndex == 1
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF1976F3),
              foregroundColor: Colors.white,
              elevation: 4,
              onPressed: () {
                showAddExpense(context);
              },
              child: const Icon(Icons.add_rounded),
            )
          : null,
        );
      },
    );
  }

  void showAddExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExpenseSheet(
        onSaved: () {
          setState(() {});
          homeKey.currentState?.refresh();
          expensesKey.currentState?.refresh();
        },
      ),
    );
  }
}

// ============================================================
// HOME PAGE
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        children: [
          _buildHeader(context),
          const SizedBox(height: 18),

          _AccountSelector(
            selectedAccount: app.selectedAccount,
            onChanged: (account) {
              setState(() {
                app.selectedAccount = account;
              });
            },
          ),
          const SizedBox(height: 12),

          // BALANCE CARD
          _BalanceCard(
            balance: app.balance,
            budget: app.currentBudget,
            spent: app.totalSpent,
            percentage: app.spendingPercentage,
          ),

          const SizedBox(height: 12),

          // QUICK STATS
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF8758E8),
                  title: 'Budget',
                  value: currency(app.currentBudget),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.trending_down_rounded,
                  iconColor: const Color(0xFFE85A67),
                  title: 'Spent',
                  value: currency(app.totalSpent),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.today_rounded,
                  iconColor: const Color(0xFF20A46B),
                  title: 'Today',
                  value: currency(_todaySpending()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.insights_rounded,
                  iconColor: const Color(0xFF239FB7),
                  title: 'Daily Average',
                  value: currency(_dailyAverage()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ADD EXPENSE
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AddExpenseSheet(
                    onSaved: () {
                      setState(() {});
                    },
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Expense',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1976F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // CATEGORY CHART
          _SectionCard(
            title: 'Expenses by Category',
            trailing: 'View All',
            onTrailingTap: () {
              context
                  .findAncestorStateOfType<_MainNavigationState>()
                  ?.goToExpenses();
            },
            child: Column(
              children: [
                const SizedBox(height: 4),
                SizedBox(
                  height: 210,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: CustomPaint(
                          painter: DonutChartPainter(
                            values: _categoryValues(),
                            colors: _categoryColors(),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  currency(app.totalSpent),
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    color: Color(0xFF7C8798),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: _buildCategoryLegend(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // RECENT EXPENSES
          _SectionCard(
            title: 'Recent Expenses',
            trailing: 'View All',
            onTrailingTap: () {
              context
                  .findAncestorStateOfType<_MainNavigationState>()
                  ?.goToExpenses();
            },
            child: Column(
              children: [
                ...app.activeExpenses.take(5).map(
                      (expense) => _ExpenseTile(
                        expense: expense,
                        onTap: () {
                          showExpenseDetails(
                            context,
                            expense,
                            onChanged: () {
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final app = AppState.instance;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              showMonthSelector(context);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EXPENSY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8A94A5),
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      app.selectedMonthName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _CircleButton(
          icon: Icons.calendar_month_rounded,
          onTap: () {
            showMonthSelector(context);
          },
        ),
      ],
    );
  }

  double _todaySpending() {
    // Use the real device/system date for "Today".
    final now = DateTime.now();
    final appMonth = AppState.instance.selectedMonth;

    // "Today" only applies when the currently selected app month
    // is the same month as the device/system date.
    if (appMonth.year != now.year || appMonth.month != now.month) {
      return 0;
    }

    return AppState.instance.activeExpenses
        .where(
          (e) =>
              e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day,
        )
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double _dailyAverage() {
    final app = AppState.instance;
    final expenses = app.activeExpenses;

    if (expenses.isEmpty) return 0;

    final now = DateTime.now();
    final selectedMonth = app.selectedMonth;

    final isCurrentMonth =
        selectedMonth.year == now.year &&
        selectedMonth.month == now.month;

    final isFutureMonth =
        selectedMonth.year > now.year ||
        (selectedMonth.year == now.year &&
            selectedMonth.month > now.month);

    if (isFutureMonth) return 0;

    final daysElapsed = isCurrentMonth
        ? now.day
        : DateTime(
            selectedMonth.year,
            selectedMonth.month + 1,
            0,
          ).day;

    return daysElapsed > 0 ? app.totalSpent / daysElapsed : 0;
  }

  List<double> _categoryValues() {
    final app = AppState.instance;

    return app.categories
        .map(
          (category) => app.activeExpenses
              .where((e) => e.category == category.name)
              .fold(0.0, (sum, e) => sum + e.amount),
        )
        .where((value) => value > 0)
        .toList();
  }

  List<Color> _categoryColors() {
    final app = AppState.instance;

    return app.categories
        .where(
          (category) => app.activeExpenses
              .any((e) => e.category == category.name),
        )
        .map((category) => category.color)
        .toList();
  }

  Widget _buildCategoryLegend() {
    final app = AppState.instance;

    final activeCategories = app.categories.where(
      (category) => app.activeExpenses.any(
        (e) => e.category == category.name,
      ),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: activeCategories.take(5).map(
        (category) {
          final amount = app.activeExpenses
              .where((e) => e.category == category.name)
              .fold(0.0, (sum, e) => sum + e.amount);

          final percent = app.totalSpent == 0
              ? 0
              : amount / app.totalSpent * 100;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: category.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    category.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7D8798),
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(),
    );
  }
}

// ============================================================
// BALANCE CARD
// ============================================================

class _BalanceCard extends StatelessWidget {
  final double balance;
  final double budget;
  final double spent;
  final double percentage;

  const _BalanceCard({
    required this.balance,
    required this.budget,
    required this.spent,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1976F3),
            Color(0xFF3188F5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976F3).withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'AVAILABLE BALANCE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha:.8),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currency(balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  'of ${currency(budget)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 7,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(
                Color(0xFFFF806D),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                '${(percentage * 100).toStringAsFixed(0)}% used',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                '${currency(spent)} spent',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MINI STAT
// ============================================================

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _MiniStatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE9EDF4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha:.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF8993A4),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION CARD
// ============================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE8ECF2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (trailing != null)
                GestureDetector(
                  onTap: onTrailingTap,
                  child: Text(
                    trailing!,
                    style: const TextStyle(
                      color: Color(0xFF1976F3),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ============================================================
// EXPENSES PAGE
// ============================================================

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final TextEditingController searchController =
      TextEditingController();

  String selectedCategory = 'All';
  bool newestFirst = true;

  void refresh() {
    if (mounted) setState(() {});
  }

  List<Expense> get filteredExpenses {
    final expenses =
        List<Expense>.from(AppState.instance.activeExpenses);

    final query = searchController.text.trim().toLowerCase();

    final filtered = expenses.where((expense) {
      final matchesSearch =
          query.isEmpty ||
          expense.title.toLowerCase().contains(query) ||
          expense.category.toLowerCase().contains(query) ||
          expense.note.toLowerCase().contains(query);

      final matchesCategory =
          selectedCategory == 'All' ||
          expense.category == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    filtered.sort(
      (a, b) => newestFirst
          ? b.date.compareTo(a.date)
          : a.date.compareTo(b.date),
    );

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;

    return Column(
      children: [
        _AccountSelector(
          selectedAccount: AppState.instance.selectedAccount,
          onChanged: (account) {
            setState(() {
              AppState.instance.selectedAccount = account;
            });
          },
        ),
const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 15, 18, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Expenses',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _CircleButton(
                icon: Icons.tune_rounded,
                onTap: () {
                  showFilterSheet();
                },
              ),
            ],
          ),
        ),

        // SEARCH
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 5,
          ),
          child: Container(
            height: 47,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: const Color(0xFFE2E7EF),
              ),
            ),
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Color(0xFF8490A3),
                ),
                hintText: 'Search expenses...',
                hintStyle: TextStyle(
                  color: Color(0xFF9BA5B4),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),

        // CATEGORY FILTERS
        SizedBox(
          height: 54,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(18, 9, 18, 8),
            children: [
              _FilterChip(
                title: 'All',
                selected: selectedCategory == 'All',
                onTap: () {
                  setState(() {
                    selectedCategory = 'All';
                  });
                },
              ),
              ...app.categories.map(
                (category) => _FilterChip(
                  title: category.name,
                  selected: selectedCategory == category.name,
                  onTap: () {
                    setState(() {
                      selectedCategory = category.name;
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 7),
          child: Row(
            children: [
              Text(
                app.selectedMonthName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                currency(filteredExpenses.fold(0.0, (s, e) => s + e.amount)),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7A8494),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: filteredExpenses.isEmpty
              ? _EmptyExpenses()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    0,
                    18,
                    90,
                  ),
                  itemCount: filteredExpenses.length,
                  itemBuilder: (_, index) {
                    final expense = filteredExpenses[index];

                    return _ExpenseTile(
                      expense: expense,
                      onTap: () {
                        showExpenseDetails(
                          context,
                          expense,
                          onChanged: () {
                            setState(() {});
                          },
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  void showFilterSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                5,
                20,
                30,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Expenses',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 22),

                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
  initialValue: 'All',
  decoration: inputDecoration('Select category'),
  items: [
    const DropdownMenuItem(
      value: 'All',
      child: Text('All Categories'),
    ),
    ...AppState.instance.categories.map(
      (category) => DropdownMenuItem(
        value: category.name,
        child: Text(category.name),
      ),
    ),
  ],
  onChanged: (value) {
    setSheetState(() {
      selectedCategory = value ?? 'All';
    });
    setState(() {});
  },
),

                  const SizedBox(height: 18),

                  const Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _ChoiceButton(
                          title: 'Date (Newest)',
                          selected: newestFirst,
                          onTap: () {
                            setSheetState(() {
                              newestFirst = true;
                            });
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ChoiceButton(
                          title: 'Date (Oldest)',
                          selected: !newestFirst,
                          onTap: () {
                            setSheetState(() {
                              newestFirst = false;
                            });
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// ADD EXPENSE SHEET
// ============================================================

class AddExpenseSheet extends StatefulWidget {
  final VoidCallback? onSaved;

  const AddExpenseSheet({
    super.key,
    this.onSaved,
  });

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  final noteController = TextEditingController();

  String? selectedCategory;
  String selectedAccount = AppState.instance.selectedAccount;
DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    if (AppState.instance.categories.isNotEmpty) {
      selectedCategory =
          AppState.instance.categories.first.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFD),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4DAE3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Add Expense',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),

            const SizedBox(height: 15),
            
            const _FieldLabel('Account'),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Account'),
                    selected: selectedAccount == 'Account',
                    onSelected: (_) {
                      setState(() {
                        selectedAccount = 'Account';
                      });
                    },
                    avatar: const Icon(
                      Icons.account_balance_rounded,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Wallet'),
                    selected: selectedAccount == 'Wallet',
                    onSelected: (_) {
                      setState(() {
                        selectedAccount = 'Wallet';
                      });
                    },
                    avatar: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 18,
        ),
      ),
    ),
  ],
),

const SizedBox(height: 15),

            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: inputDecoration(
                '₹ 0',
                prefixIcon: Icons.currency_rupee_rounded,
              ),
            ),

            const SizedBox(height: 15),

            const _FieldLabel('Description'),

            TextField(
              controller: descriptionController,
              decoration: inputDecoration(
                'What did you spend on?',
              ),
            ),

            const SizedBox(height: 15),

            const _FieldLabel('Category'),

            DropdownButtonFormField<String>(
  initialValue: selectedCategory,
  decoration: inputDecoration('Select category'),
  items: AppState.instance.categories
      .map(
        (category) => DropdownMenuItem(
          value: category.name,
          child: Row(
            children: [
              Icon(
                category.icon,
                size: 18,
                color: category.color,
              ),
              const SizedBox(width: 8),
              Text(category.name),
            ],
          ),
        ),
      )
      .toList(),
  onChanged: (value) {
    setState(() {
      selectedCategory = value;
    });
  },
),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showAddCategory();
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add New Category'),
              ),
            ),

            const SizedBox(height: 15),

            const _FieldLabel('Date'),

            GestureDetector(
              onTap: _pickDate,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: const Color(0xFFE0E6EF),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFF6C7789),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      dateText(selectedDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            const _FieldLabel('Personal Note'),

            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: inputDecoration(
                'Add a personal note...',
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 53,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1976F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Save Expense',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(DateTime.now().year - 10, 1, 1),
      lastDate: DateTime(DateTime.now().year + 10, 12, 31),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _showAddCategory() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            'Add Category',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: inputDecoration(
              'Category name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  await AppState.instance.addCategory(
                    controller.text.trim(),
                  );

                  if (!mounted) return;

                  setState(() {
                    selectedCategory =
                        controller.text.trim();
                  });

                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _save() async {
    final amount =
        double.tryParse(amountController.text.trim());

    if (amount == null || amount <= 0) {
      showSnack(context, 'Enter a valid amount');
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
      showSnack(context, 'Enter an expense description');
      return;
    }

    if (selectedCategory == null) {
      showSnack(context, 'Select a category');
      return;
    }

    await AppState.instance.addExpense(
      Expense(
        title: descriptionController.text.trim(),
        amount: amount,
        category: selectedCategory!,
        date: selectedDate,
        note: noteController.text.trim(),
        account: selectedAccount,
      ),
    );

    widget.onSaved?.call();

    if (!mounted) return;

    Navigator.pop(context);

    showSnack(context, 'Expense added successfully');
  }
}

// ============================================================
// EXPENSE TILE
// ============================================================

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;

  const _ExpenseTile({
    required this.expense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = AppState.instance.categories.firstWhere(
      (c) => c.name == expense.category,
      orElse: () => ExpenseCategory(
        name: expense.category,
        icon: Icons.label_rounded,
        color: const Color(0xFF6F7B8D),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE8ECF2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha:.11),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category.icon,
                color: category.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${dateText(expense.date)} • ${expense.category}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF8993A4),
                    ),
                  ),
                  if (expense.note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        expense.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9BA4B1),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '-${currency(expense.amount)}',
              style: const TextStyle(
                color: Color(0xFFE34C55),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9AA4B3),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// EXPENSE DETAILS
// ============================================================

void showExpenseDetails(
  BuildContext context,
  Expense expense, {
  VoidCallback? onChanged,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ExpenseDetailsSheet(
      expense: expense,
      onChanged: onChanged,
    ),
  );
}

class ExpenseDetailsSheet extends StatefulWidget {
  final Expense expense;
  final VoidCallback? onChanged;

  const ExpenseDetailsSheet({
    super.key,
    required this.expense,
    this.onChanged,
  });

  @override
  State<ExpenseDetailsSheet> createState() =>
      _ExpenseDetailsSheetState();
}

class _ExpenseDetailsSheetState
    extends State<ExpenseDetailsSheet> {
  @override
  Widget build(BuildContext context) {
    final expense = widget.expense;

    final category =
        AppState.instance.categories.firstWhere(
      (c) => c.name == expense.category,
      orElse: () => ExpenseCategory(
        name: expense.category,
        icon: Icons.label_rounded,
        color: const Color(0xFF6F7B8D),
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        25,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFD),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD3D9E2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 22),

            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ),

            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha:.11),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category.icon,
                size: 30,
                color: category.color,
              ),
            ),

            const SizedBox(height: 13),

            Text(
              expense.title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 5),

            Text(
              currency(expense.amount),
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: Color(0xFFE34C55),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              '${dateText(expense.date)} • 3:15 PM',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8993A4),
              ),
            ),

            const SizedBox(height: 20),

            _DetailRow(
              icon: Icons.label_outline_rounded,
              title: 'Category',
              value: expense.category,
            ),

            _DetailRow(
              icon: Icons.notes_rounded,
              title: 'Personal Note',
              value: expense.note.isEmpty
                  ? 'No note added'
                  : expense.note,
            ),

            _DetailRow(
              icon: Icons.calendar_today_rounded,
              title: 'Date',
              value: dateText(expense.date),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _edit,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1976F3),
                      minimumSize: const Size(0, 49),
                      side: const BorderSide(
                        color: Color(0xFF1976F3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE34C55),
                      minimumSize: const Size(0, 49),
                      side: const BorderSide(
                        color: Color(0xFFE34C55),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _edit() {
    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditExpenseSheet(
        expense: widget.expense,
        onSaved: widget.onChanged,
      ),
    );
  }

  void _delete() {
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Delete Expense?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'This expense will be removed from this month.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE34C55),
            ),
            onPressed: () async {
              await AppState.instance.deleteExpense(
                widget.expense,
              );

              if (!mounted) return;

              Navigator.pop(context);
              widget.onChanged?.call();

              showSnack(
                context,
                'Expense deleted',
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EDIT EXPENSE
// ============================================================

class EditExpenseSheet extends StatefulWidget {
  final Expense expense;
  final VoidCallback? onSaved;

  const EditExpenseSheet({
    super.key,
    required this.expense,
    this.onSaved,
  });

  @override
  State<EditExpenseSheet> createState() =>
      _EditExpenseSheetState();
}

class _EditExpenseSheetState
    extends State<EditExpenseSheet> {
  late TextEditingController amount;
  late TextEditingController title;
  late TextEditingController note;

  late String category;
  late DateTime date;

  @override
  void initState() {
    super.initState();

    amount = TextEditingController(
      text: widget.expense.amount.toStringAsFixed(0),
    );

    title = TextEditingController(
      text: widget.expense.title,
    );

    note = TextEditingController(
      text: widget.expense.note,
    );

    category = widget.expense.category;
    date = widget.expense.date;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFD),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Expense',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 20),

            const _FieldLabel('Amount'),

            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: inputDecoration('₹ 0'),
            ),

            const SizedBox(height: 14),

            const _FieldLabel('Description'),

            TextField(
              controller: title,
              decoration: inputDecoration('Description'),
            ),

            const SizedBox(height: 14),

            const _FieldLabel('Category'),

            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: inputDecoration('Category'),
              items: AppState.instance.categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.name,
                      child: Text(c.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  category = value ?? category;
                });
              },
            ),

            const SizedBox(height: 14),

            const _FieldLabel('Date'),

            ListTile(
              contentPadding: EdgeInsets.zero,
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              leading: const Icon(
                Icons.calendar_month_rounded,
              ),
              title: Text(dateText(date)),
              trailing: const Icon(
                Icons.chevron_right_rounded,
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(DateTime.now().year - 10, 1, 1),
                  lastDate: DateTime(DateTime.now().year + 10, 12, 31),
                );

                if (picked != null) {
                  setState(() {
                    date = picked;
                  });
                }
              },
            ),

            const SizedBox(height: 14),

            const _FieldLabel('Personal Note'),

            TextField(
              controller: note,
              maxLines: 3,
              decoration: inputDecoration(
                'Personal note',
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _save,
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final value = double.tryParse(amount.text);

    if (value == null || value <= 0) {
      showSnack(context, 'Enter a valid amount');
      return;
    }

    final updated = Expense(
      title: title.text.trim(),
      amount: value,
      category: category,
      date: date,
      note: note.text.trim(),
      account: widget.expense.account,
    );

    await AppState.instance.updateExpense(
      widget.expense,
      updated,
    );

    widget.onSaved?.call();

    if (!mounted) return;

    Navigator.pop(context);

    showSnack(
      context,
      'Expense updated',
    );
  }
}

// ============================================================
// SUMMARY PAGE
// ============================================================

// ============================================================
// SETTINGS PAGE
// ============================================================

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        15,
        18,
        30,
      ),
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 22),

        _SettingsGroup(
          title: 'BUDGET',
          children: [
            _SettingsTile(
              icon: Icons.account_balance_wallet_rounded,
              iconColor: const Color(0xFF8758E8),
              title: 'Monthly Wallet Budget',
              value: currency(app.budgetForAccount('Wallet')),
              onTap: () {
                showAccountBudgetEditor(context, 'Wallet');
              },
            ),
            _SettingsTile(
              icon: Icons.account_balance_rounded,
              iconColor: const Color(0xFF1976F3),
              title: 'Monthly Account Budget',
              value: currency(app.budgetForAccount('Account')),
              onTap: () {
                showAccountBudgetEditor(context, 'Account');
              },
            ),
            _SettingsTile(
              icon: Icons.calendar_month_rounded,
              iconColor: const Color(0xFF26A9C9),
              title: 'Current Month',
              value: app.selectedMonthName,
              onTap: () {
                showMonthSelector(context);
              },
            ),
          ],
        ),

        const SizedBox(height: 18),

        _SettingsGroup(
          title: 'DATA',
          children: [
            _SettingsTile(
              icon: Icons.file_download_outlined,
              iconColor: const Color(0xFF1976F3),
              title: 'Export Data',
              value: 'CSV / PDF',
              onTap: () {
                showExportDialog(context);
              },
            ),
          ],
        ),

        const SizedBox(height: 18),

        _SettingsGroup(
          title: 'APP',
          children: [
            _SettingsTile(
              icon: Icons.category_rounded,
              iconColor: const Color(0xFF1976F3),
              title: 'Manage Categories',
              value: 'Add, edit or delete',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CategoryManagementPage(),
                  ),
                );
              },
            ),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              iconColor: const Color(0xFF65758B),
              title: 'About',
              value: 'Version 1.0.0',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// CATEGORY MANAGEMENT
// ============================================================

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() =>
      _CategoryManagementPageState();
}

class _CategoryManagementPageState
    extends State<CategoryManagementPage> {
  @override
  Widget build(BuildContext context) {
    final categories = AppState.instance.categories;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FC),
        elevation: 0,
        title: const Text(
          'Categories',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _addCategory,
            icon: const Icon(
              Icons.add_rounded,
              color: Color(0xFF1976F3),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: categories.length,
        itemBuilder: (_, index) {
          final category = categories[index];

          final expenseCount = AppState
              .instance
              .currentMonthData
              .expenses
              .where(
                (expense) =>
                    expense.category == category.name,
              )
              .length;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE7EBF1),
              ),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha:.11),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                ),
              ),
              title: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                '$expenseCount expenses',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF8993A4),
                ),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editCategory(category);
                  }

                  if (value == 'delete') {
                    _deleteCategory(category);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1976F3),
        foregroundColor: Colors.white,
        onPressed: _addCategory,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _addCategory() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'New Category',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: inputDecoration(
            'Category name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await AppState.instance.addCategory(
                  controller.text.trim(),
                );

                if (!mounted) return;

                setState(() {});

                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editCategory(ExpenseCategory category) {
    final controller =
        TextEditingController(text: category.name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Edit Category',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: inputDecoration(
            'Category name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async{
              final newName = controller.text.trim();

              if (newName.isEmpty) return;

              final oldName = category.name;

              category.name = newName;

for (final month
    in AppState.instance.months.values) {
  for (final expense in month.expenses) {
    if (expense.category == oldName) {
      expense.category = newName;
    }
  }
}
await AppState.instance.storage.saveCategories(
  AppState.instance.categories,
);

await AppState.instance.storage.saveMonths(
  AppState.instance.months,
);

if (!mounted) return;

setState(() {});

Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(ExpenseCategory category) {
    if (AppState.instance.categories.length <= 1) {
      showSnack(
        context,
        'At least one category is required',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Delete Category?',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'Delete "${category.name}"? Existing expenses will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE34C55),
            ),
            onPressed: () async{
              AppState.instance.categories.remove(
  category,
);

await AppState.instance.storage.saveCategories(
  AppState.instance.categories,
);

              if (!mounted) return;

              setState(() {});

              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// ACCOUNT / WALLET MONTHLY BUDGET EDITOR
// ============================================================

Future<void> showAccountBudgetEditor(
  BuildContext context,
  String account,
) async {
  final app = AppState.instance;
  final controller = TextEditingController(
    text: app.budgetForAccount(account).toStringAsFixed(0),
  );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            22,
            20,
            25,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly $account Budget',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                app.selectedMonthName,
                style: const TextStyle(
                  color: Color(0xFF8993A4),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: inputDecoration(
                  'Enter budget',
                  prefixIcon: Icons.currency_rupee_rounded,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 51,
                child: FilledButton(
                  onPressed: () async {
                    final value = double.tryParse(
                      controller.text.trim(),
                    );

                    if (value == null || value < 0) {
                      showSnack(
                        sheetContext,
                        'Enter a valid budget',
                      );
                      return;
                    }

                    await app.setBudgetForAccount(
                      account,
                      value,
                    );

                    if (!sheetContext.mounted) return;

                    Navigator.of(sheetContext).pop();

                    showSnack(
                      context,
                      '$account budget updated',
                    );
                  },
                  child: const Text('Save Budget'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  controller.dispose();
}

// ============================================================
// MONTH SELECTOR
// ============================================================

void showMonthSelector(BuildContext context) async {
  final app = AppState.instance;
  final now = DateTime.now();

  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime(
      app.selectedMonth.year,
      app.selectedMonth.month,
      1,
    ),
    firstDate: DateTime(now.year - 10, 1, 1),
    lastDate: DateTime(now.year + 10, 12, 31),
    initialDatePickerMode: DatePickerMode.day,
    helpText: 'Select month',
  );

  if (picked == null) return;

  final selectedMonth = DateTime(
    picked.year,
    picked.month,
  );

  final name = AppState.monthName(selectedMonth);

  app.selectedMonth = selectedMonth;

  app.months.putIfAbsent(
    name,
    () => MonthlyData(
      budget: 50000,
      expenses: [],
    ),
  );

  await app.storage.saveMonths(app.months);
  await app.storage.saveSelectedMonth(selectedMonth);
}

// ============================================================
// EXPORT
// ============================================================

Future<void> showExportDialog(BuildContext context) async {
  final app = AppState.instance;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          4,
          20,
          30,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Your Data',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '${app.selectedAccount} • ${app.selectedMonthName}',
              style: const TextStyle(
                color: Color(0xFF8490A1),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Export the selected account and month.',
              style: TextStyle(
                color: Color(0xFF8490A1),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),

            _ExportOption(
              icon: Icons.table_chart_rounded,
              title: 'CSV',
              subtitle: 'Spreadsheet-compatible expense file',
              onTap: () async {
                Navigator.pop(sheetContext);
                await _exportCurrentAccountCsv(context);
              },
            ),

            const SizedBox(height: 9),

            _ExportOption(
              icon: Icons.picture_as_pdf_rounded,
              title: 'PDF Report',
              subtitle: 'Readable monthly expense report',
              onTap: () async {
                Navigator.pop(sheetContext);
                await _exportCurrentAccountPdf(context);
              },
            ),
          ],
        ),
      );
    },
  );
}

List<Expense> _exportExpenses() {
  final app = AppState.instance;

  final expenses = List<Expense>.from(
    app.activeExpenses,
  );

  expenses.sort(
    (a, b) => b.date.compareTo(a.date),
  );

  return expenses;
}

String _csvCell(Object? value) {
  final text = value?.toString() ?? '';
  final escaped = text.replaceAll('"', '""');

  if (escaped.contains(',') ||
      escaped.contains('"') ||
      escaped.contains('\n') ||
      escaped.contains('\r')) {
    return '"$escaped"';
  }

  return escaped;
}

String _exportFileDate() {
  final now = DateTime.now();

  String twoDigits(int value) =>
      value.toString().padLeft(2, '0');

  return '${now.year}${twoDigits(now.month)}${twoDigits(now.day)}_'
      '${twoDigits(now.hour)}${twoDigits(now.minute)}';
}

Future<void> _exportCurrentAccountCsv(
  BuildContext context,
) async {
  try {
    final app = AppState.instance;
    final expenses = _exportExpenses();

    final rows = <List<Object?>>[
      [
        'Date',
        'Account',
        'Category',
        'Expense',
        'Amount',
        'Note',
      ],
      ...expenses.map(
        (expense) => [
          dateText(expense.date),
          expense.account,
          expense.category,
          expense.title,
          expense.amount.toStringAsFixed(2),
          expense.note,
        ],
      ),
    ];

    final csv = rows
        .map(
          (row) => row.map(_csvCell).join(','),
        )
        .join('\r\n');

    final bytes = Uint8List.fromList(
      utf8.encode('\uFEFF$csv'),
    );

    final fileName =
        'expenses_${app.selectedAccount.toLowerCase()}_'
        '${app.selectedMonthName.toLowerCase().replaceAll(' ', '_')}_'
        '${_exportFileDate()}.csv';

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'text/csv',
            name: fileName,
          ),
        ],
        subject:
            '${app.selectedAccount} expenses - '
            '${app.selectedMonthName}',
        text:
            '${app.selectedAccount} expenses for '
            '${app.selectedMonthName}',
      ),
    );

    if (context.mounted) {
      showSnack(
        context,
        'CSV export ready',
      );
    }
  } catch (error) {
    if (context.mounted) {
      showSnack(
        context,
        'CSV export failed',
      );
    }
  }
}

Future<void> _exportCurrentAccountPdf(
  BuildContext context,
) async {
  try {
    final app = AppState.instance;
    final expenses = _exportExpenses();
    final document = pw.Document();

    final total = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    final budget = app.currentBudget;
    final remaining = budget - total;

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pdfContext) {
          return [
            pw.Text(
              'Personal Expense Tracker',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              '${app.selectedAccount} • ${app.selectedMonthName}',
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 18),

            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
              ),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  children: [
                    _pdfCell('Budget', bold: true),
                    _pdfCell(
                      currency(budget),
                      bold: true,
                    ),
                    _pdfCell('Spent', bold: true),
                    _pdfCell(
                      currency(total),
                      bold: true,
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfCell('Remaining'),
                    _pdfCell(
                      currency(remaining),
                    ),
                    _pdfCell('Expenses'),
                    _pdfCell(
                      expenses.length.toString(),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            if (expenses.isEmpty)
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(
                    top: 40,
                  ),
                  child: pw.Text(
                    'No expenses for this account and month.',
                    style: const pw.TextStyle(
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.15),
                  1: pw.FlexColumnWidth(1.2),
                  2: pw.FlexColumnWidth(1.9),
                  3: pw.FlexColumnWidth(1.2),
                  4: pw.FlexColumnWidth(1.0),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _pdfCell('Date', bold: true),
                      _pdfCell('Category', bold: true),
                      _pdfCell('Expense', bold: true),
                      _pdfCell('Note', bold: true),
                      _pdfCell('Amount', bold: true),
                    ],
                  ),
                  ...expenses.map(
                    (expense) => pw.TableRow(
                      children: [
                        _pdfCell(
                          dateText(expense.date),
                        ),
                        _pdfCell(expense.category),
                        _pdfCell(expense.title),
                        _pdfCell(
                          expense.note.isEmpty
                              ? '-'
                              : expense.note,
                        ),
                        _pdfCell(
                          currency(expense.amount),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            pw.SizedBox(height: 18),
            pw.Text(
              'Generated ${dateText(DateTime.now())}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
          ];
        },
      ),
    );

    final bytes = Uint8List.fromList(
      await document.save(),
    );

    final fileName =
        'expenses_${app.selectedAccount.toLowerCase()}_'
        '${app.selectedMonthName.toLowerCase().replaceAll(' ', '_')}_'
        '${_exportFileDate()}.pdf';

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'application/pdf',
            name: fileName,
          ),
        ],
        subject:
            '${app.selectedAccount} expense report - '
            '${app.selectedMonthName}',
        text:
            '${app.selectedAccount} expense report for '
            '${app.selectedMonthName}',
      ),
    );

    if (context.mounted) {
      showSnack(
        context,
        'PDF export ready',
      );
    }
  } catch (error) {
    if (context.mounted) {
      showSnack(
        context,
        'PDF export failed',
      );
    }
  }
}

pw.Widget _pdfCell(
  String text, {
  bool bold = false,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 8.5,
        fontWeight:
            bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE4E9F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF1976F3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8993A4),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF8993A4),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ============================================================
// DONUT CHART
// ============================================================

class DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  DonutChartPainter({
    required this.values,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final total =
        values.fold(0.0, (a, b) => a + b);

    if (total == 0) return;

    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        size.shortestSide / 2 - 15;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 23
      ..strokeCap = StrokeCap.butt;

    double startAngle = -1.5708;

    for (int i = 0; i < values.length; i++) {
      final sweep =
          values[i] / total * 6.283185;

      paint.color =
          colors[i % colors.length];

      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        startAngle,
        sweep,
        false,
        paint,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(
    covariant DonutChartPainter oldDelegate,
  ) {
    return oldDelegate.values != values ||
        oldDelegate.colors != colors;
  }
}

// ============================================================
// SETTINGS COMPONENTS
// ============================================================

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 4,
            bottom: 8,
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF8B95A4),
              fontWeight: FontWeight.w800,
              letterSpacing: .9,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFE6EAF0),
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  const Divider(
                    height: 1,
                    indent: 60,
                    endIndent: 14,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 2,
      ),
      leading: Container(
        width: 37,
        height: 37,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha:.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: iconColor,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF8C96A6),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF9BA4B1),
      ),
    );
  }
}

// ============================================================
// OTHER COMPONENTS
// ============================================================

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE7EBF0),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF1FA578),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF8A94A3),
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthComparisonRow extends StatelessWidget {
  final String month;
  final double amount;

  const _MonthComparisonRow({
    required this.month,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              month,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            currency(amount),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: const Color(0xFFE3E8EF),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF1976F3),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1976F3)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF1976F3)
                : const Color(0xFFE1E6EE),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: selected
                ? Colors.white
                : const Color(0xFF657184),
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 43,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1976F3)
              : Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected
                ? const Color(0xFF1976F3)
                : const Color(0xFFE1E6EE),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: selected
                ? Colors.white
                : const Color(0xFF687486),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 7,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4E596A),
        ),
      ),
    );
  }
}

class _EmptyExpenses extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 32,
              color: Color(0xFF1976F3),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'No expenses found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Try another search or add an expense.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF8B95A5),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

String currency(double amount) {
  final rounded = amount.round();

  final text = rounded.toString();

  final buffer = StringBuffer();

  int count = 0;

  for (int i = text.length - 1; i >= 0; i--) {
    buffer.write(text[i]);
    count++;

    if (count == 3 &&
        i != 0 &&
        i != text.length - 1) {
      buffer.write(',');
      count = 0;
    }
  }

  final formatted =
      buffer.toString().split('').reversed.join();

  return '₹$formatted';
}

String dateText(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

InputDecoration inputDecoration(
  String hint, {
  IconData? prefixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon:
        prefixIcon != null ? Icon(prefixIcon) : null,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 14,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(
        color: Color(0xFFE0E6EF),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(
        color: Color(0xFFE0E6EF),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(
        color: Color(0xFF1976F3),
        width: 1.5,
      ),
    ),
  );
}

void showSnack(
  BuildContext context,
  String message,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}
class _AccountSelector extends StatelessWidget {
  final String selectedAccount;
  final ValueChanged<String> onChanged;

  const _AccountSelector({
    required this.selectedAccount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const accounts = [
      'Account',
      'Wallet',
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: accounts.map((account) {
          final selected = selectedAccount == account;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(account),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      account == 'Wallet'
                          ? Icons.account_balance_wallet_rounded
                          : Icons.account_balance_rounded,
                      size: 16,
                      color: selected
                          ? const Color(0xFF1976F3)
                          : const Color(0xFF8993A4),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      account,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: selected
                            ? const Color(0xFF1976F3)
                            : const Color(0xFF8993A4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}