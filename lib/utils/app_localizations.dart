import 'package:flutter/foundation.dart';

class AppLocalizations {
  static final ValueNotifier<String> languageNotifier = ValueNotifier<String>(
    'vi',
  );

  static bool get isEn => languageNotifier.value == 'en';
  static String get currentLang => languageNotifier.value;

  static void setLanguage(String langCode) {
    if (langCode == 'en' || langCode == 'vi') {
      languageNotifier.value = langCode;
    }
  }
}

/// Helper function to translate inline between Vietnamese and English
String tr(String vi, String en) => AppLocalizations.isEn ? en : vi;
