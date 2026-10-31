import 'package:flutter_test/flutter_test.dart';
import 'package:bai/models/budget.dart';
import 'package:bai/models/category.dart';
import 'package:bai/models/savings_goal.dart';
import 'package:bai/models/transaction.dart';
import 'package:bai/services/financial_advisor.dart';

void main() {
  group('FinancialAdvisorService Tests', () {
    test('Đánh giá sức khỏe tài chính xuất sắc khi tiết kiệm > 50%', () {
      final advisor = FinancialAdvisorService.instance;
      final health = advisor.evaluateHealth(
        totalIncome: 20000000,
        totalExpense: 8000000,
        budgets: [],
        transactions: [],
      );

      expect(health.score, greaterThanOrEqualTo(85));
      expect(health.status.contains('Xuất sắc'), isTrue);
      expect(health.savingsRate, equals(60.0));
    });

    test('Đánh giá sức khỏe tài chính báo động khi chi vượt thu', () {
      final advisor = FinancialAdvisorService.instance;
      final health = advisor.evaluateHealth(
        totalIncome: 10000000,
        totalExpense: 15000000,
        budgets: [],
        transactions: [],
      );

      expect(health.score, lessThan(50));
      expect(health.status.contains('Báo động'), isTrue);
      expect(health.savingsRate, equals(0.0));
    });

    test('Phát hiện cảnh báo khi danh mục vượt quá 80% ngân sách', () {
      final now = DateTime.now();
      final advisor = FinancialAdvisorService.instance;
      final budgets = [
        BudgetItem(
          categoryId: 'food',
          limit: 2000000,
          month: now.month,
          year: now.year,
        ),
      ];
      final transactions = [
        TransactionRecord(
          id: '1',
          title: 'Ăn lẩu',
          amount: 1800000,
          type: TransactionType.expense,
          categoryId: 'food',
          dateTime: now,
        ),
      ];

      final alerts = advisor.getBudgetAlerts(
        budgets: budgets,
        transactions: transactions,
        month: now,
      );

      expect(alerts.length, equals(1));
      expect(alerts.first.category.id, equals('food'));
      expect(alerts.first.percent, equals(0.9));
      expect(alerts.first.isOver, isFalse);
    });
  });

  group('SavingsGoal Model Tests', () {
    test('Tính toán % hoàn thành và còn thiếu chính xác', () {
      final goal = SavingsGoal(
        id: 'g1',
        title: 'Mua laptop',
        targetAmount: 20000000,
        currentAmount: 5000000,
        createdAt: DateTime.now(),
      );

      expect(goal.progress, equals(0.25));
      expect(goal.remainingAmount, equals(15000000));
      expect(goal.isCompleted, isFalse);
    });

    test('Đánh dấu hoàn thành khi đạt đủ số tiền', () {
      final goal = SavingsGoal(
        id: 'g2',
        title: 'Quỹ du lịch',
        targetAmount: 5000000,
        currentAmount: 5500000,
        createdAt: DateTime.now(),
      );

      expect(goal.progress, equals(1.0));
      expect(goal.isCompleted, isTrue);
      expect(goal.remainingAmount, equals(0.0));
    });
  });
}
