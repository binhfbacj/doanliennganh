import 'package:flutter/foundation.dart';
import 'category.dart';

@immutable
class TransactionRecord {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final DateTime dateTime;
  final String? note;
  final bool isVoiceInput;
  final String? rawVoiceText;

  const TransactionRecord({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.dateTime,
    this.note,
    this.isVoiceInput = false,
    this.rawVoiceText,
  });

  CategoryItem get category => CategoryItem.findById(categoryId);

  TransactionRecord copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    DateTime? dateTime,
    String? note,
    bool clearNote = false,
    bool? isVoiceInput,
    String? rawVoiceText,
  }) {
    return TransactionRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      dateTime: dateTime ?? this.dateTime,
      note: clearNote ? null : (note ?? this.note),
      isVoiceInput: isVoiceInput ?? this.isVoiceInput,
      rawVoiceText: rawVoiceText ?? this.rawVoiceText,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'type': type.name,
    'categoryId': categoryId,
    'dateTime': dateTime.toIso8601String(),
    'note': note,
    'isVoiceInput': isVoiceInput,
    'rawVoiceText': rawVoiceText,
  };

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Giao dịch',
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      categoryId: json['categoryId'] as String? ?? 'other_expense',
      dateTime:
          DateTime.tryParse(json['dateTime'] as String? ?? '') ??
          DateTime.now(),
      note: json['note'] as String?,
      isVoiceInput: json['isVoiceInput'] as bool? ?? false,
      rawVoiceText: json['rawVoiceText'] as String?,
    );
  }
}
