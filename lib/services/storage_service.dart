import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget.dart';
import '../models/recurring_bill.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';

class StorageService {
  static const String _keyTransactionsBase = 'app_transactions_real';
  static const String _keyBudgetsBase = 'app_budgets';
  static const String _keySavingsBase = 'app_savings_goals';
  static const String _keyRecurringBase = 'app_recurring_bills';
  static const String _keyLegacyV2 = 'app_transactions_v2';
  static const String _keyLegacyInit = 'app_initial_loaded_v2';
  static const String _keyLegacyMigrated = 'app_migrated_to_user_scope_v1';

  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  String? _activeUserId;

  void setActiveUser(String? userId) {
    _activeUserId = (userId != null && userId.isNotEmpty) ? userId : null;
  }

  String _scopedKey(String baseKey) =>
      _activeUserId == null ? baseKey : '${baseKey}_$_activeUserId';

  // Chuyển dữ liệu cũ sang tài khoản đầu tiên đăng nhập
  Future<void> _migrateLegacyDataIfNeeded(SharedPreferences prefs) async {
    if (_activeUserId == null) return;
    if (prefs.getBool(_keyLegacyMigrated) ?? false) return;

    const baseKeys = [
      _keyTransactionsBase,
      _keyBudgetsBase,
      _keySavingsBase,
      _keyRecurringBase,
    ];

    for (final base in baseKeys) {
      final scoped = _scopedKey(base);
      if (!prefs.containsKey(scoped) && prefs.containsKey(base)) {
        final val = prefs.getString(base);
        if (val != null && val.isNotEmpty) {
          await prefs.setString(scoped, val);
        }
        await prefs.remove(base);
      }
    }
    await prefs.setBool(_keyLegacyMigrated, true);
  }

  // Helper đọc/ghi danh sách JSON dùng chung
  Future<List<T>> _loadList<T>(
    String baseKey,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _migrateLegacyDataIfNeeded(prefs);
      final raw = prefs.getString(_scopedKey(baseKey));
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Storage load error ($baseKey): $e');
      return [];
    }
  }

  Future<bool> _saveList<T>(
    String baseKey,
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(items.map(toJson).toList());
      return await prefs.setString(_scopedKey(baseKey), encoded);
    } catch (e) {
      debugPrint('Storage save error ($baseKey): $e');
      return false;
    }
  }

  // Giao dịch
  Future<List<TransactionRecord>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_keyLegacyInit)) await prefs.remove(_keyLegacyInit);
    if (prefs.containsKey(_keyLegacyV2)) await prefs.remove(_keyLegacyV2);

    final list = await _loadList(
      _keyTransactionsBase,
      TransactionRecord.fromJson,
    );
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  Future<bool> saveTransactions(List<TransactionRecord> transactions) =>
      _saveList(_keyTransactionsBase, transactions, (t) => t.toJson());

  Future<bool> clearAllTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_scopedKey(_keyTransactionsBase));
      await prefs.remove(_keyLegacyV2);
      await prefs.remove(_keyLegacyInit);
      return true;
    } catch (e) {
      debugPrint('Error clearing transactions: $e');
      return false;
    }
  }

  // Onboarding
  Future<bool> hasSeenOnboarding(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('app_onboarding_seen_$userId') ?? false;
  }

  Future<void> setOnboardingSeen(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_onboarding_seen_$userId', true);
  }

  // Ngân sách
  Future<bool> saveBudgets(List<BudgetItem> budgets) =>
      _saveList(_keyBudgetsBase, budgets, (b) => b.toJson());

  Future<List<BudgetItem>> loadBudgets() =>
      _loadList(_keyBudgetsBase, BudgetItem.fromJson);

  // Mục tiêu tiết kiệm
  Future<bool> saveSavingsGoals(List<SavingsGoal> goals) =>
      _saveList(_keySavingsBase, goals, (g) => g.toJson());

  Future<List<SavingsGoal>> loadSavingsGoals() =>
      _loadList(_keySavingsBase, SavingsGoal.fromJson);

  // Hoá đơn định kỳ
  Future<bool> saveRecurringBills(List<RecurringBill> bills) =>
      _saveList(_keyRecurringBase, bills, (b) => b.toJson());

  Future<List<RecurringBill>> loadRecurringBills() async {
    final list = await _loadList(_keyRecurringBase, RecurringBill.fromJson);
    list.sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
    return list;
  }

  // Chế độ giao diện & ngôn ngữ
  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme_mode', mode);
  }

  Future<String> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_theme_mode') ?? 'dark';
  }

  Future<void> saveLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', langCode);
  }

  Future<String> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_language') ?? 'vi';
  }
}
