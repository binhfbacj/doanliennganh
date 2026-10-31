import '../models/category.dart';
import '../models/transaction.dart';
import '../utils/app_localizations.dart';
import '../utils/currency_formatter.dart';

/// Kết quả trả lời câu hỏi thống kê giọng nói
class VoiceQueryResult {
  final bool isQuery;
  final String answer;
  final List<VoiceStatItem> stats;

  const VoiceQueryResult({
    required this.isQuery,
    required this.answer,
    this.stats = const [],
  });
}

class VoiceStatItem {
  final String label;
  final String value;
  final bool isNegative;
  const VoiceStatItem(this.label, this.value, {this.isNegative = false});
}

class VoiceQueryHandler {
  /// Kiểm tra và xử lý câu hỏi thống kê
  static VoiceQueryResult handle(
    String text,
    List<TransactionRecord> allTransactions,
  ) {
    final lower = text.toLowerCase().trim();

    final queryKeywords = [
      'tôi tiêu',
      'tiêu bao nhiêu',
      'chi bao nhiêu',
      'tổng chi',
      'tôi có',
      'còn bao nhiêu',
      'thu nhập',
      'thu bao nhiêu',
      'tổng thu',
      'tháng này',
      'tháng trước',
      'tuần này',
      'tuần trước',
      'hôm nay',
      'nhiều nhất',
      'ít nhất',
      'hay tiêu',
      'thường tiêu',
      'bao nhiêu giao dịch',
      'mấy lần',
      'số dư',
      'tổng cộng',
      'tóm tắt',
      'báo cáo',
      'thống kê',
      'how much',
      'summary',
      'report',
      'balance',
      'most on',
      'spend this',
      'spent today',
    ];

    final isQuery = queryKeywords.any((kw) => lower.contains(kw));
    if (!isQuery) {
      return const VoiceQueryResult(isQuery: false, answer: '');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<TransactionRecord> filtered;
    String period;

    if (lower.contains('hôm nay') ||
        lower.contains('hom nay') ||
        lower.contains('today')) {
      filtered = allTransactions
          .where((t) => _sameDay(t.dateTime, today))
          .toList();
      period = tr('hôm nay', 'today');
    } else if (lower.contains('tuần này') ||
        lower.contains('tuan nay') ||
        lower.contains('this week')) {
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      filtered = allTransactions
          .where((t) => !t.dateTime.isBefore(startOfWeek))
          .toList();
      period = tr('tuần này', 'this week');
    } else if (lower.contains('tuần trước') ||
        lower.contains('tuan truoc') ||
        lower.contains('last week')) {
      final startOfLastWeek = today.subtract(Duration(days: today.weekday + 6));
      final endOfLastWeek = today.subtract(Duration(days: today.weekday));
      filtered = allTransactions.where((t) {
        return !t.dateTime.isBefore(startOfLastWeek) &&
            !t.dateTime.isAfter(endOfLastWeek);
      }).toList();
      period = tr('tuần trước', 'last week');
    } else if (lower.contains('tháng trước') || lower.contains('last month')) {
      final lastMonth = now.month == 1
          ? DateTime(now.year - 1, 12)
          : DateTime(now.year, now.month - 1);
      filtered = allTransactions
          .where(
            (t) =>
                t.dateTime.year == lastMonth.year &&
                t.dateTime.month == lastMonth.month,
          )
          .toList();
      period = '${tr('tháng', 'month')} ${lastMonth.month}/${lastMonth.year}';
    } else {
      filtered = allTransactions
          .where(
            (t) => t.dateTime.year == now.year && t.dateTime.month == now.month,
          )
          .toList();
      period = '${tr('tháng', 'month')} ${now.month}/${now.year}';
    }

    final expenses = filtered
        .where((t) => t.type == TransactionType.expense)
        .toList();
    final incomes = filtered
        .where((t) => t.type == TransactionType.income)
        .toList();

    final totalExpense = expenses.fold(0.0, (s, t) => s + t.amount);
    final totalIncome = incomes.fold(0.0, (s, t) => s + t.amount);
    final balance = totalIncome - totalExpense;

    if (lower.contains('số dư') ||
        lower.contains('còn bao nhiêu') ||
        lower.contains('tôi có') ||
        lower.contains('balance')) {
      return VoiceQueryResult(
        isQuery: true,
        answer: tr(
          'Số dư $period của bạn là ${AppFormatters.formatCurrency(balance.abs())}${balance >= 0 ? ' (dư)' : ' (âm)'}.',
          'Your balance for $period is ${AppFormatters.formatCurrency(balance.abs())}${balance >= 0 ? ' (positive)' : ' (deficit)'}.',
        ),
        stats: [
          VoiceStatItem(
            tr('Thu vào', 'Income'),
            AppFormatters.formatCurrency(totalIncome),
          ),
          VoiceStatItem(
            tr('Chi ra', 'Expense'),
            AppFormatters.formatCurrency(totalExpense),
            isNegative: true,
          ),
          VoiceStatItem(
            tr('Số dư', 'Balance'),
            '${balance >= 0 ? '+' : '-'}${AppFormatters.formatCurrency(balance.abs())}',
            isNegative: balance < 0,
          ),
        ],
      );
    }

    if ((lower.contains('thu') || lower.contains('income')) &&
        !lower.contains('tổng')) {
      if (totalIncome == 0) {
        return VoiceQueryResult(
          isQuery: true,
          answer: tr(
            'Bạn chưa có khoản thu nhập nào được ghi lại trong $period.',
            'You have no income recorded for $period.',
          ),
        );
      }
      return VoiceQueryResult(
        isQuery: true,
        answer: tr(
          'Tổng thu nhập $period của bạn là ${AppFormatters.formatCurrency(totalIncome)} từ ${incomes.length} giao dịch.',
          'Your total income for $period is ${AppFormatters.formatCurrency(totalIncome)} across ${incomes.length} transactions.',
        ),
        stats: _buildCategoryStats(incomes),
      );
    }

    if (lower.contains('nhiều nhất') ||
        lower.contains('hay tiêu') ||
        lower.contains('thường tiêu') ||
        lower.contains('most')) {
      if (expenses.isEmpty) {
        return VoiceQueryResult(
          isQuery: true,
          answer: tr(
            'Không có dữ liệu chi tiêu nào trong $period.',
            'No expenses recorded for $period.',
          ),
        );
      }
      final catMap = <String, double>{};
      for (final t in expenses) {
        catMap[t.category.name] = (catMap[t.category.name] ?? 0) + t.amount;
      }
      final sorted = catMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;
      return VoiceQueryResult(
        isQuery: true,
        answer: tr(
          'Trong $period, bạn chi nhiều nhất cho "${top.key}" với ${AppFormatters.formatCurrency(top.value)}.',
          'In $period, you spent the most on "${top.key}" (${AppFormatters.formatCurrency(top.value)}).',
        ),
        stats: sorted
            .take(4)
            .map(
              (e) => VoiceStatItem(
                e.key,
                AppFormatters.formatCurrency(e.value),
                isNegative: true,
              ),
            )
            .toList(),
      );
    }

    if (lower.contains('tóm tắt') ||
        lower.contains('báo cáo') ||
        lower.contains('thống kê') ||
        lower.contains('tổng cộng') ||
        lower.contains('summary') ||
        lower.contains('report')) {
      if (filtered.isEmpty) {
        return VoiceQueryResult(
          isQuery: true,
          answer: tr(
            'Chưa có giao dịch nào được ghi lại trong $period.',
            'No transactions recorded for $period.',
          ),
        );
      }
      return VoiceQueryResult(
        isQuery: true,
        answer: tr(
          'Tóm tắt $period: ${filtered.length} giao dịch. Thu ${AppFormatters.formatCurrency(totalIncome)}, Chi ${AppFormatters.formatCurrency(totalExpense)}. Số dư ${balance >= 0 ? '+' : ''}${AppFormatters.formatCurrency(balance.abs())}.',
          'Summary for $period: ${filtered.length} transactions. Income ${AppFormatters.formatCurrency(totalIncome)}, Expense ${AppFormatters.formatCurrency(totalExpense)}. Net ${balance >= 0 ? '+' : ''}${AppFormatters.formatCurrency(balance.abs())}.',
        ),
        stats: [
          VoiceStatItem(
            tr('Tổng giao dịch', 'Total txs'),
            '${filtered.length}',
          ),
          VoiceStatItem(
            tr('Thu vào', 'Income'),
            AppFormatters.formatCurrency(totalIncome),
          ),
          VoiceStatItem(
            tr('Chi ra', 'Expense'),
            AppFormatters.formatCurrency(totalExpense),
            isNegative: true,
          ),
          VoiceStatItem(
            tr('Số dư', 'Balance'),
            '${balance >= 0 ? '+' : '-'}${AppFormatters.formatCurrency(balance.abs())}',
            isNegative: balance < 0,
          ),
        ],
      );
    }

    if (expenses.isEmpty) {
      return VoiceQueryResult(
        isQuery: true,
        answer: tr(
          'Bạn chưa ghi lại khoản chi tiêu nào trong $period.',
          'You have not logged any expenses for $period.',
        ),
      );
    }

    return VoiceQueryResult(
      isQuery: true,
      answer: tr(
        'Trong $period, bạn đã chi tổng cộng ${AppFormatters.formatCurrency(totalExpense)} qua ${expenses.length} giao dịch.',
        'In $period, you spent a total of ${AppFormatters.formatCurrency(totalExpense)} across ${expenses.length} transactions.',
      ),
      stats: _buildCategoryStats(expenses),
    );
  }

  static List<String> buildSmartPrompts(List<TransactionRecord> transactions) {
    final defaults = AppLocalizations.isEn
        ? _enDefaultPrompts
        : _viDefaultPrompts;
    if (transactions.isEmpty) {
      return defaults;
    }

    final now = DateTime.now();
    final recent = transactions
        .where((t) => now.difference(t.dateTime).inDays <= 30)
        .toList();

    if (recent.isEmpty) return defaults;

    final titleCount = <String, int>{};
    for (final t in recent) {
      final key = t.title;
      titleCount[key] = (titleCount[key] ?? 0) + 1;
    }
    final sortedTitles = titleCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final prompts = <String>[];

    prompts.add(
      tr(
        'Ăn phở 45k, cà phê 30k và đổ xăng 70k',
        'Lunch 50k, coffee 30k and taxi 60k',
      ),
    );
    prompts.add(
      tr('Tháng này tôi tiêu bao nhiêu?', 'How much did I spend this month?'),
    );
    prompts.add(
      tr('Tôi hay tiêu nhiều nhất vào đâu?', 'What did I spend the most on?'),
    );
    prompts.add(
      tr('Tóm tắt tháng này cho tôi', 'Give me a summary for this month'),
    );

    for (final entry in sortedTitles.take(3)) {
      final tx = recent.firstWhere((t) => t.title == entry.key);
      final unit = _guessUnit(tx.amount);
      final amountStr = _formatAmountShort(tx.amount);
      final prefix = tx.type == TransactionType.income
          ? tr('Nhận', 'Received')
          : '';
      final label = prefix.isEmpty
          ? '${tx.title} $amountStr$unit'
          : '$prefix ${tx.title.toLowerCase()} $amountStr$unit';
      if (label.length > 5) prompts.add(label);
    }

    for (final p in defaults) {
      if (prompts.length >= 8) break;
      if (!prompts.any(
        (existing) =>
            existing.toLowerCase().contains(p.split(' ').first.toLowerCase()),
      )) {
        prompts.add(p);
      }
    }

    return prompts.take(8).toList();
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static List<VoiceStatItem> _buildCategoryStats(List<TransactionRecord> txs) {
    final catMap = <String, double>{};
    for (final t in txs) {
      catMap[t.category.name] = (catMap[t.category.name] ?? 0) + t.amount;
    }
    final sorted = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(4)
        .map(
          (e) => VoiceStatItem(
            e.key,
            AppFormatters.formatCurrency(e.value),
            isNegative: true,
          ),
        )
        .toList();
  }

  static String _guessUnit(double amount) {
    if (amount >= 1000000) return AppLocalizations.isEn ? 'm' : ' triệu';
    if (amount >= 1000) return 'k';
    return '';
  }

  static String _formatAmountShort(double amount) {
    if (amount >= 1000000) {
      final m = amount / 1000000;
      return m == m.roundToDouble() ? '${m.toInt()}' : m.toStringAsFixed(1);
    }
    if (amount >= 1000) return '${(amount / 1000).round()}';
    return '${amount.toInt()}';
  }

  static const _viDefaultPrompts = [
    'Ăn phở 45k, cà phê 30k và đổ xăng 70k',
    'Ăn sáng phở bò 45 nghìn',
    'Đổ xăng xe máy 70k',
    'Cà phê highland 55k',
    'Mua đồ shopee 250 ngàn',
    'Nhận lương 18 triệu',
    'Tháng này tôi tiêu bao nhiêu?',
    'Tôi hay tiêu nhiều nhất vào đâu?',
  ];

  static const _enDefaultPrompts = [
    'Lunch 50k, coffee 30k and taxi 60k',
    'Breakfast pho 45k',
    'Gas fuel 70k',
    'Coffee 55k',
    'Shopping 250k',
    'Received salary 18m',
    'How much did I spend this month?',
    'What did I spend the most on?',
  ];
}
