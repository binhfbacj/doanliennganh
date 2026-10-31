import 'package:flutter_test/flutter_test.dart';
import 'package:bai/models/category.dart';
import 'package:bai/services/voice_parser.dart';

void main() {
  group('VietnameseVoiceParser Tests', () {
    test('Nhận diện chi tiêu ăn uống dạng k', () {
      final res = VietnameseVoiceParser.parse('Ăn sáng phở bò 35k');
      expect(res.success, isTrue);
      expect(res.amount, 35000.0);
      expect(res.type, TransactionType.expense);
      expect(res.category.id, 'food');
      expect(res.title.contains('Ăn sáng phở bò'), isTrue);
    });

    test('Nhận diện đổ xăng dạng nghìn / ngàn', () {
      final res = VietnameseVoiceParser.parse('Đổ xăng xe máy 70 ngàn');
      expect(res.success, isTrue);
      expect(res.amount, 70000.0);
      expect(res.type, TransactionType.expense);
      expect(res.category.id, 'transport');
    });

    test('Nhận diện mua sắm', () {
      final res = VietnameseVoiceParser.parse('Mua quần áo shopee 250k');
      expect(res.success, isTrue);
      expect(res.amount, 250000.0);
      expect(res.type, TransactionType.expense);
      expect(res.category.id, 'shopping');
    });

    test('Nhận diện hóa đơn điện nước', () {
      final res = VietnameseVoiceParser.parse('Tiền điện tháng này 650 nghìn');
      expect(res.success, isTrue);
      expect(res.amount, 650000.0);
      expect(res.type, TransactionType.expense);
      expect(res.category.id, 'bills');
    });

    test('Nhận diện thu nhập tiền lương', () {
      final res = VietnameseVoiceParser.parse('Nhận lương tháng này 18 triệu');
      expect(res.success, isTrue);
      expect(res.amount, 18000000.0);
      expect(res.type, TransactionType.income);
      expect(res.category.id, 'salary');
    });

    test('Nhận diện thưởng dạng củ', () {
      final res = VietnameseVoiceParser.parse('Thưởng dự án 2 củ');
      expect(res.success, isTrue);
      expect(res.amount, 2000000.0);
      expect(res.type, TransactionType.income);
      expect(res.category.id, 'bonus');
    });

    test('Nhận diện từ lóng lít', () {
      final res = VietnameseVoiceParser.parse('Ăn trưa 2 lít');
      expect(res.success, isTrue);
      expect(res.amount, 200000.0);
      expect(res.type, TransactionType.expense);
      expect(res.category.id, 'food');
    });

    test('Báo lỗi khi không có số tiền', () {
      final res = VietnameseVoiceParser.parse('Hôm nay đi chơi vui quá');
      expect(res.success, isFalse);
    });
  });
}
