import '../models/category.dart';
import '../utils/app_localizations.dart';

class VoiceParseResult {
  final bool success;
  final double amount;
  final TransactionType type;
  final CategoryItem category;
  final String title;
  final String? note;
  final String rawText;
  final String? message;
  final DateTime date;

  const VoiceParseResult({
    required this.success,
    required this.amount,
    required this.type,
    required this.category,
    required this.title,
    this.note,
    required this.rawText,
    this.message,
    required this.date,
  });

  factory VoiceParseResult.failed(String rawText, String reason) {
    return VoiceParseResult(
      success: false,
      amount: 0,
      type: TransactionType.expense,
      category: CategoryItem.defaultCategories.first,
      title: tr('Không nhận diện được', 'Unrecognized'),
      rawText: rawText,
      message: reason,
      date: DateTime.now(),
    );
  }
}

class VietnameseVoiceParser {
  /// Phân tích câu nói có thể chứa NHIỀU giao dịch cùng lúc
  /// Ví dụ: "Hôm nay ăn phở 45k, uống cà phê 30k và đổ xăng 70k"
  static List<VoiceParseResult> parseMultiple(String text) {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      return [
        VoiceParseResult.failed(
          '',
          tr('Chưa nhận được câu nói nào.', 'No speech detected.'),
        ),
      ];
    }

    final lowerFull = cleanText.toLowerCase();
    final hasExplicitSharedDate = _hasExplicitDateKeyword(lowerFull);
    final sharedDate = _extractDate(lowerFull);

    // Tách câu theo dấu phẩy, chấm phẩy, liên từ ("và", "với", "rồi", "sau đó", "thêm", "and", "then", "plus")
    // hoặc tách ngay sau cụm số tiền khi người dùng đọc liền nhiều khoản
    final normalized = cleanText.replaceAllMapped(
      RegExp(
        r'(\d+(?:[.,]\d+)?\s*(?:triệu|củ|tr|million|m|nghìn|ngàn|k|thousand|lít|đồng|đ|vnd))\s+(?=(?:ăn|uống|mua|đổ|trả|đóng|nạp|xem|đi|thuê|cafe|cà phê|phở|bún|cơm|trà|bánh|xăng|grab|taxi|lương|thưởng|nhận|buy|eat|drink|coffee|lunch|dinner|breakfast|taxi|fuel|gas|rent|paid|pay)\b)',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}, ',
    );

    final rawSegments = normalized
        .split(
          RegExp(
            r'(?:[,;]+|\s+(?:và|với|rồi|sau đó|thêm|cùng với|and|then|plus)\s+)',
            caseSensitive: false,
          ),
        )
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (rawSegments.length > 1) {
      final results = <VoiceParseResult>[];
      for (final seg in rawSegments) {
        final parsed = parse(
          seg,
          fallbackDate: hasExplicitSharedDate ? sharedDate : null,
        );
        if (parsed.success) {
          results.add(parsed);
        }
      }
      if (results.isNotEmpty) {
        return results;
      }
    }

    return [parse(cleanText)];
  }

  /// Phân tích câu nói tiếng Việt hoặc tiếng Anh để trích xuất số tiền, loại giao dịch, danh mục và tiêu đề
  static VoiceParseResult parse(String text, {DateTime? fallbackDate}) {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      return VoiceParseResult.failed(
        '',
        tr('Chưa nhận được câu nói nào.', 'No speech detected.'),
      );
    }

    final lower = cleanText.toLowerCase();

    // 1. Xác định Loại giao dịch (Thu nhập vs Chi tiêu)
    final type = _detectTransactionType(lower);

    // 2. Trích xuất Số tiền (Amount)
    final amount = _extractAmount(lower);
    if (amount == null || amount <= 0) {
      return VoiceParseResult.failed(
        cleanText,
        tr(
          'Không tìm thấy số tiền hợp lệ trong câu nói (Ví dụ: "Ăn sáng 35 nghìn", "Đổ xăng 50k", "Lương 15 triệu").',
          'Could not find a valid amount in your command (e.g., "Breakfast 35k", "Coffee 50k", "Salary 15m").',
        ),
      );
    }

    // 3. Xác định Danh mục (Category)
    final category = _detectCategory(lower, type);

    // 4. Trích xuất Ngày (Date)
    final date = (_hasExplicitDateKeyword(lower) || fallbackDate == null)
        ? _extractDate(lower)
        : fallbackDate;

    // 5. Tạo Tiêu đề (Title) & Ghi chú (Note)
    final title = _generateTitle(cleanText, lower, category);

    return VoiceParseResult(
      success: true,
      amount: amount,
      type: type,
      category: category,
      title: title,
      note: tr(
        'Nhập bằng giọng nói: "$cleanText"',
        'Voice input: "$cleanText"',
      ),
      rawText: cleanText,
      date: date,
    );
  }

  static bool _hasExplicitDateKeyword(String lower) {
    return lower.contains('hôm qua') ||
        lower.contains('hom qua') ||
        lower.contains('yesterday') ||
        lower.contains('last night') ||
        lower.contains('hôm kia') ||
        lower.contains('hom kia') ||
        lower.contains('hôm kìa') ||
        lower.contains('tuần trước') ||
        lower.contains('tuan truoc') ||
        lower.contains('last week') ||
        lower.contains('hôm nay') ||
        lower.contains('hom nay') ||
        lower.contains('today') ||
        lower.contains('tối qua') ||
        lower.contains('sáng qua') ||
        lower.contains('chiều qua') ||
        lower.contains('trưa qua') ||
        RegExp(r'ngày\s+\d{1,2}').hasMatch(lower) ||
        RegExp(r'\b\d{1,2}/\d{1,2}\b').hasMatch(lower);
  }

  /// Xác định loại: Chi tiêu hay Thu nhập
  static TransactionType _detectTransactionType(String text) {
    const incomeKeywords = [
      'lương',
      'nhận',
      'thu',
      'thưởng',
      'lãi',
      'được cho',
      'lì xì',
      'bán hàng',
      'tiền vào',
      'cộng tiền',
      'hoàn tiền',
      'nhận tiền',
      'salary',
      'bonus',
      'income',
      'received',
      'receive',
      'paycheck',
      'profit',
      'dividend',
    ];

    for (final kw in incomeKeywords) {
      if (text.contains(kw)) {
        return TransactionType.income;
      }
    }
    return TransactionType.expense;
  }

  /// Trích xuất số tiền từ câu nói
  static double? _extractAmount(String text) {
    final trioTrieuRuoi = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:triệu|củ|tr)\s*(?:rưỡi|nửa)',
    );
    final matchRuoi = trioTrieuRuoi.firstMatch(text);
    if (matchRuoi != null) {
      final base =
          double.tryParse(matchRuoi.group(1)!.replaceAll(',', '.')) ?? 0;
      return (base + 0.5) * 1000000;
    }

    final regTrieuLe = RegExp(
      r'(\d+)\s*(?:triệu|củ|tr|million)\s*(\d+)\s*(?:trăm|nghìn|ngàn|k|thousand)?',
    );
    final matchTrieuLe = regTrieuLe.firstMatch(text);
    if (matchTrieuLe != null) {
      final million = double.tryParse(matchTrieuLe.group(1)!) ?? 0;
      final part = double.tryParse(matchTrieuLe.group(2)!) ?? 0;
      if (part < 10) {
        return (million + (part / 10)) * 1000000;
      } else if (part < 1000) {
        return (million * 1000000) + (part * 1000);
      } else {
        return (million * 1000000) + part;
      }
    }

    // Triệu / Củ / Tr / Million / M
    final regTrieu = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:triệu|củ|tr|million|m)(?:\s|$|[.,;!?])',
    );
    final matchTrieu = regTrieu.firstMatch(text);
    if (matchTrieu != null) {
      final val =
          double.tryParse(matchTrieu.group(1)!.replaceAll(',', '.')) ?? 0;
      return val * 1000000;
    }

    final regLit = RegExp(r'(\d+)\s*(?:lít)(?:\s|$|[.,;!?])');
    final matchLit = regLit.firstMatch(text);
    if (matchLit != null) {
      final val = double.tryParse(matchLit.group(1)!) ?? 0;
      return val * 100000;
    }

    // "nghìn", "ngàn", "k", "thousand"
    final regNgan = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:nghìn|ngàn|k|thousand)(?:\s|$|[.,;!?])',
    );
    final matchNgan = regNgan.firstMatch(text);
    if (matchNgan != null) {
      final val =
          double.tryParse(matchNgan.group(1)!.replaceAll(',', '.')) ?? 0;
      return val * 1000;
    }

    final regSoDayDu = RegExp(
      r'(\d{1,3}(?:[.,]\d{3})+|\d{4,9})\s*(?:đồng|đ|vnd)?(?:\s|$|[.,;!?])',
    );
    final matchDayDu = regSoDayDu.firstMatch(text);
    if (matchDayDu != null) {
      final cleanNum = matchDayDu
          .group(1)!
          .replaceAll('.', '')
          .replaceAll(',', '');
      return double.tryParse(cleanNum);
    }

    final regGeneral = RegExp(r'(\d+)\s*(?:đồng|đ)?');
    final matchGeneral = regGeneral.firstMatch(text);
    if (matchGeneral != null) {
      final numVal = double.tryParse(matchGeneral.group(1)!) ?? 0;
      if (numVal > 0 && numVal < 1000) {
        return numVal * 1000;
      }
      return numVal;
    }

    return null;
  }

  /// Tìm danh mục khớp nhất dựa trên từ khóa
  static CategoryItem _detectCategory(String text, TransactionType type) {
    final categories = CategoryItem.defaultCategories
        .where((c) => c.type == type)
        .toList();

    int bestMatchCount = -1;
    CategoryItem? bestCategory;

    for (final cat in categories) {
      int score = 0;
      for (final kw in cat.keywords) {
        if (text.contains(kw)) {
          score += kw.length;
        }
      }
      if (score > bestMatchCount) {
        bestMatchCount = score;
        bestCategory = cat;
      }
    }

    if (bestCategory != null && bestMatchCount > 0) {
      return bestCategory;
    }

    for (final cat in CategoryItem.defaultCategories) {
      for (final kw in cat.keywords) {
        if (text.contains(kw)) {
          return cat;
        }
      }
    }

    return type == TransactionType.income
        ? CategoryItem.findById('other_income')
        : CategoryItem.findById('other_expense');
  }

  /// Trích xuất ngày từ câu nói
  static DateTime _extractDate(String text) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (text.contains('hôm qua') ||
        text.contains('hom qua') ||
        text.contains('yesterday') ||
        text.contains('last night')) {
      return today.subtract(const Duration(days: 1));
    }
    if (text.contains('hôm kia') ||
        text.contains('hom kia') ||
        text.contains('hôm kìa')) {
      return today.subtract(const Duration(days: 2));
    }
    if (text.contains('tuần trước') ||
        text.contains('tuan truoc') ||
        text.contains('last week')) {
      return today.subtract(const Duration(days: 7));
    }
    if (text.contains('hôm nay') ||
        text.contains('hom nay') ||
        text.contains('sáng nay') ||
        text.contains('trưa nay') ||
        text.contains('chiều nay') ||
        text.contains('tối nay') ||
        text.contains('today')) {
      return today;
    }

    if (text.contains('tối qua') ||
        text.contains('sáng qua') ||
        text.contains('chiều qua') ||
        text.contains('trưa qua')) {
      return today.subtract(const Duration(days: 1));
    }

    final regNgayThang = RegExp(r'(?:ngày\s+)?(\d{1,2})\s+tháng\s+(\d{1,2})');
    final mNgayThang = regNgayThang.firstMatch(text);
    if (mNgayThang != null) {
      final d = int.tryParse(mNgayThang.group(1)!) ?? now.day;
      final mo = int.tryParse(mNgayThang.group(2)!) ?? now.month;
      if (d >= 1 && d <= 31 && mo >= 1 && mo <= 12) {
        return DateTime(now.year, mo, d);
      }
    }

    final regNgay = RegExp(r'ngày\s+(\d{1,2})(?:\s|$)');
    final mNgay = regNgay.firstMatch(text);
    if (mNgay != null) {
      final d = int.tryParse(mNgay.group(1)!) ?? now.day;
      return DateTime(now.year, now.month, d);
    }

    final regSlash = RegExp(r'\b(\d{1,2})/(\d{1,2})(?:/(\d{4}))?\b');
    final mSlash = regSlash.firstMatch(text);
    if (mSlash != null) {
      final d = int.tryParse(mSlash.group(1)!) ?? now.day;
      final mo = int.tryParse(mSlash.group(2)!) ?? now.month;
      final yr = int.tryParse(mSlash.group(3) ?? '') ?? now.year;
      if (d >= 1 && d <= 31 && mo >= 1 && mo <= 12) {
        return DateTime(yr, mo, d);
      }
    }

    return today;
  }

  /// Tạo tiêu đề gọn gàng cho giao dịch
  static String _generateTitle(
    String originalText,
    String lower,
    CategoryItem category,
  ) {
    var cleaned = originalText
        .replaceAll(
          RegExp(
            r'\d+(?:[.,]\d+)?\s*(?:triệu|củ|tr|million|m|nghìn|ngàn|k|thousand|lít|đồng|đ|vnd)?',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'\b(hôm nay|hôm qua|hôm kia|hôm kìa|sáng nay|trưa nay|chiều nay|tối nay|tối qua|sáng qua|chiều qua|trưa qua|tuần trước|today|yesterday|last night|last week)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'\bngày\s+\d{1,2}(\s+tháng\s+\d{1,2})?\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(r'\b\d{1,2}\s+tháng\s+\d{1,2}\b', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\b\d{1,2}/\d{1,2}(?:/\d{4})?\b'), '')
        .trim();

    cleaned = cleaned.replaceAll(RegExp(r'^\s*[-:,]\s*'), '').trim();

    if (cleaned.isNotEmpty && cleaned.length >= 2) {
      return cleaned[0].toUpperCase() + cleaned.substring(1);
    }

    return category.name;
  }
}
