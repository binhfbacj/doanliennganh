import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'app_localizations.dart';

class AppFormatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final NumberFormat _numberFormat = NumberFormat.decimalPattern('vi_VN');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount).trim();
  }

  static String formatNumber(double amount) {
    return _numberFormat.format(amount.round());
  }

  static double? parseAmount(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = today.difference(target).inDays;
    if (diff == 0) return tr('Hôm nay', 'Today');
    if (diff == 1) return tr('Hôm qua', 'Yesterday');
    return _dateFormat.format(date);
  }

  static String formatFullDate(DateTime date) {
    return '${_dateFormat.format(date)} ${tr('lúc', 'at')} ${_timeFormat.format(date)}';
  }

  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final number = int.tryParse(digits);
    if (number == null) return oldValue;

    final formatted = AppFormatters.formatNumber(number.toDouble());
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
