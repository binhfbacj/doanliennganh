import 'dart:math';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../utils/app_localizations.dart';
import '../utils/currency_formatter.dart';

class FinancialHealth {
  final int score; // 0 - 100
  final String status;
  final String advice;
  final double savingsRate;

  const FinancialHealth({
    required this.score,
    required this.status,
    required this.advice,
    required this.savingsRate,
  });
}

class BudgetAlert {
  final CategoryItem category;
  final double limit;
  final double spent;
  final double percent;
  final bool isOver;

  const BudgetAlert({
    required this.category,
    required this.limit,
    required this.spent,
    required this.percent,
    required this.isOver,
  });
}

class FinancialAdvisorService {
  static final FinancialAdvisorService instance =
      FinancialAdvisorService._internal();
  FinancialAdvisorService._internal();

  /// Tính điểm sức khỏe tài chính thông minh (0 - 100)
  FinancialHealth evaluateHealth({
    required double totalIncome,
    required double totalExpense,
    required List<BudgetItem> budgets,
    required List<TransactionRecord> transactions,
  }) {
    if (totalIncome == 0 && totalExpense == 0) {
      return FinancialHealth(
        score: 100,
        status: tr('Chưa có dữ liệu', 'No data yet'),
        advice: tr(
          'Hãy ghi lại các khoản thu và chi đầu tiên để AI đánh giá sức khỏe tài chính của bạn.',
          'Log your first income and expenses so Smart Bee AI can evaluate your financial health.',
        ),
        savingsRate: 0,
      );
    }

    double savingsRate = 0;
    if (totalIncome > 0) {
      savingsRate = max(
        0.0,
        ((totalIncome - totalExpense) / totalIncome) * 100,
      );
    }

    int score = 70;

    if (totalIncome > 0) {
      final expenseRate = totalExpense / totalIncome;
      if (expenseRate <= 0.5) {
        score += 25;
      } else if (expenseRate <= 0.7) {
        score += 15;
      } else if (expenseRate <= 0.85) {
        score += 5;
      } else if (expenseRate <= 1.0) {
        score -= 10;
      } else {
        score -= 30;
      }
    } else if (totalExpense > 0) {
      score -= 20;
    }

    final now = DateTime.now();
    int overBudgetCount = 0;
    for (final b in budgets) {
      if (b.month == now.month && b.year == now.year && b.limit > 0) {
        final spent = transactions
            .where(
              (t) =>
                  t.type == TransactionType.expense &&
                  t.categoryId == b.categoryId &&
                  t.dateTime.month == now.month &&
                  t.dateTime.year == now.year,
            )
            .fold(0.0, (sum, t) => sum + t.amount);
        if (spent > b.limit) {
          overBudgetCount++;
        }
      }
    }

    score -= (overBudgetCount * 10);
    score = score.clamp(10, 100);

    String status;
    String advice;

    if (score >= 85) {
      status = tr('Xuất sắc ⭐⭐⭐', 'Excellent ⭐⭐⭐');
      advice = tr(
        'Bạn đang quản lý tài chính rất kỷ luật! Hãy trích thêm vào hũ mật tích lũy hoặc mục tiêu tiết kiệm dài hạn.',
        'You are managing your finances with great discipline! Consider adding more to your Honey Jar savings goals.',
      );
    } else if (score >= 70) {
      status = tr('Tốt & Ổn định 👍', 'Good & Stable 👍');
      advice = tr(
        'Dòng tiền của bạn đang ở mức an toàn. Tiếp tục duy trì hạn mức chi tiêu cho các nhu cầu thiết yếu nhé!',
        'Your cash flow is healthy. Keep maintaining your budget limits for essential categories!',
      );
    } else if (score >= 50) {
      status = tr('Cần chú ý ⚠️', 'Needs Attention ⚠️');
      advice = tr(
        'Chi tiêu đang chiếm tỷ trọng khá cao trong thu nhập. Hãy hạn chế các khoản mua sắm hoặc ăn uống tự do.',
        'Spending takes up a high share of your income. Try reducing non-essential shopping or dining out.',
      );
    } else {
      status = tr('Báo động chi tiêu 🚨', 'Spending Alert 🚨');
      advice = tr(
        'Cảnh báo: Bạn đang tiêu vượt quá thu nhập hoặc thâm hụt ngân sách! Hãy rà soát lại các khoản chi ngay hôm nay.',
        'Warning: Your expenses exceed your income or budget! Review your spending categories today.',
      );
    }

    return FinancialHealth(
      score: score,
      status: status,
      advice: advice,
      savingsRate: savingsRate,
    );
  }

  /// Quét các danh mục sắp vượt (>= 80%) hoặc đã vượt (>= 100%) ngân sách
  List<BudgetAlert> getBudgetAlerts({
    required List<BudgetItem> budgets,
    required List<TransactionRecord> transactions,
    required DateTime month,
  }) {
    final alerts = <BudgetAlert>[];

    for (final b in budgets) {
      if (b.month == month.month && b.year == month.year && b.limit > 0) {
        final spent = transactions
            .where(
              (t) =>
                  t.type == TransactionType.expense &&
                  t.categoryId == b.categoryId &&
                  t.dateTime.month == month.month &&
                  t.dateTime.year == month.year,
            )
            .fold(0.0, (sum, t) => sum + t.amount);

        final pct = spent / b.limit;
        if (pct >= 0.8) {
          final cat = CategoryItem.findById(b.categoryId);
          alerts.add(
            BudgetAlert(
              category: cat,
              limit: b.limit,
              spent: spent,
              percent: pct,
              isOver: pct >= 1.0,
            ),
          );
        }
      }
    }

    alerts.sort((a, b) => b.percent.compareTo(a.percent));
    return alerts;
  }

  /// Tính hạn mức chi tiêu trung bình mỗi ngày trong tháng
  double calculateDailyRemainingBudget({
    required double totalBudget,
    required double totalSpent,
    required DateTime now,
  }) {
    if (totalBudget <= 0) return 0.0;
    final remainingBudget = totalBudget - totalSpent;
    if (remainingBudget <= 0) return 0.0;

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = max(1, daysInMonth - now.day + 1);

    return remainingBudget / remainingDays;
  }

  /// Tạo mẹo chi tiêu thông minh theo danh mục tốn kém nhất
  String generateInsight({
    required List<TransactionRecord> transactions,
    required double totalIncome,
    required double totalExpense,
  }) {
    if (transactions.isEmpty || totalExpense <= 0) {
      return tr(
        'Bắt đầu ghi chép mọi khoản chi tiêu dù nhỏ nhất để hình thành thói quen kiểm soát dòng tiền thông minh!',
        'Start logging every expense, even small ones, to build smart money management habits!',
      );
    }

    final catMap = <String, double>{};
    for (final tx in transactions.where(
      (t) => t.type == TransactionType.expense,
    )) {
      catMap[tx.categoryId] = (catMap[tx.categoryId] ?? 0) + tx.amount;
    }

    if (catMap.isEmpty) {
      return tr(
        'Tuyệt vời! Bạn chưa có khoản chi tiêu nào phát sinh.',
        'Awesome! You have no expenses recorded yet.',
      );
    }

    final topEntry = catMap.entries.reduce((a, b) => a.value > b.value ? a : b);
    final topCat = CategoryItem.findById(topEntry.key);
    final topPercent = (topEntry.value / totalExpense) * 100;

    if (topPercent >= 40) {
      return tr(
        'Danh mục "${topCat.name}" đang chiếm tới ${topPercent.toStringAsFixed(0)}% tổng chi tiêu (${AppFormatters.formatCurrency(topEntry.value)}). Bạn nên cân nhắc tối ưu khoản này để tăng tiền tiết kiệm!',
        '"${topCat.name}" accounts for ${topPercent.toStringAsFixed(0)}% of your total spending (${AppFormatters.formatCurrency(topEntry.value)}). Consider optimizing it to boost your savings!',
      );
    } else {
      return tr(
        'Chi tiêu tháng này của bạn phân bổ tương đối đồng đều. Danh mục cao nhất là "${topCat.name}" chiếm ${topPercent.toStringAsFixed(0)}% tổng chi.',
        'Your spending is well balanced this month. The highest category is "${topCat.name}" at ${topPercent.toStringAsFixed(0)}% of total expenses.',
      );
    }
  }
}
