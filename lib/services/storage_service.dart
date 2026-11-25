import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

class StorageService {
  static const String _monthsKey = 'expense_tracker_months';
  static const String _categoriesKey = 'expense_tracker_categories';
  static const String _selectedMonthKey =
      'expense_tracker_selected_month';

  SharedPreferences? _preferences;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  SharedPreferences get preferences {
    if (_preferences == null) {
      throw StateError(
        'StorageService has not been initialized. '
        'Call init() first.',
      );
    }

    return _preferences!;
  }

  // ============================================================
  // MONTHS
  // ============================================================

  Future<void> saveMonths(
    Map<String, MonthlyData> months,
  ) async {
    final Map<String, dynamic> data = {};

    for (final entry in months.entries) {
      data[entry.key] = {
        'budget': entry.value.budget,
        'expenses': entry.value.expenses
            .map((expense) => expense.toJson())
            .toList(),
      };
    }

    await preferences.setString(
      _monthsKey,
      jsonEncode(data),
    );
  }

  Map<String, MonthlyData>? loadMonths() {
    final savedData =
        preferences.getString(_monthsKey);

    if (savedData == null || savedData.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(savedData);

      if (decoded is! Map) {
        return null;
      }

      final Map<String, MonthlyData> result = {};

      for (final entry in decoded.entries) {
        final value = entry.value;

        if (value is! Map) {
          continue;
        }

        final budget =
            (value['budget'] as num?)?.toDouble() ??
                50000.0;

        final rawExpenses =
            value['expenses'];

        final List<Expense> expenses = [];

        if (rawExpenses is List) {
          for (final item in rawExpenses) {
            if (item is Map) {
              try {
                expenses.add(
                  Expense.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                );
              } catch (_) {
                // Ignore invalid expense entries.
              }
            }
          }
        }

        result[entry.key.toString()] =
            MonthlyData(
          budget: budget,
          expenses: expenses,
        );
      }

      return result;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Future<void> saveCategories(
    List<ExpenseCategory> categories,
  ) async {
    final data = categories
        .map(
          (category) => category.toJson(),
        )
        .toList();

    await preferences.setString(
      _categoriesKey,
      jsonEncode(data),
    );
  }

  List<ExpenseCategory>? loadCategories() {
    final savedData =
        preferences.getString(_categoriesKey);

    if (savedData == null || savedData.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(savedData);

      if (decoded is! List) {
        return null;
      }

      final List<ExpenseCategory> result = [];

      for (final item in decoded) {
        if (item is Map) {
          try {
            result.add(
              ExpenseCategory.fromJson(
                Map<String, dynamic>.from(item),
              ),
            );
          } catch (_) {
            // Ignore invalid category entries.
          }
        }
      }

      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // SELECTED MONTH
  // ============================================================

  Future<void> saveSelectedMonth(
    DateTime month,
  ) async {
    await preferences.setString(
      _selectedMonthKey,
      month.toIso8601String(),
    );
  }

  DateTime? loadSelectedMonth() {
    final savedData =
        preferences.getString(_selectedMonthKey);

    if (savedData == null || savedData.isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(savedData);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // CLEAR ALL DATA
  // ============================================================

  Future<void> clearAllData() async {
    await preferences.remove(_monthsKey);
    await preferences.remove(_categoriesKey);
    await preferences.remove(_selectedMonthKey);
  }
}