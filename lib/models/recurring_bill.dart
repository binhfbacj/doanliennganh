import 'package:flutter/foundation.dart';
import 'category.dart';

@immutable
class RecurringBill {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final int dayOfMonth; // 1..31
  final bool isActive;
  final bool autoAdd;
  final int? lastPaidMonth;
  final int? lastPaidYear;
  final String? note;

  const RecurringBill({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.dayOfMonth,
    this.isActive = true,
    this.autoAdd = false,
    this.lastPaidMonth,
    this.lastPaidYear,
    this.note,
  });

  CategoryItem get category => CategoryItem.findById(categoryId);

  bool isPaidForMonth(DateTime now) {
    return lastPaidMonth == now.month && lastPaidYear == now.year;
  }

  DateTime dueDateForMonth(DateTime now) {
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final clampedDay = dayOfMonth > lastDayOfMonth
        ? lastDayOfMonth
        : dayOfMonth;
    return DateTime(now.year, now.month, clampedDay);
  }

  /// Số ngày còn lại đến ngày thanh toán trong tháng này (âm nếu đã qua ngày hạn)
  int daysUntilDue(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final due = dueDateForMonth(now);
    return due.difference(today).inDays;
  }

  /// Đã đến hạn hoặc quá hạn trong tháng này mà chưa thanh toán
  bool isDueOrOverdue(DateTime now) {
    if (!isActive || isPaidForMonth(now)) return false;
    return daysUntilDue(now) <= 0;
  }

  /// Sắp đến hạn (trong vòng 5 ngày tới) hoặc đã đến hạn trong tháng này
  bool needsAttention(DateTime now) {
    if (!isActive || isPaidForMonth(now)) return false;
    return daysUntilDue(now) <= 5;
  }

  RecurringBill copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    int? dayOfMonth,
    bool? isActive,
    bool? autoAdd,
    int? lastPaidMonth,
    int? lastPaidYear,
    bool clearPaidStatus = false,
    String? note,
  }) {
    return RecurringBill(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      isActive: isActive ?? this.isActive,
      autoAdd: autoAdd ?? this.autoAdd,
      lastPaidMonth: clearPaidStatus
          ? null
          : (lastPaidMonth ?? this.lastPaidMonth),
      lastPaidYear: clearPaidStatus
          ? null
          : (lastPaidYear ?? this.lastPaidYear),
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'type': type.name,
    'categoryId': categoryId,
    'dayOfMonth': dayOfMonth,
    'isActive': isActive,
    'autoAdd': autoAdd,
    'lastPaidMonth': lastPaidMonth,
    'lastPaidYear': lastPaidYear,
    'note': note,
  };

  factory RecurringBill.fromJson(Map<String, dynamic> json) {
    return RecurringBill(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Hoá đơn định kỳ',
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      categoryId: json['categoryId'] as String? ?? 'bills',
      dayOfMonth: (json['dayOfMonth'] as num?)?.toInt() ?? 1,
      isActive: json['isActive'] as bool? ?? true,
      autoAdd: json['autoAdd'] as bool? ?? false,
      lastPaidMonth: (json['lastPaidMonth'] as num?)?.toInt(),
      lastPaidYear: (json['lastPaidYear'] as num?)?.toInt(),
      note: json['note'] as String?,
    );
  }
}
