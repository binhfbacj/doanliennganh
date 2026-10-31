import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'models/budget.dart';
import 'models/recurring_bill.dart';
import 'models/savings_goal.dart';
import 'models/transaction.dart';
import 'models/user_model.dart';
import 'screens/analytics_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/recurring_bills_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/settings_screen.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'utils/app_localizations.dart';
import 'utils/app_theme.dart';
import 'widgets/add_transaction_modal.dart';
import 'widgets/voice_assistant_sheet.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final results = await Future.wait([
    StorageService.instance.loadThemeMode(),
    StorageService.instance.loadLanguage(),
  ]);

  AppTheme.themeModeNotifier.value = results[0] == 'light'
      ? ThemeMode.light
      : ThemeMode.dark;
  AppLocalizations.setLanguage(results[1]);

  runApp(const ExpenseApp());
}

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          ),
        );
        return ValueListenableBuilder<String>(
          valueListenable: AppLocalizations.languageNotifier,
          builder: (context, lang, _) {
            return MaterialApp(
              title: tr(
                'Quản Lý Tiêu Dùng Thông Minh',
                'Smart Bee Expense Tracker',
              ),
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
              locale: lang == 'en'
                  ? const Locale('en', 'US')
                  : const Locale('vi', 'VN'),
              home: MainNavigationShell(
                key: ValueKey('${themeMode.name}_$lang'),
              ),
            );
          },
        );
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  final Set<int> _visitedTabs = {0};
  UserModel? _currentUser;
  bool _hasSeenOnboarding = false;
  List<TransactionRecord> _transactions = [];
  List<BudgetItem> _budgets = [];
  List<SavingsGoal> _savingsGoals = [];
  List<RecurringBill> _recurringBills = [];
  bool _isLoading = true;

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
      _visitedTabs.add(index);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    AppTheme.themeModeNotifier.addListener(_onAppConfigChanged);
    AppLocalizations.languageNotifier.addListener(_onAppConfigChanged);
  }

  @override
  void dispose() {
    AppTheme.themeModeNotifier.removeListener(_onAppConfigChanged);
    AppLocalizations.languageNotifier.removeListener(_onAppConfigChanged);
    super.dispose();
  }

  void _onAppConfigChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    final user = await AuthService.instance.getCurrentUser();
    StorageService.instance.setActiveUser(user?.id);
    final results = await Future.wait([
      StorageService.instance.loadTransactions(),
      StorageService.instance.loadBudgets(),
      StorageService.instance.loadSavingsGoals(),
      StorageService.instance.loadRecurringBills(),
      user != null
          ? StorageService.instance.hasSeenOnboarding(user.id)
          : Future.value(false),
    ]);
    final list = results[0] as List<TransactionRecord>;
    final budgets = results[1] as List<BudgetItem>;
    final goals = results[2] as List<SavingsGoal>;
    final bills = results[3] as List<RecurringBill>;
    final seenOnboarding = results[4] as bool;

    final now = DateTime.now();
    bool autoAddedAny = false;
    for (int i = 0; i < bills.length; i++) {
      final b = bills[i];
      if (b.isActive && b.autoAdd && b.isDueOrOverdue(now)) {
        final dueDate = b.dueDateForMonth(now);
        list.insert(
          0,
          TransactionRecord(
            id: 'tx_auto_${b.id}_${now.year}_${now.month}',
            title: b.title,
            amount: b.amount,
            type: b.type,
            categoryId: b.categoryId,
            dateTime: DateTime(dueDate.year, dueDate.month, dueDate.day, 9, 0),
            note: tr(
              'Tự động ghi nhận khoản định kỳ hàng tháng',
              'Auto-logged monthly recurring item',
            ),
            isVoiceInput: false,
          ),
        );
        bills[i] = b.copyWith(lastPaidMonth: now.month, lastPaidYear: now.year);
        autoAddedAny = true;
      }
    }

    if (autoAddedAny) {
      list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      await StorageService.instance.saveTransactions(list);
      await StorageService.instance.saveRecurringBills(bills);
    }

    if (mounted) {
      setState(() {
        _currentUser = user;
        _hasSeenOnboarding = seenOnboarding;
        _transactions = list;
        _budgets = budgets;
        _savingsGoals = goals;
        _recurringBills = bills;
        _isLoading = false;
      });
    }
  }

  void _onAuthSuccess(UserModel user) async {
    StorageService.instance.setActiveUser(user.id);
    final seen = await StorageService.instance.hasSeenOnboarding(user.id);
    if (mounted) {
      setState(() {
        _currentUser = user;
        _hasSeenOnboarding = seen;
      });
      _loadData();
    }
  }

  void _finishOnboarding() async {
    if (_currentUser != null) {
      await StorageService.instance.setOnboardingSeen(_currentUser!.id);
    }
    if (mounted) setState(() => _hasSeenOnboarding = true);
  }

  void _replayOnboarding() => setState(() => _hasSeenOnboarding = false);

  Future<void> _logout() async {
    await AuthService.instance.logout();
    StorageService.instance.setActiveUser(null);
    if (mounted) {
      setState(() {
        _currentUser = null;
        _hasSeenOnboarding = false;
        _transactions = [];
        _budgets = [];
        _savingsGoals = [];
        _recurringBills = [];
        _currentIndex = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('Đã đăng xuất tài khoản!', 'Signed out successfully!'),
          ),
        ),
      );
    }
  }

  Future<void> _saveData() =>
      StorageService.instance.saveTransactions(_transactions);

  Future<void> _saveBudgets(List<BudgetItem> budgets) async {
    setState(() => _budgets = budgets);
    await StorageService.instance.saveBudgets(budgets);
  }

  Future<void> _saveSavingsGoals(List<SavingsGoal> goals) async {
    setState(() => _savingsGoals = goals);
    await StorageService.instance.saveSavingsGoals(goals);
  }

  Future<void> _saveRecurringBills(List<RecurringBill> bills) async {
    setState(() => _recurringBills = bills);
    await StorageService.instance.saveRecurringBills(bills);
  }

  void _openRecurringBillsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecurringBillsScreen(
          bills: _recurringBills,
          onBillsChanged: _saveRecurringBills,
          onTransactionAdded: _addTransaction,
        ),
      ),
    );
  }

  void _logRecurringBillQuick(RecurringBill bill) {
    final now = DateTime.now();
    _addTransaction(
      TransactionRecord(
        id: 'tx_rec_${now.millisecondsSinceEpoch}',
        title: bill.title,
        amount: bill.amount,
        type: bill.type,
        categoryId: bill.categoryId,
        dateTime: now,
        note: tr(
          'Khoản định kỳ hàng tháng (Ngày ${bill.dayOfMonth})',
          'Monthly recurring item (Day ${bill.dayOfMonth})',
        ),
        isVoiceInput: false,
      ),
    );

    final updatedList = _recurringBills
        .map(
          (b) => b.id == bill.id
              ? b.copyWith(lastPaidMonth: now.month, lastPaidYear: now.year)
              : b,
        )
        .toList();
    _saveRecurringBills(updatedList);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            '🐝 Đã ghi nhận "${bill.title}" vào sổ giao dịch!',
            '🐝 Logged "${bill.title}" to transactions!',
          ),
          style: const TextStyle(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addTransaction(TransactionRecord tx) {
    setState(() {
      _transactions.insert(0, tx);
      _transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    });
    _saveData();
  }

  void _editTransaction(TransactionRecord updatedTx) {
    setState(() {
      final index = _transactions.indexWhere((t) => t.id == updatedTx.id);
      if (index != -1) {
        _transactions[index] = updatedTx;
      } else {
        _transactions.insert(0, updatedTx);
      }
      _transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    });
    _saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            'Đã cập nhật giao dịch "${updatedTx.title}"',
            'Updated transaction "${updatedTx.title}"',
          ),
          style: const TextStyle(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _deleteTransaction(TransactionRecord tx) {
    final index = _transactions.indexOf(tx);
    setState(() => _transactions.removeWhere((t) => t.id == tx.id));
    _saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            'Đã xóa giao dịch "${tx.title}"',
            'Deleted transaction "${tx.title}"',
          ),
        ),
        action: SnackBarAction(
          label: tr('HOÀN TÁC', 'UNDO'),
          textColor: Colors.amber,
          onPressed: () {
            setState(() {
              if (index >= 0 && index <= _transactions.length) {
                _transactions.insert(index, tx);
              } else {
                _transactions.add(tx);
              }
              _transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
            });
            _saveData();
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openVoiceAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VoiceAssistantSheet(
        onTransactionAdded: _addTransaction,
        transactions: _transactions,
      ),
    );
  }

  void _openAddModal({TransactionRecord? initialTx}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionModal(
        initialTransaction: initialTx,
        onSave: (tx) =>
            initialTx != null ? _editTransaction(tx) : _addTransaction(tx),
      ),
    );
  }

  Widget _quickActionTile({
    required BuildContext ctx,
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: () {
        Navigator.of(ctx).pop();
        onTap();
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      tileColor: AppColors.surfaceElevated,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.onPrimary, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.primary,
      ),
    );
  }

  void _showQuickActionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Text('🐝', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  tr('Thao Tác Nhanh', 'Quick Actions'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _quickActionTile(
              ctx: ctx,
              icon: Icons.mic_rounded,
              iconBg: AppColors.primary,
              title: tr('Ghi chép bằng Giọng nói AI', 'AI Voice Expense Entry'),
              subtitle: tr(
                'Nói câu lệnh: "Ăn sáng 35k", "Đổ xăng 60k"...',
                'Say: "Breakfast 35k", "Coffee 50k"...',
              ),
              onTap: _openVoiceAssistant,
            ),
            const SizedBox(height: 10),
            _quickActionTile(
              ctx: ctx,
              icon: Icons.add_rounded,
              iconBg: AppColors.primaryDark,
              title: tr('Nhập giao dịch thủ công', 'Manual Transaction Entry'),
              subtitle: tr(
                'Tùy chỉnh số tiền, danh mục, ngày tháng',
                'Customize amount, category, and date',
              ),
              onTap: _openAddModal,
            ),
            const SizedBox(height: 10),
            _quickActionTile(
              ctx: ctx,
              icon: Icons.event_repeat_rounded,
              iconBg: AppColors.primaryDark,
              title: tr(
                'Hoá Đơn & Khoản Định Kỳ 🔁',
                'Recurring Bills & Income 🔁',
              ),
              subtitle: tr(
                'Tiền nhà, điện nước, lương cố định hàng tháng',
                'Rent, utilities, subscriptions & monthly salary',
              ),
              onTap: _openRecurringBillsScreen,
            ),
            const SizedBox(height: 10),
            _quickActionTile(
              ctx: ctx,
              icon: Icons.savings_rounded,
              iconBg: AppColors.primary,
              title: tr(
                'Hũ Mật Tích Lũy & Tiết kiệm',
                'Honey Jar Savings Goals',
              ),
              subtitle: tr(
                'Theo dõi các kế hoạch tài chính dài hạn',
                'Track your long-term financial goals',
              ),
              onTap: () => _switchTab(4),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  void _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('Xóa toàn bộ giao dịch?', 'Delete all transactions?')),
        content: Text(
          tr(
            'Hành động này sẽ xóa sạch dữ liệu. Số dư ví sẽ trở về 0đ để bạn nhập dữ liệu thật.',
            'This action will permanently clear all transactions and reset your balance to 0đ.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('Hủy', 'Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              tr('Xóa hết', 'Delete All'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _transactions.clear());
      await StorageService.instance.clearAllTransactions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'Đã xóa sạch tất cả giao dịch!',
              'All transactions have been deleted!',
            ),
          ),
        ),
      );
    }
  }

  Widget _buildTabAt(int index) {
    if (!_visitedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    switch (index) {
      case 0:
        return HomeScreen(
          user: _currentUser,
          transactions: _transactions,
          budgets: _budgets,
          savingsGoals: _savingsGoals,
          recurringBills: _recurringBills,
          onOpenVoiceAssistant: _openVoiceAssistant,
          onOpenAddModal: _openAddModal,
          onDeleteTransaction: _deleteTransaction,
          onEditTransaction: (tx) => _openAddModal(initialTx: tx),
          onGoToHistory: () => _switchTab(3),
          onGoToBudget: () => _switchTab(1),
          onGoToSavings: () => _switchTab(4),
          onOpenRecurringBills: _openRecurringBillsScreen,
          onLogRecurringBill: _logRecurringBillQuick,
          onOpenSettings: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  user: _currentUser,
                  onClearAllData: _clearAllData,
                  onOpenVoiceAssistant: _openVoiceAssistant,
                  onLogout: _logout,
                  onReplayOnboarding: _replayOnboarding,
                  onGoToSavings: () {
                    Navigator.of(context).pop();
                    _switchTab(4);
                  },
                ),
              ),
            );
          },
        );
      case 1:
        return BudgetScreen(
          transactions: _transactions,
          budgets: _budgets,
          onBudgetsChanged: _saveBudgets,
        );
      case 2:
        return AnalyticsScreen(transactions: _transactions);
      case 3:
        return HistoryScreen(
          transactions: _transactions,
          onDeleteTransaction: _deleteTransaction,
          onEditTransaction: (tx) => _openAddModal(initialTx: tx),
        );
      case 4:
        return SavingsScreen(
          goals: _savingsGoals,
          onGoalsChanged: _saveSavingsGoals,
        );
      default:
        return SettingsScreen(
          user: _currentUser,
          onClearAllData: _clearAllData,
          onOpenVoiceAssistant: _openVoiceAssistant,
          onLogout: _logout,
          onReplayOnboarding: _replayOnboarding,
          onGoToSavings: () => _switchTab(4),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (_currentUser == null) {
      return AuthScreen(onAuthSuccess: _onAuthSuccess);
    }
    if (!_hasSeenOnboarding) {
      return OnboardingScreen(onFinish: _finishOnboarding);
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(6, _buildTabAt),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActionsSheet,
        elevation: 8,
        backgroundColor: Colors.transparent,
        shape: const CircleBorder(),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.beeGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: AppColors.onPrimary,
            size: 32,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: AppColors.isDark ? 0.5 : 0.08,
              ),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex > 4 ? 4 : _currentIndex,
          onTap: _switchTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.isDark
              ? AppColors.primary
              : AppColors.primaryDark,
          unselectedItemColor: AppColors.textMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_rounded),
              label: tr('Tổng quan', 'Home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_wallet_rounded),
              label: tr('Ngân sách', 'Budget'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.pie_chart_rounded),
              label: tr('Báo cáo', 'Analytics'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_rounded),
              label: tr('Lịch sử', 'History'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.savings_rounded),
              label: tr('Tiết kiệm', 'Savings'),
            ),
          ],
        ),
      ),
    );
  }
}
