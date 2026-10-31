import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/financial_advisor.dart';
import '../utils/app_localizations.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

class BeeMascotCard extends StatefulWidget {
  final List<TransactionRecord> transactions;
  final double totalIncome;
  final double totalExpense;

  const BeeMascotCard({
    super.key,
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  State<BeeMascotCard> createState() => _BeeMascotCardState();
}

class _BeeMascotCardState extends State<BeeMascotCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;
  int _tipIndex = 0;

  static const List<String> _viTips = [
    'Quy tắc 50/30/20: Dành 50% cho nhu cầu thiết yếu, 30% giải trí và 20% tiết kiệm mỗi tháng.',
    'Ghi lại mọi khoản chi dù nhỏ nhất để tránh thất thoát ngân sách hàng tháng.',
    'Đặt hạn mức ngân sách cho từng danh mục để chủ động kiểm soát chi tiêu.',
    'Trước khi mua món đồ không thiết yếu, hãy chờ 24 giờ trước khi quyết định.',
    'Tích lũy đều đặn mỗi tháng vào hũ mật tiết kiệm để sớm đạt mục tiêu.',
  ];

  static const List<String> _enTips = [
    '50/30/20 Rule: Allocate 50% to needs, 30% to wants, and 20% to savings every month.',
    'Track every expense, even the smallest ones, to avoid budget leaks.',
    'Set monthly budget limits for each category to stay in control of your spending.',
    'Before buying non-essentials, wait 24 hours before making a decision.',
    'Save consistently every month in your Honey Jar to reach your goals faster.',
  ];

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _bounceAnim = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  String get _currentTip {
    final tips = AppLocalizations.isEn ? _enTips : _viTips;
    if (widget.transactions.isNotEmpty) {
      final aiInsight = FinancialAdvisorService.instance.generateInsight(
        transactions: widget.transactions,
        totalIncome: widget.totalIncome,
        totalExpense: widget.totalExpense,
      );
      final allTips = [aiInsight, ...tips];
      return allTips[_tipIndex % allTips.length];
    }
    return tips[_tipIndex % tips.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.14),
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
              AnimatedBuilder(
                animation: _bounceAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _bounceAnim.value),
                  child: child,
                ),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Text('🐝', style: TextStyle(fontSize: 26)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Chú Ong Chi Tiêu', 'Smart Bee Advisor'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      tr(
                        'Mẹo thông minh cho bạn hôm nay',
                        'Smart financial tips for you today',
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _tipIndex++),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.primaryDark,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentTip,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildQuickChips(),
        ],
      ),
    );
  }

  Widget _buildQuickChips() {
    final chips = <(String, String)>[];

    if (widget.totalExpense > 0 && widget.totalIncome > 0) {
      final ratio = widget.totalExpense / widget.totalIncome;
      if (ratio > 0.8) {
        chips.add((
          '⚠️',
          tr(
            'Chi tiêu cao: ${(ratio * 100).toStringAsFixed(0)}% thu',
            'High spending: ${(ratio * 100).toStringAsFixed(0)}% of income',
          ),
        ));
      } else if (ratio < 0.5) {
        chips.add((
          '🌟',
          tr(
            'Tiết kiệm tốt: ${((1 - ratio) * 100).toStringAsFixed(0)}%',
            'Great savings: ${((1 - ratio) * 100).toStringAsFixed(0)}%',
          ),
        ));
      }
    }

    if (widget.transactions.isNotEmpty) {
      chips.add((
        '📊',
        tr(
          '${widget.transactions.length} giao dịch đã ghi',
          '${widget.transactions.length} transactions logged',
        ),
      ));
    }

    if (widget.totalExpense > 0) {
      chips.add((
        '💸',
        '${tr('Đã chi', 'Spent')}: ${AppFormatters.formatCurrency(widget.totalExpense)}',
      ));
    }

    if (chips.isEmpty) {
      chips.add(('🍯', tr('Chạm 🔄 để đổi mẹo', 'Tap 🔄 for next tip')));
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips.take(3).map((c) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(c.$1, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                c.$2,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
