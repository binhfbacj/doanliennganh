import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

class BalanceCard extends StatefulWidget {
  final double totalIncome;
  final double totalExpense;
  final double balance;

  const BalanceCard({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _hideAmount = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDE047), Color(0xFFFBBF24), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.onPrimary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('🐝', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      tr('Tổng số dư hũ mật', 'Total Honey Balance'),
                      style: TextStyle(
                        color: AppColors.onPrimary.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => setState(() => _hideAmount = !_hideAmount),
                  icon: Icon(
                    _hideAmount
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.onPrimary.withValues(alpha: 0.75),
                    size: 20,
                  ),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _hideAmount
                  ? '•••••••• ₫'
                  : AppFormatters.formatCurrency(widget.balance),
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.onPrimary.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      label: tr('Thu nhập', 'Income'),
                      amount: widget.totalIncome,
                      prefix: '+',
                      icon: Icons.arrow_downward_rounded,
                      color: const Color(0xFF34D399),
                      bgColor: AppColors.income,
                    ),
                  ),
                  Container(
                    height: 32,
                    width: 1,
                    color: AppColors.darkBorder,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      label: tr('Chi tiêu', 'Expense'),
                      amount: widget.totalExpense,
                      prefix: '-',
                      icon: Icons.arrow_upward_rounded,
                      color: const Color(0xFFF87171),
                      bgColor: AppColors.expense,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required double amount,
    required String prefix,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _hideAmount
                    ? '••••••'
                    : '$prefix${AppFormatters.formatCurrency(amount)}',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
