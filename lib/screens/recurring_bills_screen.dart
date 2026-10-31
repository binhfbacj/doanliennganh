import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/recurring_bill.dart';
import '../models/transaction.dart';
import '../utils/app_localizations.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

class RecurringBillsScreen extends StatefulWidget {
  final List<RecurringBill> bills;
  final void Function(List<RecurringBill>) onBillsChanged;
  final void Function(TransactionRecord) onTransactionAdded;

  const RecurringBillsScreen({
    super.key,
    required this.bills,
    required this.onBillsChanged,
    required this.onTransactionAdded,
  });

  @override
  State<RecurringBillsScreen> createState() => _RecurringBillsScreenState();
}

class _RecurringBillsScreenState extends State<RecurringBillsScreen> {
  late List<RecurringBill> _bills;

  @override
  void initState() {
    super.initState();
    _bills = List.from(widget.bills);
  }

  @override
  void didUpdateWidget(RecurringBillsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bills != widget.bills) _bills = List.from(widget.bills);
  }

  void _save(List<RecurringBill> updated) {
    updated.sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
    setState(() => _bills = updated);
    widget.onBillsChanged(updated);
  }

  void _addOrUpdateBill(RecurringBill bill) {
    final list = List<RecurringBill>.from(_bills);
    final idx = list.indexWhere((b) => b.id == bill.id);
    if (idx != -1) {
      list[idx] = bill;
    } else {
      list.add(bill);
    }
    _save(list);
  }

  void _deleteBill(RecurringBill bill) {
    _save(_bills.where((b) => b.id != bill.id).toList());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            'Đã xóa khoản định kỳ "${bill.title}"',
            'Deleted recurring item "${bill.title}"',
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _logBillNow(RecurringBill bill) {
    final now = DateTime.now();
    widget.onTransactionAdded(
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
    _addOrUpdateBill(
      bill.copyWith(lastPaidMonth: now.month, lastPaidYear: now.year),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            '🐝 Đã ghi nhận "${bill.title}" (${AppFormatters.formatCurrency(bill.amount)}) vào sổ giao dịch!',
            '🐝 Logged "${bill.title}" (${AppFormatters.formatCurrency(bill.amount)}) to transactions!',
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

  void _openBillSheet({RecurringBill? initialBill}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEditRecurringBillSheet(
        initialBill: initialBill,
        onSave: _addOrUpdateBill,
      ),
    );
  }

  void _addPreset({
    required String titleVi,
    required String titleEn,
    required double amount,
    required TransactionType type,
    required String categoryId,
    required int dayOfMonth,
  }) {
    _openBillSheet(
      initialBill: RecurringBill(
        id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
        title: tr(titleVi, titleEn),
        amount: amount,
        type: type,
        categoryId: categoryId,
        dayOfMonth: dayOfMonth,
        isActive: true,
        autoAdd: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    double monthlyFixedExpense = 0, monthlyFixedIncome = 0;
    int paidCount = 0, activeCount = 0;

    for (final b in _bills) {
      if (!b.isActive) continue;
      activeCount++;
      if (b.type == TransactionType.expense) {
        monthlyFixedExpense += b.amount;
      } else {
        monthlyFixedIncome += b.amount;
      }
      if (b.isPaidForMonth(now)) paidCount++;
    }

    final presets = [
      (
        '🏠',
        tr('Tiền thuê nhà', 'House Rent'),
        'Tiền thuê nhà',
        'House Rent',
        3000000.0,
        TransactionType.expense,
        'bills',
        5,
      ),
      (
        '⚡',
        tr('Tiền điện nước', 'Electricity & Water'),
        'Tiền điện nước',
        'Electricity & Water',
        600000.0,
        TransactionType.expense,
        'bills',
        10,
      ),
      (
        '🌐',
        tr('Internet / Wifi', 'Internet / Wifi'),
        'Tiền Internet / Wifi',
        'Internet / Wifi Bill',
        250000.0,
        TransactionType.expense,
        'bills',
        15,
      ),
      (
        '🎬',
        'Netflix / Spotify',
        'Gói Netflix / Spotify',
        'Netflix / Spotify Subscription',
        180000.0,
        TransactionType.expense,
        'entertainment',
        20,
      ),
      (
        '💰',
        tr('Lương hàng tháng', 'Monthly Salary'),
        'Lương hàng tháng',
        'Monthly Salary',
        12000000.0,
        TransactionType.income,
        'salary',
        5,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            const Text('🔁', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              tr('Hoá Đơn & Định Kỳ', 'Recurring Bills & Income'),
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _openBillSheet(),
              icon: const Icon(
                Icons.add_circle_rounded,
                color: AppColors.primaryDark,
                size: 18,
              ),
              label: Text(
                tr('Thêm mới', 'Add New'),
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  width: 1.4,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr(
                          'Tổng quan định kỳ tháng ${now.month}/${now.year}',
                          'Monthly Recurring (${now.month}/${now.year})',
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tr(
                            'Đã ghi nhận $paidCount/$activeCount khoản',
                            'Logged $paidCount/$activeCount items',
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryMetricBox(
                          label: tr(
                            'Chi cố định / tháng',
                            'Fixed Expense / mo',
                          ),
                          amount: monthlyFixedExpense,
                          color: AppColors.expense,
                          icon: Icons.arrow_upward_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryMetricBox(
                          label: tr('Thu cố định / tháng', 'Fixed Income / mo'),
                          amount: monthlyFixedIncome,
                          color: AppColors.income,
                          icon: Icons.arrow_downward_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              tr('Gợi ý tạo nhanh (1 chạm)', 'Quick Templates (1-Tap)'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final p in presets)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => _addPreset(
                          titleVi: p.$3,
                          titleEn: p.$4,
                          amount: p.$5,
                          type: p.$6,
                          categoryId: p.$7,
                          dayOfMonth: p.$8,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(p.$1, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                p.$2,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              tr('Danh sách khoản định kỳ', 'Recurring Items List'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (_bills.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
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
                        color: AppColors.primary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.event_repeat_rounded,
                        size: 40,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      tr(
                        'Chưa có hoá đơn định kỳ nào',
                        'No recurring bills yet',
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr(
                        'Thêm tiền nhà, tiền điện, lương cố định... để Chú Ong tự động nhắc nhở hoặc ghi sổ mỗi tháng!',
                        'Add rent, utilities, or salary so Smart Bee can remind or auto-log them every month!',
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
              )
            else
              for (final bill in _bills) _buildBillCard(bill, now),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBillSheet(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          tr('Thêm khoản định kỳ', 'Add Recurring Item'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildSummaryMetricBox({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppFormatters.formatCurrency(amount),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(RecurringBill bill, DateTime now) {
    final cat = bill.category;
    final isPaid = bill.isPaidForMonth(now);
    final daysLeft = bill.daysUntilDue(now);
    final isIncome = bill.type == TransactionType.income;

    final (String statusText, Color statusColor) = switch ((isPaid, daysLeft)) {
      (true, _) => (
        tr('Đã ghi nhận tháng ${now.month}', 'Logged for month ${now.month}'),
        AppColors.income,
      ),
      (false, 0) => (tr('Đến hạn hôm nay!', 'Due today!'), AppColors.expense),
      (false, < 0) => (
        tr(
          'Đã quá hạn ${-daysLeft} ngày (Ngày ${bill.dayOfMonth})',
          'Overdue by ${-daysLeft}d (Day ${bill.dayOfMonth})',
        ),
        AppColors.expense,
      ),
      (false, <= 3) => (
        tr(
          'Ngày ${bill.dayOfMonth} hàng tháng (còn $daysLeft ngày)',
          'Day ${bill.dayOfMonth} monthly ($daysLeft days left)',
        ),
        AppColors.primaryDark,
      ),
      _ => (
        tr(
          'Ngày ${bill.dayOfMonth} hàng tháng (còn $daysLeft ngày)',
          'Day ${bill.dayOfMonth} monthly ($daysLeft days left)',
        ),
        AppColors.textSecondary,
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (!isPaid && daysLeft <= 3)
              ? AppColors.primary.withValues(alpha: 0.7)
              : AppColors.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark ? 0.35 : 0.05,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(cat.icon, color: cat.color, size: 24),
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
                            bill.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (bill.autoAdd) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tr('⚡ Tự động', '⚡ Auto'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}${AppFormatters.formatCurrency(bill.amount)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isIncome ? AppColors.income : AppColors.expense,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _openBillSheet(initialBill: bill),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _deleteBill(bill),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.expense.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cat.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cat.color,
                ),
              ),
              if (isPaid)
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppColors.income,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tr('Đã hoàn tất tháng này', 'Completed'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.income,
                      ),
                    ),
                  ],
                )
              else
                InkWell(
                  onTap: () => _logBillNow(bill),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.beeGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 15,
                          color: AppColors.onPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tr('Ghi nhận tháng này', 'Log for This Month'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onPrimary,
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

class _AddEditRecurringBillSheet extends StatefulWidget {
  final RecurringBill? initialBill;
  final void Function(RecurringBill) onSave;

  const _AddEditRecurringBillSheet({this.initialBill, required this.onSave});

  @override
  State<_AddEditRecurringBillSheet> createState() =>
      _AddEditRecurringBillSheetState();
}

class _AddEditRecurringBillSheetState
    extends State<_AddEditRecurringBillSheet> {
  late TransactionType _type;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late String _categoryId;
  late int _dayOfMonth;
  late bool _autoAdd;

  @override
  void initState() {
    super.initState();
    final init = widget.initialBill;
    _type = init?.type ?? TransactionType.expense;
    _titleController = TextEditingController(text: init?.title ?? '');
    _amountController = TextEditingController(
      text: init != null ? AppFormatters.formatNumber(init.amount) : '',
    );
    _categoryId = init?.categoryId ?? 'bills';
    _dayOfMonth = init?.dayOfMonth ?? 5;
    _autoAdd = init?.autoAdd ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(
      _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('Vui lòng nhập số tiền hợp lệ!', 'Please enter a valid amount!'),
          ),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : CategoryItem.findById(_categoryId).name;

    final bill =
        (widget.initialBill ??
                RecurringBill(
                  id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
                  title: title,
                  amount: amount,
                  type: _type,
                  categoryId: _categoryId,
                  dayOfMonth: _dayOfMonth,
                ))
            .copyWith(
              title: title,
              amount: amount,
              type: _type,
              categoryId: _categoryId,
              dayOfMonth: _dayOfMonth,
              autoAdd: _autoAdd,
            );

    widget.onSave(bill);
    Navigator.of(context).pop();
  }

  Widget _buildTypeTab(
    TransactionType type,
    String label,
    Color activeColor,
    String defaultCat,
  ) {
    final active = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = type;
          _categoryId = defaultCat;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = CategoryItem.defaultCategories
        .where((c) => c.type == _type)
        .toList();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
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
            const SizedBox(height: 14),
            Text(
              widget.initialBill != null
                  ? tr('Thiết lập khoản định kỳ', 'Configure Recurring Item')
                  : tr('Thêm khoản định kỳ mới', 'New Recurring Item'),
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _buildTypeTab(
                    TransactionType.expense,
                    tr('Hoá đơn / Chi (-)', 'Recurring Expense (-)'),
                    AppColors.expense,
                    'bills',
                  ),
                  _buildTypeTab(
                    TransactionType.income,
                    tr('Thu nhập cố định (+)', 'Recurring Income (+)'),
                    AppColors.income,
                    'salary',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: tr('Tên khoản định kỳ', 'Item Name'),
                hintText: tr(
                  'VD: Tiền nhà, Tiền điện, Lương...',
                  'e.g. Rent, Electricity, Salary...',
                ),
                prefixIcon: Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: tr(
                  'Số tiền hàng tháng (VNĐ)',
                  'Monthly Amount (VND)',
                ),
                suffixText: '₫',
                prefixIcon: Icon(
                  Icons.payments_outlined,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              tr('Danh mục', 'Category'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, index) {
                  final cat = categories[index];
                  final isSelected = cat.id == _categoryId;
                  return GestureDetector(
                    onTap: () => setState(() => _categoryId = cat.id),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cat.color
                                : cat.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            cat.icon,
                            color: isSelected ? Colors.white : cat.color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: isSelected
                                ? cat.color
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('Ngày thanh toán hàng tháng:', 'Monthly Due Day:'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _dayOfMonth,
                      dropdownColor: AppColors.surface,
                      items: List.generate(31, (i) => i + 1)
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(
                                tr('Ngày $d', 'Day $d'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _dayOfMonth = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
              title: Text(
                tr(
                  'Tự động ghi vào sổ khi đến ngày',
                  'Auto-log transaction on due date',
                ),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                tr(
                  'Tự tạo giao dịch khi mở ứng dụng vào hoặc sau ngày hạn',
                  'Automatically adds transaction when app opens on/after due day',
                ),
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              value: _autoAdd,
              onChanged: (val) => setState(() => _autoAdd = val),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.onPrimary,
                ),
                label: Text(
                  tr('Lưu khoản định kỳ', 'Save Recurring Item'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onPrimary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
