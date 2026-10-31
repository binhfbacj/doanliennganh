import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../utils/app_localizations.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/donut_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  final List<TransactionRecord> transactions;

  const AnalyticsScreen({super.key, required this.transactions});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 0;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final filtered = widget.transactions.where((t) {
      if (_selectedPeriod == 0) {
        return t.dateTime.year == now.year && t.dateTime.month == now.month;
      } else if (_selectedPeriod == 1) {
        final startOfToday = DateTime(now.year, now.month, now.day);
        final startOf7DaysAgo = startOfToday.subtract(const Duration(days: 6));
        final txDate = DateTime(
          t.dateTime.year,
          t.dateTime.month,
          t.dateTime.day,
        );
        return !txDate.isBefore(startOf7DaysAgo) &&
            !txDate.isAfter(startOfToday);
      } else if (_selectedPeriod == 2) {
        final prevMonth = DateTime(now.year, now.month - 1);
        return t.dateTime.year == prevMonth.year &&
            t.dateTime.month == prevMonth.month;
      }
      return true;
    }).toList();

    double totalIncome = 0;
    double totalExpense = 0;
    final categoryExpenseMap = <String, double>{};
    final categoryCountMap = <String, int>{};

    for (final tx in filtered) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
        categoryExpenseMap[tx.categoryId] =
            (categoryExpenseMap[tx.categoryId] ?? 0) + tx.amount;
        categoryCountMap[tx.categoryId] =
            (categoryCountMap[tx.categoryId] ?? 0) + 1;
      }
    }

    final sortedCategories = categoryExpenseMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final donutItems = sortedCategories.map((entry) {
      return DonutChartItem(
        category: CategoryItem.findById(entry.key),
        amount: entry.value,
        percentage: totalExpense > 0 ? (entry.value / totalExpense) : 0.0,
      );
    }).toList();

    final netSavings = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0
        ? ((netSavings / totalIncome) * 100).clamp(-100.0, 100.0)
        : 0.0;

    int dayCount = 1;
    if (_selectedPeriod == 0) {
      dayCount = now.day;
    } else if (_selectedPeriod == 1) {
      dayCount = 7;
    } else if (_selectedPeriod == 2) {
      dayCount = DateTime(now.year, now.month, 0).day;
    } else if (filtered.isNotEmpty) {
      final oldest = filtered
          .map((e) => e.dateTime)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      dayCount = (now.difference(oldest).inDays + 1).clamp(1, 3650);
    }
    final avgDailyExpense = totalExpense / dayCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(tr('Báo Cáo & Phân Tích', 'Reports & Analytics')),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => _exportReport(
              totalIncome: totalIncome,
              totalExpense: totalExpense,
              netSavings: netSavings,
              sortedCategories: sortedCategories,
            ),
            icon: const Icon(Icons.share_rounded, color: AppColors.primaryDark),
            tooltip: tr('Xuất tóm tắt báo cáo', 'Export report summary'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1.2),
              ),
              child: Row(
                children: [
                  _buildPeriodTab(0, tr('Tháng này', 'This Month')),
                  _buildPeriodTab(1, tr('7 ngày qua', 'Last 7 Days')),
                  _buildPeriodTab(2, tr('Tháng trước', 'Last Month')),
                  _buildPeriodTab(3, tr('Tất cả', 'All Time')),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Thẻ tổng hợp thu chi
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildAmountColumn(
                        tr('Tổng thu vào', 'Total Income'),
                        totalIncome,
                        AppColors.income,
                        CrossAxisAlignment.start,
                      ),
                      Container(height: 38, width: 1, color: AppColors.border),
                      _buildAmountColumn(
                        tr('Tổng đã chi', 'Total Expense'),
                        totalExpense,
                        AppColors.expense,
                        CrossAxisAlignment.end,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 10,
                      child: totalIncome + totalExpense == 0
                          ? Container(color: AppColors.border)
                          : Row(
                              children: [
                                Expanded(
                                  flex: (totalIncome * 100).toInt().clamp(
                                    1,
                                    1000000,
                                  ),
                                  child: Container(color: AppColors.income),
                                ),
                                Expanded(
                                  flex: (totalExpense * 100).toInt().clamp(
                                    1,
                                    1000000,
                                  ),
                                  child: Container(color: AppColors.expense),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: AppColors.border),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            netSavings >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 18,
                            color: netSavings >= 0
                                ? AppColors.income
                                : AppColors.expense,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            netSavings >= 0
                                ? tr('Tích lũy ròng:', 'Net savings:')
                                : tr('Thâm hụt ròng:', 'Net deficit:'),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${netSavings >= 0 ? '+' : ''}${AppFormatters.formatCurrency(netSavings)} (${savingsRate.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: netSavings >= 0
                              ? AppColors.income
                              : AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr('Chi tiêu trung bình:', 'Average daily spending:'),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '~${AppFormatters.formatCurrency(avgDailyExpense)}${tr('/ngày', '/day')}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Biểu đồ tròn
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Biểu đồ phân bổ chi tiêu', 'Expense Breakdown Chart'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DonutChart(items: donutItems, totalAmount: totalExpense),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Nhận xét chi tiêu
            if (sortedCategories.isNotEmpty && totalExpense > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lightbulb_rounded,
                        color: AppColors.primaryDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(
                              '🐝 Phân tích chi tiêu thông minh',
                              '🐝 Smart Bee Spending Insight',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tr(
                              'Danh mục "${CategoryItem.findById(sortedCategories.first.key).name}" đang chiếm tỉ trọng lớn nhất với ${((sortedCategories.first.value / totalExpense) * 100).toStringAsFixed(0)}% (${AppFormatters.formatCurrency(sortedCategories.first.value)}).',
                              '"${CategoryItem.findById(sortedCategories.first.key).name}" accounts for the largest share at ${((sortedCategories.first.value / totalExpense) * 100).toStringAsFixed(0)}% (${AppFormatters.formatCurrency(sortedCategories.first.value)}).',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
            ],

            Text(
              tr('Chi tiết danh mục chi tiêu', 'Category Expense Details'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            if (sortedCategories.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    tr(
                      'Chưa có dữ liệu chi tiêu trong kỳ này.',
                      'No expense records for this period.',
                    ),
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...sortedCategories.map((entry) {
                final cat = CategoryItem.findById(entry.key);
                final amount = entry.value;
                final percentage = totalExpense > 0
                    ? (amount / totalExpense)
                    : 0.0;
                final count = categoryCountMap[entry.key] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(radius: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(cat.icon, color: cat.color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '$count ${tr('giao dịch', 'txs')} • ${(percentage * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            AppFormatters.formatCurrency(amount),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                          minHeight: 7,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 24}) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.border, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: AppColors.isDark ? 0.45 : 0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildAmountColumn(
    String label,
    double amount,
    Color color,
    CrossAxisAlignment align,
  ) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppFormatters.formatCurrency(amount),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodTab(int index, String title) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? AppColors.onPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _exportReport({
    required double totalIncome,
    required double totalExpense,
    required double netSavings,
    required List<MapEntry<String, double>> sortedCategories,
  }) {
    final buffer = StringBuffer()
      ..writeln(
        tr(
          '📊 BÁO CÁO CHI TIÊU THÔNG MINH 🐝',
          '📊 SMART BEE EXPENSE REPORT 🐝',
        ),
      )
      ..writeln('-----------------------------------')
      ..writeln(
        '• ${tr('Tổng thu vào', 'Total Income')}: ${AppFormatters.formatCurrency(totalIncome)}',
      )
      ..writeln(
        '• ${tr('Tổng đã chi', 'Total Expense')}:  ${AppFormatters.formatCurrency(totalExpense)}',
      )
      ..writeln(
        '• ${tr('Tiết kiệm ròng', 'Net Savings')}: ${AppFormatters.formatCurrency(netSavings)}',
      )
      ..writeln('-----------------------------------')
      ..writeln(tr('CƠ CẤU CHI TIÊU:', 'EXPENSE BREAKDOWN:'));

    for (final entry in sortedCategories) {
      final cat = CategoryItem.findById(entry.key);
      final pct = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0;
      buffer.writeln(
        ' - ${cat.name}: ${AppFormatters.formatCurrency(entry.value)} (${pct.toStringAsFixed(1)}%)',
      );
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tr('Đã sao chép báo cáo!', 'Report copied!'),
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: Text(
          tr(
            'Nội dung tóm tắt báo cáo tài chính đã được sao chép vào bộ nhớ tạm:\n\n$buffer',
            'Financial report summary has been copied to your clipboard:\n\n$buffer',
          ),
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr('Đóng', 'Close')),
          ),
        ],
      ),
    );
  }
}
