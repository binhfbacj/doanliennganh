import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../utils/app_localizations.dart';

class VoiceService {
  static final VoiceService instance = VoiceService._internal();
  VoiceService._internal();

  final SpeechToText _speechToText = SpeechToText();

  bool _isInitialized = false;
  bool _isAvailable = false;
  String _viLocaleId = 'vi_VN';
  String _enLocaleId = 'en_US';

  bool get isListening => _speechToText.isListening;
  bool get isAvailable => _isAvailable;
  bool get isInitialized => _isInitialized;

  /// Khởi tạo nhận diện giọng nói
  Future<bool> initialize({
    Function(SpeechRecognitionError)? onError,
    Function(String)? onStatus,
  }) async {
    if (_isInitialized) return _isAvailable;

    try {
      _isAvailable = await _speechToText.initialize(
        onError: (val) {
          debugPrint('Speech error: ${val.errorMsg}');
          onError?.call(val);
        },
        onStatus: (val) {
          debugPrint('Speech status: $val');
          onStatus?.call(val);
        },
        debugLogging: kDebugMode,
      );

      if (_isAvailable) {
        final locales = await _speechToText.locales();
        if (locales.isNotEmpty) {
          final viLocale = locales.firstWhere(
            (l) => l.localeId.toLowerCase().startsWith('vi'),
            orElse: () => locales.first,
          );
          final enLocale = locales.firstWhere(
            (l) => l.localeId.toLowerCase().startsWith('en'),
            orElse: () => locales.first,
          );
          _viLocaleId = viLocale.localeId;
          _enLocaleId = enLocale.localeId;
        }
      }

      _isInitialized = true;
      return _isAvailable;
    } catch (e) {
      debugPrint('Voice initialize error: $e');
      _isAvailable = false;
      _isInitialized = true;
      return false;
    }
  }

  /// Bắt đầu lắng nghe giọng nói
  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    Function(double level)? onSoundLevelChange,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isAvailable) {
      throw Exception(
        tr(
          'Thiết bị chưa hỗ trợ nhận diện giọng nói hoặc chưa cấp quyền Micro.',
          'Speech recognition is not available or microphone permission was denied.',
        ),
      );
    }

    final localeToUse = AppLocalizations.isEn ? _enLocaleId : _viLocaleId;

    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
        onDevice: false,
        localeId: localeToUse,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
      ),
      onSoundLevelChange: onSoundLevelChange,
    );
  }

  /// Dừng lắng nghe
  Future<void> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
  }

  /// Hủy lắng nghe
  Future<void> cancelListening() async {
    if (_speechToText.isListening) {
      await _speechToText.cancel();
    }
  }
}
