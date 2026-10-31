import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../utils/app_localizations.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

class BudgetScreen extends StatefulWidget {
  final List<TransactionRecord> transactions;
  final List<BudgetItem> budgets;
  final void Function(List<BudgetItem>) onBudgetsChanged;

  const BudgetScreen({
    super.key,
    required this.transactions,
    required this.budgets,
    required this.onBudgetsChanged,
  });

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late DateTime _selectedMonth;
  late List<BudgetItem> _budgets;

  static const _enMonths = [
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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _budgets = List.from(widget.budgets);
  }

  @override
  void didUpdateWidget(BudgetScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.budgets != widget.budgets) {
      _budgets = List.from(widget.budgets);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
  }

  BudgetItem? _getBudget(String categoryId) {
    for (final b in _budgets) {
      if (b.categoryId == categoryId &&
          b.month == _selectedMonth.month &&
          b.year == _selectedMonth.year) {
        return b;
      }
    }
    return null;
  }

  double _getSpent(String categoryId) {
    return widget.transactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              t.categoryId == categoryId &&
              t.dateTime.month == _selectedMonth.month &&
              t.dateTime.year == _selectedMonth.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  void _upsertBudget(BudgetItem updated) {
    final newList = _budgets.where((b) => b != updated).toList();
    if (updated.limit > 0) newList.add(updated);
    setState(() => _budgets = newList);
    widget.onBudgetsChanged(newList);
  }

  Future<void> _showBudgetDialog(CategoryItem category) async {
    final existing = _getBudget(category.id);
    final controller = TextEditingController(
      text: existing != null && existing.limit > 0
          ? AppFormatters.formatNumber(existing.limit)
          : '',
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) => _BudgetDialog(
        category: category,
        month: _selectedMonth.month,
        year: _selectedMonth.year,
        controller: controller,
        hasExisting: existing != null && existing.limit > 0,
        onSave: (amount) {
          _upsertBudget(
            BudgetItem(
              categoryId: category.id,
              limit: amount,
              month: _selectedMonth.month,
              year: _selectedMonth.year,
            ),
          );
          Navigator.of(ctx).pop();
        },
        onDelete: () {
          _upsertBudget(
            BudgetItem(
              categoryId: category.id,
              limit: 0,
              month: _selectedMonth.month,
              year: _selectedMonth.year,
            ),
          );
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseCategories = CategoryItem.defaultCategories
        .where((c) => c.type == TransactionType.expense)
        .toList();

    double totalBudget = 0;
    double totalSpent = 0;
    for (final cat in expenseCategories) {
      final b = _getBudget(cat.id);
      if (b != null && b.limit > 0) totalBudget += b.limit;
      totalSpent += _getSpent(cat.id);
    }

    final monthLabel = AppLocalizations.isEn
        ? '${_enMonths[_selectedMonth.month - 1]} / ${_selectedMonth.year}'
        : 'Tháng ${_selectedMonth.month} / ${_selectedMonth.year}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('Ngân Sách Thông Minh', 'Smart Budget'),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            monthLabel,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildMonthBtn(
                      Icons.chevron_left_rounded,
                      () => _changeMonth(-1),
                    ),
                    const SizedBox(width: 8),
                    _buildMonthBtn(
                      Icons.chevron_right_rounded,
                      () => _changeMonth(1),
                    ),
                  ],
                ),
              ),
            ),
            if (totalBudget > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: _SummaryCard(
                    totalBudget: totalBudget,
                    totalSpent: totalSpent,
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final cat = expenseCategories[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BudgetCategoryCard(
                      category: cat,
                      budget: _getBudget(cat.id),
                      spent: _getSpent(cat.id),
                      onTap: () => _showBudgetDialog(cat),
                    ),
                  );
                }, childCount: expenseCategories.length),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 22, color: AppColors.textSecondary),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalBudget;
  final double totalSpent;
  const _SummaryCard({required this.totalBudget, required this.totalSpent});

  @override
  Widget build(BuildContext context) {
    final pct = totalBudget > 0
        ? (totalSpent / totalBudget).clamp(0.0, 1.0)
        : 0.0;
    final remaining = totalBudget - totalSpent;
    final isOver = totalSpent > totalBudget;
    final barColor = isOver
        ? Colors.white
        : (pct > 0.8 ? const Color(0xFF7C2D12) : AppColors.onPrimary);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isOver
            ? const LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.beeGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isOver ? const Color(0xFFDC2626) : AppColors.primary)
                .withValues(alpha: 0.35),
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
              Text(
                tr('Tổng ngân sách tháng', 'Monthly Budget Limit'),
                style: TextStyle(
                  color: isOver
                      ? Colors.white70
                      : AppColors.onPrimary.withValues(alpha: 0.75),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOver
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.onPrimary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${((totalSpent / (totalBudget > 0 ? totalBudget : 1)) * 100).toStringAsFixed(0)}% ${tr('đã dùng', 'used')}',
                  style: TextStyle(
                    color: isOver ? Colors.white : AppColors.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppFormatters.formatCurrency(totalBudget),
            style: TextStyle(
              color: isOver ? Colors.white : AppColors.onPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: isOver
                  ? Colors.white24
                  : AppColors.onPrimary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${tr('Đã chi', 'Spent')}: ${AppFormatters.formatCurrency(totalSpent)}',
                style: TextStyle(
                  color: isOver
                      ? Colors.white70
                      : AppColors.onPrimary.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                remaining >= 0
                    ? '${tr('Còn lại', 'Left')}: ${AppFormatters.formatCurrency(remaining)}'
                    : '${tr('Vượt', 'Over')}: ${AppFormatters.formatCurrency(-remaining)}',
                style: TextStyle(
                  color: isOver ? Colors.white : AppColors.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetCategoryCard extends StatelessWidget {
  final CategoryItem category;
  final BudgetItem? budget;
  final double spent;
  final VoidCallback onTap;

  const _BudgetCategoryCard({
    required this.category,
    required this.budget,
    required this.spent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLimit = budget != null && budget!.limit > 0;
    final limit = hasLimit ? budget!.limit : 0.0;
    final pct = hasLimit ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final isOver = hasLimit && spent > limit;

    final (barColor, statusBadge, badgeColor) = !hasLimit
        ? (
            AppColors.textMuted,
            tr('Chưa đặt', 'Not set'),
            AppColors.textSecondary,
          )
        : isOver
        ? (
            AppColors.expense,
            tr('Vượt hạn mức', 'Over budget'),
            AppColors.expense,
          )
        : pct > 0.8
        ? (
            AppColors.warning,
            tr('Sắp chạm trần', 'Near limit'),
            AppColors.warning,
          )
        : (AppColors.income, tr('An toàn', 'On track'), AppColors.income);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOver
                ? AppColors.expense.withValues(alpha: 0.5)
                : AppColors.border,
            width: isOver ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: AppColors.isDark ? 0.45 : 0.06,
              ),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(category.icon, color: category.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusBadge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!hasLimit)
                  OutlinedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(
                      Icons.add,
                      size: 14,
                      color: AppColors.primaryDark,
                    ),
                    label: Text(
                      tr('Đặt hạn mức', 'Set limit'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppFormatters.formatCurrency(limit),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        tr('hạn mức tháng', 'monthly limit'),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${tr('Đã chi', 'Spent')}: ${AppFormatters.formatCurrency(spent)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (hasLimit)
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: barColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: hasLimit ? pct : 0,
                minHeight: 7,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            if (isOver) ...[
              const SizedBox(height: 6),
              Text(
                tr(
                  'Vượt hạn mức ${AppFormatters.formatCurrency(spent - limit)}!',
                  'Exceeded limit by ${AppFormatters.formatCurrency(spent - limit)}!',
                ),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.expense,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BudgetDialog extends StatefulWidget {
  final CategoryItem category;
  final int month;
  final int year;
  final TextEditingController controller;
  final bool hasExisting;
  final void Function(double) onSave;
  final VoidCallback onDelete;

  const _BudgetDialog({
    required this.category,
    required this.month,
    required this.year,
    required this.controller,
    required this.hasExisting,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  String? _error;

  double? _parseAmount(String raw) {
    final s = raw.trim().toLowerCase().replaceAll(',', '').replaceAll('.', '');
    if (s.isEmpty) return null;

    final trMatch = RegExp(
      r'^(\d+(?:\.\d+)?)\s*(?:triệu|trieu|tr|m)$',
    ).firstMatch(s);
    if (trMatch != null) return double.tryParse(trMatch.group(1)!)! * 1000000;

    final kMatch = RegExp(r'^(\d+(?:\.\d+)?)\s*k$').firstMatch(s);
    if (kMatch != null) return double.tryParse(kMatch.group(1)!)! * 1000;

    return double.tryParse(s);
  }

  void _submit() {
    final amount = _parseAmount(widget.controller.text);
    if (amount == null || amount <= 0) {
      setState(() {
        _error = tr(
          'Vui lòng nhập số tiền hợp lệ',
          'Please enter a valid amount',
        );
      });
      return;
    }
    widget.onSave(amount);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: widget.category.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.category.icon,
              color: widget.category.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.category.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${tr('Tháng', 'Month')} ${widget.month} / ${widget.year}',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(
              'Nhập hạn mức chi tiêu cho danh mục này:',
              'Enter monthly spending limit for this category:',
            ),
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            autofocus: true,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: tr('VD: 2.000.000', 'e.g. 2.000.000'),
              errorText: _error,
              suffixText: '₫',
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [500000.0, 1000000.0, 2000000.0, 5000000.0].map((v) {
              final formatted = AppFormatters.formatNumber(v);
              return InkWell(
                onTap: () {
                  widget.controller.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                  if (_error != null) setState(() => _error = null);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    formatted,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        if (widget.hasExisting)
          TextButton(
            onPressed: widget.onDelete,
            child: Text(
              tr('Xóa hạn mức', 'Remove limit'),
              style: const TextStyle(
                color: AppColors.expense,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            tr('Hủy', 'Cancel'),
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(onPressed: _submit, child: Text(tr('Lưu', 'Save'))),
      ],
    );
  }
}
