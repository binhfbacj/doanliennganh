import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../utils/app_localizations.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

class AddTransactionModal extends StatefulWidget {
  final Function(TransactionRecord transaction) onSave;
  final TransactionRecord? initialTransaction;

  const AddTransactionModal({
    super.key,
    required this.onSave,
    this.initialTransaction,
  });

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  late TransactionType _type;
  late TextEditingController _amountController;
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  late String _selectedCategoryId;
  late DateTime _selectedDate;

  bool get _isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final init = widget.initialTransaction;
    _type = init?.type ?? TransactionType.expense;
    _amountController = TextEditingController(
      text: init != null ? AppFormatters.formatNumber(init.amount) : '',
    );
    _titleController = TextEditingController(text: init?.title ?? '');
    _noteController = TextEditingController(text: init?.note ?? '');
    _selectedCategoryId = init?.categoryId ?? 'food';
    _selectedDate = init?.dateTime ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _type = type;
      _selectedCategoryId = type == TransactionType.expense ? 'food' : 'salary';
    });
  }

  void _quickAddAmount(double add) {
    final current = AppFormatters.parseAmount(_amountController.text) ?? 0;
    final formatted = AppFormatters.formatNumber(current + add);
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  bool _isToday(DateTime date) => _isSameDay(date, DateTime.now());
  bool _isYesterday(DateTime date) =>
      _isSameDay(date, DateTime.now().subtract(const Duration(days: 1)));

  void _setDayPreservingTime(DateTime day) {
    setState(() {
      _selectedDate = DateTime(
        day.year,
        day.month,
        day.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) _setDayPreservingTime(picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _submit() {
    final amount = AppFormatters.parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'Vui lòng nhập số tiền hợp lệ lớn hơn 0!',
              'Please enter a valid amount greater than 0!',
            ),
          ),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : CategoryItem.findById(_selectedCategoryId).name;
    final note = _noteController.text.trim().isNotEmpty
        ? _noteController.text.trim()
        : null;

    final resultTx = _isEditing
        ? widget.initialTransaction!.copyWith(
            title: title,
            amount: amount,
            type: _type,
            categoryId: _selectedCategoryId,
            dateTime: _selectedDate,
            note: note,
            clearNote: note == null,
          )
        : TransactionRecord(
            id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
            title: title,
            amount: amount,
            type: _type,
            categoryId: _selectedCategoryId,
            dateTime: _selectedDate,
            note: note,
            isVoiceInput: false,
          );

    widget.onSave(resultTx);
    Navigator.of(context).pop();
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final categories = CategoryItem.defaultCategories
        .where((c) => c.type == _type)
        .toList();
    final isExpense = _type == TransactionType.expense;
    final typeColor = isExpense ? AppColors.expense : AppColors.income;
    final isOtherDate =
        !_isToday(_selectedDate) && !_isYesterday(_selectedDate);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isEditing
                            ? Icons.edit_note_rounded
                            : Icons.add_circle_outline_rounded,
                        color: typeColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isEditing
                          ? tr('Chỉnh sửa giao dịch', 'Edit Transaction')
                          : tr('Thêm giao dịch mới', 'New Transaction'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _buildTypeTab(
                    TransactionType.expense,
                    tr('Chi tiêu (-)', 'Expense (-)'),
                    AppColors.expense,
                  ),
                  _buildTypeTab(
                    TransactionType.income,
                    tr('Thu nhập (+)', 'Income (+)'),
                    AppColors.income,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sectionLabel(tr('Số tiền (VNĐ)', 'Amount (VND)')),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: typeColor,
              ),
              decoration: InputDecoration(
                prefixText: isExpense ? '- ' : '+ ',
                prefixStyle: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: typeColor,
                ),
                suffixText: '₫',
                suffixStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
                hintText: '0',
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final v in [
                    10000.0,
                    50000.0,
                    100000.0,
                    500000.0,
                    1000000.0,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => _quickAddAmount(v),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            '+${AppFormatters.formatNumber(v)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sectionLabel(tr('Danh mục', 'Category')),
            const SizedBox(height: 10),
            SizedBox(
              height: 94,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, index) {
                  final cat = categories[index];
                  final isSelected = cat.id == _selectedCategoryId;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryId = cat.id),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cat.color
                                : cat.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? cat.color
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: cat.color.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            cat.icon,
                            color: isSelected ? Colors.white : cat.color,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 12,
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
            const SizedBox(height: 14),
            _sectionLabel(tr('Tiêu đề / Tên giao dịch', 'Title / Description')),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: tr(
                  'Ví dụ: Ăn phở bò, Mua quà, Tiền điện...',
                  'e.g. Pho lunch, Coffee, Electricity bill...',
                ),
                prefixIcon: Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _sectionLabel(tr('Ghi chú (Tùy chọn)', 'Note (Optional)')),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: tr(
                  'Thêm địa điểm, chi tiết chi tiêu...',
                  'Add location or extra details...',
                ),
                prefixIcon: Icon(
                  Icons.notes_rounded,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionLabel(
                  tr('Ngày & Giờ giao dịch', 'Transaction Date & Time'),
                ),
                InkWell(
                  onTap: _pickTime,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppFormatters.formatTime(_selectedDate),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildDateQuickChip(
                    label: tr('Hôm nay', 'Today'),
                    icon: Icons.today_rounded,
                    isSelected: _isToday(_selectedDate),
                    onTap: () => _setDayPreservingTime(DateTime.now()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDateQuickChip(
                    label: tr('Hôm qua', 'Yesterday'),
                    icon: Icons.history_rounded,
                    isSelected: _isYesterday(_selectedDate),
                    onTap: () => _setDayPreservingTime(
                      DateTime.now().subtract(const Duration(days: 1)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDateQuickChip(
                    label: isOtherDate
                        ? AppFormatters.formatDate(_selectedDate)
                        : tr('Khác...', 'Other...'),
                    icon: Icons.calendar_month_rounded,
                    isSelected: isOtherDate,
                    onTap: _pickDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: Icon(
                  _isEditing ? Icons.check_circle_rounded : Icons.save_rounded,
                  size: 20,
                  color: isExpense ? AppColors.onPrimary : Colors.white,
                ),
                label: Text(
                  _isEditing
                      ? tr('Cập nhật giao dịch', 'Update Transaction')
                      : tr('Lưu giao dịch', 'Save Transaction'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isExpense ? AppColors.onPrimary : Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExpense
                      ? AppColors.primary
                      : AppColors.income,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildTypeTab(TransactionType type, String label, Color activeColor) {
    final active = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTypeChanged(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateQuickChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final fg = isSelected ? AppColors.primaryDark : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
