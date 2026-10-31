import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../utils/app_localizations.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/transaction_tile.dart';

class HistoryScreen extends StatefulWidget {
  final List<TransactionRecord> transactions;
  final Function(TransactionRecord) onDeleteTransaction;
  final Function(TransactionRecord)? onEditTransaction;

  const HistoryScreen({
    super.key,
    required this.transactions,
    required this.onDeleteTransaction,
    this.onEditTransaction,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  int _filterType = 0; // 0: All, 1: Expense, 2: Income, 3: Voice
  String? _selectedCategoryFilter;
  DateTime? _selectedMonth; // null = All time

  void _changeMonth(int delta) {
    final base = _selectedMonth ?? DateTime(DateTime.now().year, DateTime.now().month);
    setState(() {
      _selectedMonth = DateTime(base.year, base.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchQuery.toLowerCase();
    final filtered = widget.transactions.where((t) {
      if (_selectedMonth != null) {
        if (t.dateTime.year != _selectedMonth!.year ||
            t.dateTime.month != _selectedMonth!.month) {
          return false;
        }
      }
      final matchQuery =
          q.isEmpty ||
          t.title.toLowerCase().contains(q) ||
          t.category.name.toLowerCase().contains(q) ||
          (t.note?.toLowerCase().contains(q) ?? false) ||
          t.amount.toString().contains(q);
      if (!matchQuery) return false;
      if (_filterType == 1 && t.type != TransactionType.expense) return false;
      if (_filterType == 2 && t.type != TransactionType.income) return false;
      if (_filterType == 3 && !t.isVoiceInput) return false;
      if (_selectedCategoryFilter != null &&
          t.categoryId != _selectedCategoryFilter) {
        return false;
      }
      return true;
    }).toList();

    double periodIncome = 0;
    double periodExpense = 0;
    final grouped = <DateTime, List<TransactionRecord>>{};
    for (final tx in filtered) {
      if (tx.type == TransactionType.income) {
        periodIncome += tx.amount;
      } else {
        periodExpense += tx.amount;
      }
      final dateKey = DateTime(
        tx.dateTime.year,
        tx.dateTime.month,
        tx.dateTime.day,
      );
      grouped.putIfAbsent(dateKey, () => []).add(tx);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          tr('Lịch Sử Giao Dịch', 'Transaction History'),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String?>(
            color: AppColors.surface,
            icon: Icon(
              Icons.filter_list_rounded,
              color: _selectedCategoryFilter != null
                  ? AppColors.primaryDark
                  : AppColors.textSecondary,
            ),
            tooltip: tr('Lọc theo danh mục', 'Filter by category'),
            onSelected: (catId) =>
                setState(() => _selectedCategoryFilter = catId),
            itemBuilder: (_) => [
              PopupMenuItem<String?>(
                value: null,
                child: Text(
                  tr('Tất cả danh mục', 'All categories'),
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
              const PopupMenuDivider(),
              ...CategoryItem.defaultCategories.map(
                (cat) => PopupMenuItem<String?>(
                  value: cat.id,
                  child: Row(
                    children: [
                      Icon(cat.icon, color: cat.color, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        cat.name,
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _buildMonthFilterBar(periodIncome, periodExpense),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: tr(
                  'Tìm theo tên, danh mục, số tiền, ghi chú...',
                  'Search by title, category, amount, note...',
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textMuted,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(
                  0,
                  '${tr('Tất cả', 'All')} (${filtered.length})',
                ),
                const SizedBox(width: 8),
                _buildFilterChip(1, tr('Chi tiêu (-)', 'Expenses (-)')),
                const SizedBox(width: 8),
                _buildFilterChip(2, tr('Thu nhập (+)', 'Income (+)')),
                const SizedBox(width: 8),
                _buildFilterChip(
                  3,
                  tr('🎙️ Bằng giọng nói', '🎙️ Voice Input'),
                  highlightColor: AppColors.voiceActive,
                ),
                if (_selectedCategoryFilter != null) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      CategoryItem.findById(_selectedCategoryFilter!).name,
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    backgroundColor: CategoryItem.findById(
                      _selectedCategoryFilter!,
                    ).color,
                    onDeleted: () =>
                        setState(() => _selectedCategoryFilter = null),
                    deleteIconColor: Colors.white,
                    side: BorderSide.none,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 60,
                            color: AppColors.border,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            tr(
                              'Không tìm thấy giao dịch phù hợp',
                              'No matching transactions found',
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, dateIndex) {
                      final date = sortedDates[dateIndex];
                      final dayTxs = grouped[date]!;

                      double dayExpense = 0;
                      double dayIncome = 0;
                      for (final tx in dayTxs) {
                        if (tx.type == TransactionType.expense) {
                          dayExpense += tx.amount;
                        } else {
                          dayIncome += tx.amount;
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDateHeader(date),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (dayIncome > 0)
                                      Text(
                                        '+${AppFormatters.formatCurrency(dayIncome)} ',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.income,
                                        ),
                                      ),
                                    if (dayExpense > 0)
                                      Text(
                                        '-${AppFormatters.formatCurrency(dayExpense)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.expense,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          for (final tx in dayTxs)
                            TransactionTile(
                              transaction: tx,
                              onDelete: () => widget.onDeleteTransaction(tx),
                              onEdit: widget.onEditTransaction != null
                                  ? () => widget.onEditTransaction!(tx)
                                  : null,
                              onTap: () => _showDetailModal(tx),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthFilterBar(double income, double expense) {
    final isAllTime = _selectedMonth == null;
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _selectedMonth = isAllTime
                    ? DateTime(now.year, now.month)
                    : null;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isAllTime
                    ? AppColors.primary
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                tr('Tất cả', 'All Time'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isAllTime
                      ? AppColors.onPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => _changeMonth(-1),
            icon: Icon(
              Icons.chevron_left_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedMonth = DateTime(now.year, now.month);
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                isAllTime
                    ? tr('Chọn tháng', 'By Month')
                    : '${tr('Tháng', 'Month')} ${_selectedMonth!.month}/${_selectedMonth!.year}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isAllTime
                      ? AppColors.textSecondary
                      : AppColors.primaryDark,
                ),
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => _changeMonth(1),
            icon: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (income > 0)
                Text(
                  '+${AppFormatters.formatCurrency(income)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.income,
                  ),
                ),
              Text(
                '-${AppFormatters.formatCurrency(expense)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) {
      return '${tr('Hôm nay', 'Today')}, ${date.day}/${date.month}';
    }
    if (date == yesterday) {
      return '${tr('Hôm qua', 'Yesterday')}, ${date.day}/${date.month}';
    }
    return '${tr('Ngày', 'Date')} ${date.day}/${date.month}/${date.year}';
  }

  Widget _buildFilterChip(int index, String title, {Color? highlightColor}) {
    final isSelected = _filterType == index;
    final activeColor = highlightColor ?? AppColors.primary;

    return ChoiceChip(
      label: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
        ),
      ),
      selected: isSelected,
      selectedColor: activeColor,
      backgroundColor: AppColors.surface,
      side: BorderSide(color: isSelected ? activeColor : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => setState(() => _filterType = index),
    );
  }

  void _showDetailModal(TransactionRecord tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cat = tx.category;
        final isIncome = tx.type == TransactionType.income;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(cat.icon, color: cat.color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                tx.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${isIncome ? '+' : '-'}${AppFormatters.formatCurrency(tx.amount)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isIncome ? AppColors.income : AppColors.expense,
                ),
              ),
              const SizedBox(height: 18),
              Divider(color: AppColors.border),
              const SizedBox(height: 8),
              _detailRow(tr('Danh mục', 'Category'), cat.name),
              _detailRow(
                tr('Thời gian', 'Date & Time'),
                AppFormatters.formatFullDate(tx.dateTime),
              ),
              _detailRow(
                tr('Phương thức nhập', 'Entry Method'),
                tx.isVoiceInput
                    ? tr('🎙️ Giọng nói AI', '🎙️ AI Voice Input')
                    : tr('Bàn phím thủ công', 'Manual Entry'),
              ),
              if (tx.rawVoiceText != null)
                _detailRow(
                  tr('Câu nói gốc', 'Original Speech'),
                  '"${tx.rawVoiceText}"',
                ),
              if (tx.note != null && tx.note!.isNotEmpty)
                _detailRow(tr('Ghi chú', 'Note'), tx.note!),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onDeleteTransaction(tx);
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.expense,
                        size: 18,
                      ),
                      label: Text(
                        tr('Xóa', 'Delete'),
                        style: const TextStyle(
                          color: AppColors.expense,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: AppColors.expense.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onEditTransaction?.call(tx);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: AppColors.beeGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: AppColors.onPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tr('Chỉnh sửa', 'Edit'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
