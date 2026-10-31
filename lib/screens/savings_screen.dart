import 'package:flutter/material.dart';
import '../models/savings_goal.dart';
import '../utils/app_localizations.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

class SavingsScreen extends StatefulWidget {
  final List<SavingsGoal> goals;
  final Function(List<SavingsGoal>) onGoalsChanged;

  const SavingsScreen({
    super.key,
    required this.goals,
    required this.onGoalsChanged,
  });

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  late List<SavingsGoal> _goals;

  @override
  void initState() {
    super.initState();
    _goals = List.from(widget.goals);
  }

  @override
  void didUpdateWidget(covariant SavingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goals != widget.goals) {
      _goals = List.from(widget.goals);
    }
  }

  void _saveGoals(List<SavingsGoal> newGoals) {
    setState(() => _goals = newGoals);
    widget.onGoalsChanged(newGoals);
  }

  void _addGoal(SavingsGoal goal) {
    _saveGoals([goal, ..._goals]);
  }

  void _depositToGoal(SavingsGoal goal, double amount) {
    _saveGoals(
      _goals.map((g) {
        return g.id == goal.id
            ? g.copyWith(currentAmount: g.currentAmount + amount)
            : g;
      }).toList(),
    );
  }

  void _deleteGoal(SavingsGoal goal) {
    _saveGoals(_goals.where((g) => g.id != goal.id).toList());
  }

  void _openAddGoalModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddGoalModal(onSave: _addGoal),
    );
  }

  void _showDepositDialog(SavingsGoal goal) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: goal.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(goal.icon, color: goal.color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr(
                  'Tích lũy vào "${goal.title}"',
                  'Deposit into "${goal.title}"',
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
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
                'Nhập số tiền bạn muốn thêm vào mục tiêu này:',
                'Enter the amount you want to add to this goal:',
              ),
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              autofocus: true,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: tr('VD: 200.000', 'e.g. 200.000'),
                suffixText: '₫',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              tr('Hủy', 'Cancel'),
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final raw = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
              final amount = double.tryParse(raw);
              if (amount != null && amount > 0) {
                _depositToGoal(goal, amount);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      tr(
                        'Đã nạp +${AppFormatters.formatCurrency(amount)} vào hũ mật "${goal.title}"!',
                        'Added +${AppFormatters.formatCurrency(amount)} to "${goal.title}"!',
                      ),
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            child: Text(tr('Xác nhận', 'Confirm')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalTarget = 0;
    double totalSaved = 0;
    for (final g in _goals) {
      totalTarget += g.targetAmount;
      totalSaved += g.currentAmount;
    }
    final overallProgress = totalTarget > 0
        ? (totalSaved / totalTarget).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(tr('Hũ Mật Tiết Kiệm 🍯', 'Honey Jar Savings 🍯')),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _openAddGoalModal,
            icon: const Icon(
              Icons.add_circle_rounded,
              color: AppColors.primaryDark,
              size: 28,
            ),
            tooltip: tr('Thêm mục tiêu mới', 'Add new goal'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ tổng quan hũ mật
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.beeGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
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
                            Icons.savings_rounded,
                            color: AppColors.onPrimary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tr('Tổng hũ mật tích lũy', 'Total Saved Honey'),
                            style: TextStyle(
                              color: AppColors.onPrimary.withValues(
                                alpha: 0.78,
                              ),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
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
                          color: AppColors.onPrimary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(overallProgress * 100).toStringAsFixed(0)}% ${tr('Hoàn thành', 'Done')}',
                          style: const TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppFormatters.formatCurrency(totalSaved),
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tr('Mục tiêu tổng', 'Total target')}: ${AppFormatters.formatCurrency(totalTarget)} (${_goals.length} ${tr('mục tiêu', 'goals')})',
                    style: TextStyle(
                      color: AppColors.onPrimary.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: overallProgress,
                      minHeight: 8,
                      backgroundColor: AppColors.onPrimary.withValues(
                        alpha: 0.18,
                      ),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('Danh sách mục tiêu', 'Your Savings Goals'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _openAddGoalModal,
                  icon: const Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                  label: Text(
                    tr('Tạo mới', 'New Goal'),
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_goals.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flag_circle_rounded,
                        size: 48,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr(
                        'Chưa có mục tiêu tiết kiệm nào',
                        'No savings goals yet',
                      ),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(
                        'Đặt mục tiêu như mua xe, điện thoại mới hoặc quỹ khẩn cấp để có động lực tích lũy mỗi ngày!',
                        'Create goals like a new phone, vacation, or emergency fund to stay motivated every day!',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _openAddGoalModal,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        tr('Tạo mục tiêu đầu tiên', 'Create First Goal'),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._goals.map(_buildGoalCard),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(SavingsGoal goal) {
    final isDone = goal.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDone ? AppColors.income : AppColors.border,
          width: isDone ? 1.8 : 1.2,
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: goal.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(goal.icon, color: goal.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            goal.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isDone) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.incomeLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tr('Đạt mục tiêu 🎉', 'Completed 🎉'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.income,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      goal.deadline != null
                          ? '${tr('Hạn chót', 'Deadline')}: ${goal.deadline!.day}/${goal.deadline!.month}/${goal.deadline!.year}'
                          : tr('Mục tiêu linh hoạt', 'Flexible deadline'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
                onSelected: (val) {
                  if (val == 'deposit') _showDepositDialog(goal);
                  if (val == 'delete') _deleteGoal(goal);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'deposit',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.primaryDark,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tr('Nạp thêm tiền', 'Add funds'),
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.expense,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tr('Xóa mục tiêu', 'Delete goal'),
                          style: const TextStyle(color: AppColors.expense),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Đã tiết kiệm được', 'Saved so far'),
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.formatCurrency(goal.currentAmount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDone ? AppColors.income : AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    tr('Mục tiêu', 'Target'),
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.formatCurrency(goal.targetAmount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone ? AppColors.income : goal.color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isDone
                      ? tr(
                          'Đã hoàn thành xuất sắc!',
                          'Goal completed! Awesome job!',
                        )
                      : '${tr('Còn thiếu', 'Remaining')}: ${AppFormatters.formatCurrency(goal.remainingAmount)} (${(goal.progress * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDone ? AppColors.income : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showDepositDialog(goal),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: goal.color, width: 1.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: goal.color),
                      const SizedBox(width: 4),
                      Text(
                        tr('Tích lũy thêm', 'Add funds'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: goal.color,
                        ),
                      ),
                    ],
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

class _AddGoalModal extends StatefulWidget {
  final Function(SavingsGoal) onSave;
  const _AddGoalModal({required this.onSave});

  @override
  State<_AddGoalModal> createState() => _AddGoalModalState();
}

class _AddGoalModalState extends State<_AddGoalModal> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _deadline;
  int _selectedColor = 0xFFF59E0B;
  int _selectedIcon = 0xe59c;

  static const _colors = [
    0xFFF59E0B,
    0xFFD97706,
    0xFF10B981,
    0xFF3B82F6,
    0xFFEC4899,
    0xFF6366F1,
    0xFF8B5CF6,
  ];

  static const _icons = [
    Icons.savings_rounded,
    Icons.flight_takeoff_rounded,
    Icons.laptop_chromebook_rounded,
    Icons.directions_car_rounded,
    Icons.home_rounded,
    Icons.card_giftcard_rounded,
    Icons.phone_iphone_rounded,
    Icons.shopping_bag_rounded,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  void _submit() {
    final title = _titleController.text.trim();
    final rawAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final target = double.tryParse(rawAmount);

    if (title.isEmpty || target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'Vui lòng nhập đầy đủ tên và số tiền mục tiêu!',
              'Please enter a valid goal name and target amount!',
            ),
          ),
        ),
      );
      return;
    }

    widget.onSave(
      SavingsGoal(
        id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        targetAmount: target,
        deadline: _deadline,
        colorValue: _selectedColor,
        iconCode: _selectedIcon,
        createdAt: DateTime.now(),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
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
            const SizedBox(height: 16),
            Text(
              tr('Tạo mục tiêu tiết kiệm mới', 'Create New Savings Goal'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: tr('Tên mục tiêu', 'Goal Name'),
                hintText: tr(
                  'VD: Mua iPhone, Du lịch, Mua xe...',
                  'e.g. New iPhone, Trip, Emergency Fund...',
                ),
                prefixIcon: Icon(
                  Icons.flag_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(_selectedColor),
              ),
              decoration: InputDecoration(
                labelText: tr('Số tiền mục tiêu (VNĐ)', 'Target Amount (VND)'),
                hintText: '10.000.000',
                prefixIcon: Icon(
                  Icons.monetization_on_rounded,
                  color: AppColors.textSecondary,
                ),
                suffixText: '₫',
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDeadline,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _deadline != null
                          ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                          : tr(
                              'Chọn ngày hoàn thành (Tùy chọn)',
                              'Select target date (Optional)',
                            ),
                      style: TextStyle(
                        fontSize: 14,
                        color: _deadline != null
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.primaryDark,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr('Chọn biểu tượng & Màu sắc', 'Choose Icon & Color'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _icons.map((icon) {
                  final isSelected = _selectedIcon == icon.codePoint;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon.codePoint),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(_selectedColor).withValues(alpha: 0.2)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? Color(_selectedColor)
                              : AppColors.border,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                            ? Color(_selectedColor)
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _colors.map((c) {
                  final isSelected = _selectedColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: AppColors.textPrimary, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  tr('Bắt đầu tích lũy mục tiêu', 'Start Saving for This Goal'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
