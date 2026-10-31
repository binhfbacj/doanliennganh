/// Model lưu ngân sách cho 1 danh mục trong 1 tháng
class BudgetItem {
  final String categoryId; // khớp với CategoryItem.id
  final double limit; // hạn mức (0 = không đặt)
  final int month; // 1-12
  final int year;

  const BudgetItem({
    required this.categoryId,
    required this.limit,
    required this.month,
    required this.year,
  });

  BudgetItem copyWith({
    String? categoryId,
    double? limit,
    int? month,
    int? year,
  }) {
    return BudgetItem(
      categoryId: categoryId ?? this.categoryId,
      limit: limit ?? this.limit,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'limit': limit,
    'month': month,
    'year': year,
  };

  factory BudgetItem.fromJson(Map<String, dynamic> json) {
    return BudgetItem(
      categoryId: json['categoryId'] as String,
      limit: (json['limit'] as num).toDouble(),
      month: json['month'] as int,
      year: json['year'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetItem &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          month == other.month &&
          year == other.year;

  @override
  int get hashCode => Object.hash(categoryId, month, year);
}
