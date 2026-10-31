import 'dart:math';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../utils/app_localizations.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

class ExpenseWeeklyChart extends StatelessWidget {
  final List<TransactionRecord> transactions;

  const ExpenseWeeklyChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = <_DayData>[];
    double maxExpense = 0;

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final sum = transactions
          .where(
            (t) =>
                t.type == TransactionType.expense &&
                t.dateTime.year == date.year &&
                t.dateTime.month == date.month &&
                t.dateTime.day == date.day,
          )
          .fold(0.0, (s, t) => s + t.amount);

      if (sum > maxExpense) maxExpense = sum;

      final label = switch (i) {
        0 => tr('H.nay', 'Today'),
        1 => tr('H.qua', 'Yest'),
        _ => _weekdayLabel(date.weekday),
      };
      days.add(
        _DayData(label: label, amount: sum, isToday: i == 0, date: date),
      );
    }

    if (maxExpense == 0) maxExpense = 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.2),
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
                    Icons.bar_chart_rounded,
                    color: AppColors.primaryDark,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr('Chi tiêu 7 ngày qua', 'Last 7 Days Spending'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${tr('Tối đa', 'Max')}: ${AppFormatters.formatCurrency(maxExpense == 1 ? 0 : maxExpense)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 164,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final ratio = min(1.0, day.amount / maxExpense);
                final barHeight = max(8.0, 96 * ratio);
                final fg = day.isToday
                    ? AppColors.primaryDark
                    : AppColors.textMuted;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (day.amount > 0)
                      Text(
                        _formatCompact(day.amount),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: fg,
                        ),
                      )
                    else
                      const SizedBox(height: 12),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 28,
                      height: barHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: day.isToday
                              ? [AppColors.primaryDark, AppColors.primary]
                              : day.amount > 0
                              ? [
                                  AppColors.primaryDark.withValues(alpha: 0.65),
                                  AppColors.primary.withValues(alpha: 0.75),
                                ]
                              : [AppColors.border, AppColors.border],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      day.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: day.isToday
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: day.isToday
                            ? AppColors.primaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${day.date.day}/${day.date.month}',
                      style: TextStyle(
                        fontSize: 9,
                        color: fg,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompact(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}k';
    return amount.toStringAsFixed(0);
  }

  String _weekdayLabel(int weekday) {
    const enLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const viLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final idx = (weekday - 1).clamp(0, 6);
    return AppLocalizations.isEn ? enLabels[idx] : viLabels[idx];
  }
}

class _DayData {
  final String label;
  final double amount;
  final bool isToday;
  final DateTime date;

  _DayData({
    required this.label,
    required this.amount,
    required this.isToday,
    required this.date,
  });
}
