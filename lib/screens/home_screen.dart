import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/recurring_bill.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../models/user_model.dart';
import '../services/financial_advisor.dart';
import '../utils/app_localizations.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/balance_card.dart';
import '../widgets/bee_mascot_card.dart';
import '../widgets/expense_chart.dart';
import '../widgets/transaction_tile.dart';

class HomeScreen extends StatelessWidget {
  final UserModel? user;
  final List<TransactionRecord> transactions;
  final List<BudgetItem> budgets;
  final List<SavingsGoal> savingsGoals;
  final List<RecurringBill> recurringBills;
  final VoidCallback onOpenVoiceAssistant;
  final VoidCallback onOpenAddModal;
  final Function(TransactionRecord) onDeleteTransaction;
  final Function(TransactionRecord)? onEditTransaction;
  final VoidCallback onGoToHistory;
  final VoidCallback onGoToBudget;
  final VoidCallback onGoToSavings;
  final VoidCallback? onOpenRecurringBills;
  final Function(RecurringBill)? onLogRecurringBill;
  final VoidCallback? onOpenSettings;

  const HomeScreen({
    super.key,
    this.user,
    required this.transactions,
    this.budgets = const [],
    this.savingsGoals = const [],
    this.recurringBills = const [],
    required this.onOpenVoiceAssistant,
    required this.onOpenAddModal,
    required this.onDeleteTransaction,
    this.onEditTransaction,
    required this.onGoToHistory,
    required this.onGoToBudget,
    required this.onGoToSavings,
    this.onOpenRecurringBills,
    this.onLogRecurringBill,
    this.onOpenSettings,
  });

  BoxDecoration _cardBox({double radius = 22, Color? borderColor}) =>
      BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark ? 0.45 : 0.06,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    double totalIncome = 0, totalExpense = 0;
    double allTimeIncome = 0, allTimeExpense = 0;

    for (final tx in transactions) {
      final isIncome = tx.type == TransactionType.income;
      if (isIncome) {
        allTimeIncome += tx.amount;
      } else {
        allTimeExpense += tx.amount;
      }
      if (tx.dateTime.year == now.year && tx.dateTime.month == now.month) {
        if (isIncome) {
          totalIncome += tx.amount;
        } else {
          totalExpense += tx.amount;
        }
      }
    }

    final advisor = FinancialAdvisorService.instance;
    final health = advisor.evaluateHealth(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      budgets: budgets,
      transactions: transactions,
    );
    final alerts = advisor.getBudgetAlerts(
      budgets: budgets,
      transactions: transactions,
      month: now,
    );

    final totalBudget = budgets
        .where((b) => b.month == now.month && b.year == now.year)
        .fold(0.0, (s, b) => s + b.limit);
    final dailyBudget = advisor.calculateDailyRemainingBudget(
      totalBudget: totalBudget,
      totalSpent: totalExpense,
      now: now,
    );
    final recentTransactions = transactions.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {},
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(now),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: BalanceCard(
                    totalIncome: allTimeIncome,
                    totalExpense: allTimeExpense,
                    balance: allTimeIncome - allTimeExpense,
                  ),
                ),
                const SizedBox(height: 14),
                if (alerts.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildBudgetAlertBanner(alerts.first),
                  ),
                  const SizedBox(height: 14),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildFinancialHealthCard(
                    health,
                    totalBudget,
                    dailyBudget,
                  ),
                ),
                const SizedBox(height: 16),
                BeeMascotCard(
                  transactions: transactions,
                  totalIncome: totalIncome,
                  totalExpense: totalExpense,
                ),
                const SizedBox(height: 16),
                _buildQuickActionRow(),
                const SizedBox(height: 18),
                if (recurringBills.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _RecurringBillsHomeBanner(
                      bills: recurringBills,
                      now: now,
                      onOpenRecurringBills: onOpenRecurringBills,
                      onLogBill: onLogRecurringBill,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: _cardBox(radius: 24),
                    child: ExpenseWeeklyChart(transactions: transactions),
                  ),
                ),
                const SizedBox(height: 22),
                if (savingsGoals.isNotEmpty) ...[
                  _buildSavingsPreviewSection(),
                  const SizedBox(height: 16),
                ],
                _buildRecentTransactionsSection(recentTransactions),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(DateTime now) {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.navyGradient),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.beeGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🐝', style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greetingText(now.hour),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    user?.name.isNotEmpty == true
                        ? user!.name
                        : tr('Chú Ong Chi Tiêu', 'Smart Bee'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              if (onOpenSettings != null) ...[
                InkWell(
                  onTap: onOpenSettings,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      Icons.settings_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              InkWell(
                onTap: onOpenVoiceAssistant,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    gradient: AppColors.beeGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: AppColors.onPrimary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetAlertBanner(BudgetAlert alert) {
    final color = alert.isOver ? AppColors.expense : AppColors.primaryDark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardBox(
        radius: 20,
        borderColor: alert.isOver ? AppColors.expense : AppColors.primary,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (alert.isOver ? AppColors.expense : AppColors.primary)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              alert.isOver
                  ? Icons.warning_rounded
                  : Icons.notifications_active_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.isOver
                      ? tr(
                          'Cảnh báo: Vượt ngân sách ${alert.category.name}!',
                          'Alert: Over budget for ${alert.category.name}!',
                        )
                      : tr(
                          'Sắp chạm hạn mức: ${alert.category.name}',
                          'Near budget limit: ${alert.category.name}',
                        ),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tr(
                    'Đã chi ${AppFormatters.formatCurrency(alert.spent)} / Hạn mức ${AppFormatters.formatCurrency(alert.limit)} (${(alert.percent * 100).toStringAsFixed(0)}%)',
                    'Spent ${AppFormatters.formatCurrency(alert.spent)} / Limit ${AppFormatters.formatCurrency(alert.limit)} (${(alert.percent * 100).toStringAsFixed(0)}%)',
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onGoToBudget,
            child: Text(
              tr('Xem', 'View'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialHealthCard(
    FinancialHealth health,
    double totalBudget,
    double dailyBudget,
  ) {
    final isGood = health.score >= 70;
    final badgeColor = isGood ? AppColors.income : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.analytics_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr('Sức khỏe tài chính', 'Financial Health'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  tr('${health.score}/100 Điểm', '${health.score}/100 Pts'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isGood ? AppColors.income : AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            health.status,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            health.advice,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (totalBudget > 0 && dailyBudget > 0) ...[
            const SizedBox(height: 12),
            Divider(color: AppColors.border),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr(
                    'Hạn mức chi tiêu mỗi ngày:',
                    'Safe daily spending limit:',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '~${AppFormatters.formatCurrency(dailyBudget)}${tr('/ngày', '/day')}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpenVoiceAssistant,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.beeGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.mic_rounded,
                      color: AppColors.onPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tr('Nói để ghi', 'Voice Log'),
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onOpenAddModal,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.primaryDark,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tr('Nhập tay', 'Add Manual'),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (onOpenRecurringBills != null) ...[
            InkWell(
              onTap: onOpenRecurringBills,
              borderRadius: BorderRadius.circular(18),
              child: Tooltip(
                message: tr('Hoá đơn & Khoản định kỳ', 'Recurring Bills'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.event_repeat_rounded,
                    color: AppColors.primaryDark,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          InkWell(
            onTap: onGoToSavings,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.savings_rounded,
                color: AppColors.primaryDark,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsPreviewSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('Hũ mật tích lũy', 'Honey Jar Savings'),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: onGoToSavings,
                child: Text(
                  tr('Xem tất cả', 'See all'),
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: savingsGoals.take(3).length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              final g = savingsGoals[index];
              return Container(
                width: 220,
                padding: const EdgeInsets.all(14),
                decoration: _cardBox(radius: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(g.icon, color: g.color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            g.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${(g.progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: g.color,
                          ),
                        ),
                      ],
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: g.progress,
                        minHeight: 6,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(g.color),
                      ),
                    ),
                    Text(
                      '${AppFormatters.formatCurrency(g.currentAmount)} / ${AppFormatters.formatCurrency(g.targetAmount)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsSection(
    List<TransactionRecord> recentTransactions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('Giao dịch gần đây', 'Recent Transactions'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: onGoToHistory,
                child: Text(
                  tr('Xem tất cả', 'See all'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (recentTransactions.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: _cardBox(radius: 24),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 40,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('Chưa có giao dịch nào', 'No transactions yet'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr(
                      'Sẵn sàng ghi chép chi tiêu thật của bạn!\nNói câu lệnh giọng nói hoặc bấm Nhập tay để bắt đầu.',
                      'Ready to track your expenses!\nUse Voice Log or tap Add Manual to get started.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          for (final tx in recentTransactions)
            TransactionTile(
              transaction: tx,
              onDelete: () => onDeleteTransaction(tx),
              onEdit: onEditTransaction != null
                  ? () => onEditTransaction!(tx)
                  : null,
            ),
      ],
    );
  }

  String _greetingText(int hour) {
    if (hour < 12) return tr('Chào buổi sáng ☀️', 'Good morning ☀️');
    if (hour < 18) return tr('Chào buổi chiều 🌤️', 'Good afternoon 🌤️');
    return tr('Chào buổi tối 🌙', 'Good evening 🌙');
  }
}

class _RecurringBillsHomeBanner extends StatelessWidget {
  final List<RecurringBill> bills;
  final DateTime now;
  final VoidCallback? onOpenRecurringBills;
  final Function(RecurringBill)? onLogBill;

  const _RecurringBillsHomeBanner({
    required this.bills,
    required this.now,
    this.onOpenRecurringBills,
    this.onLogBill,
  });

  @override
  Widget build(BuildContext context) {
    final unpaidBills =
        bills.where((b) => b.isActive && !b.isPaidForMonth(now)).toList()
          ..sort((a, b) => a.daysUntilDue(now).compareTo(b.daysUntilDue(now)));
    final nextBill = unpaidBills.isNotEmpty ? unpaidBills.first : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: nextBill != null && nextBill.daysUntilDue(now) <= 3
              ? AppColors.primary
              : AppColors.border,
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark ? 0.4 : 0.05,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.event_repeat_rounded,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr(
                      'Hoá đơn & Khoản định kỳ (${bills.length})',
                      'Recurring Bills (${bills.length})',
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (onOpenRecurringBills != null)
                InkWell(
                  onTap: onOpenRecurringBills,
                  child: Text(
                    tr('Quản lý >', 'Manage >'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (nextBill == null)
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.income,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tr(
                      'Tất cả khoản định kỳ tháng ${now.month} đã được ghi nhận!',
                      'All recurring items for month ${now.month} are logged!',
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${nextBill.title} • ${AppFormatters.formatCurrency(nextBill.amount)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nextBill.daysUntilDue(now) < 0
                            ? tr(
                                'Quá hạn ${-nextBill.daysUntilDue(now)} ngày (Ngày ${nextBill.dayOfMonth})',
                                'Overdue by ${-nextBill.daysUntilDue(now)}d (Day ${nextBill.dayOfMonth})',
                              )
                            : nextBill.daysUntilDue(now) == 0
                            ? tr('Đến hạn hôm nay!', 'Due today!')
                            : tr(
                                'Đến hạn ngày ${nextBill.dayOfMonth} (còn ${nextBill.daysUntilDue(now)} ngày)',
                                'Due day ${nextBill.dayOfMonth} (${nextBill.daysUntilDue(now)}d left)',
                              ),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: nextBill.daysUntilDue(now) <= 0
                              ? AppColors.expense
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onLogBill != null)
                  InkWell(
                    onTap: () => onLogBill!(nextBill),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.beeGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tr('Ghi nhận', 'Log Now'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onPrimary,
                        ),
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
