import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/voice_parser.dart';
import '../services/voice_query_handler.dart';
import '../services/voice_service.dart';
import '../utils/app_localizations.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

class VoiceAssistantSheet extends StatefulWidget {
  final Function(TransactionRecord transaction) onTransactionAdded;
  final List<TransactionRecord> transactions;

  const VoiceAssistantSheet({
    super.key,
    required this.onTransactionAdded,
    this.transactions = const [],
  });

  @override
  State<VoiceAssistantSheet> createState() => _VoiceAssistantSheetState();
}

class _VoiceAssistantSheetState extends State<VoiceAssistantSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  final VoiceService _voiceService = VoiceService.instance;

  bool _isListening = false;
  String _recognizedText = '';
  VoiceParseResult? _parseResult;
  List<VoiceParseResult> _multiResults = [];
  VoiceQueryResult? _queryResult;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  List<String> get _quickPrompts =>
      VoiceQueryHandler.buildSmartPrompts(widget.transactions);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _startListening());
  }

  @override
  void dispose() {
    _animController.dispose();
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _errorMessage = null;
      _recognizedText = '';
      _parseResult = null;
      _multiResults = [];
      _queryResult = null;
      _isListening = true;
    });

    try {
      final available = await _voiceService.initialize();
      if (!available) {
        setState(() {
          _isListening = false;
          _errorMessage = tr(
            'Không thể kích hoạt Micro hoặc thiết bị chưa cấp quyền. Bạn có thể bấm vào các câu mẫu bên dưới để thử nghiệm!',
            'Microphone unavailable or permission denied. You can tap the sample phrases below to test!',
          );
        });
        return;
      }

      await _voiceService.startListening(
        onResult: (text, isFinal) {
          if (!mounted) return;
          setState(() => _recognizedText = text);
          if (isFinal || text.trim().isNotEmpty) _processVoiceText(text);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _errorMessage = tr(
          'Lỗi kết nối giọng nói: $e\nBạn có thể thử dùng các câu lệnh mẫu phía dưới!',
          'Voice recognition error: $e\nYou can try tapping the sample phrases below!',
        );
      });
    }
  }

  Future<void> _stopListening() async {
    await _voiceService.stopListening();
    if (mounted) {
      setState(() => _isListening = false);
      if (_recognizedText.isNotEmpty) _processVoiceText(_recognizedText);
    }
  }

  void _processVoiceText(String text) {
    if (text.trim().isEmpty) return;

    final queryResult = VoiceQueryHandler.handle(text, widget.transactions);
    if (queryResult.isQuery) {
      setState(() {
        _queryResult = queryResult;
        _parseResult = null;
        _multiResults = [];
        _errorMessage = null;
      });
      return;
    }

    final results = VietnameseVoiceParser.parseMultiple(text);
    final validResults = results.where((r) => r.success).toList();

    setState(() {
      _queryResult = null;
      if (validResults.length > 1) {
        _multiResults = validResults;
        _parseResult = validResults.first;
        _selectedDate = validResults.first.date;
        _errorMessage = null;
      } else {
        _multiResults = [];
        final single = results.first;
        _parseResult = single;
        if (single.success) {
          _selectedDate = single.date;
          _errorMessage = null;
        } else {
          _errorMessage = single.message;
        }
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) {
      return '${tr('Hôm nay', 'Today')} (${date.day}/${date.month}/${date.year})';
    }
    if (d == today.subtract(const Duration(days: 1))) {
      return '${tr('Hôm qua', 'Yesterday')} (${date.day}/${date.month}/${date.year})';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _applyQuickPrompt(String prompt) {
    setState(() {
      _recognizedText = prompt;
      _errorMessage = null;
    });
    _processVoiceText(prompt);
  }

  void _showSuccessSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.onPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _confirmAndSave() {
    final now = DateTime.now();
    final txDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      now.hour,
      now.minute,
    );

    if (_multiResults.length > 1) {
      double total = 0;
      for (int i = 0; i < _multiResults.length; i++) {
        final item = _multiResults[i];
        total += item.amount;
        widget.onTransactionAdded(
          TransactionRecord(
            id: 'tx_${now.millisecondsSinceEpoch}_$i',
            title: item.title,
            amount: item.amount,
            type: item.type,
            categoryId: item.category.id,
            dateTime: txDate,
            note: item.note,
            isVoiceInput: true,
            rawVoiceText: _recognizedText,
          ),
        );
      }
      final count = _multiResults.length;
      Navigator.of(context).pop();
      _showSuccessSnack(
        tr(
          '🐝 Đã thêm cùng lúc $count giao dịch (${AppFormatters.formatCurrency(total)})!',
          '🐝 Added $count transactions at once (${AppFormatters.formatCurrency(total)})!',
        ),
      );
      return;
    }

    if (_parseResult == null || !_parseResult!.success) return;

    final p = _parseResult!;
    widget.onTransactionAdded(
      TransactionRecord(
        id: 'tx_${now.millisecondsSinceEpoch}',
        title: p.title,
        amount: p.amount,
        type: p.type,
        categoryId: p.category.id,
        dateTime: txDate,
        note: p.note,
        isVoiceInput: true,
        rawVoiceText: p.rawText,
      ),
    );
    Navigator.of(context).pop();
    _showSuccessSnack(
      '${tr('Đã thêm', 'Added')}: ${p.title} (${AppFormatters.formatCurrency(p.amount)})',
    );
  }

  Widget _buildDateSelectorRow() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: 8),
            Text(
              tr('Ngày chi tiêu: ', 'Date: '),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              _formatDate(_selectedDate),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.edit_calendar_rounded,
              size: 15,
              color: AppColors.primaryDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton({required IconData icon, required String label}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _confirmAndSave,
        icon: Icon(icon, color: AppColors.onPrimary),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.onPrimary,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.voiceActive.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.record_voice_over_rounded,
                        color: AppColors.voiceActive,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('Trợ lý giọng nói AI', 'AI Voice Assistant'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          tr(
                            'Nói tự nhiên để tự động ghi chép',
                            'Speak naturally to log expenses',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _isListening ? _stopListening() : _startListening(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isListening)
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.voiceActive.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  if (_isListening)
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.voiceActive.withValues(alpha: 0.35),
                      ),
                    ),
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isListening
                            ? [AppColors.primary, AppColors.primaryDark]
                            : [AppColors.surfaceElevated, AppColors.border],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_isListening
                                      ? AppColors.primary
                                      : Colors.black54)
                                  .withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening
                          ? AppColors.onPrimary
                          : AppColors.textPrimary,
                      size: 34,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _isListening
                  ? tr(
                      'Đang lắng nghe... Hãy nói ngay bây giờ',
                      'Listening... Speak now',
                    )
                  : tr(
                      'Bấm micro để nói hoặc chọn mẫu câu bên dưới',
                      'Tap the mic to speak or pick a sample phrase below',
                    ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _isListening
                    ? AppColors.primaryDark
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _recognizedText.isNotEmpty
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : AppColors.border,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 16,
                    color: _recognizedText.isNotEmpty
                        ? AppColors.voiceActive
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _recognizedText.isEmpty
                          ? tr(
                              'Nội dung nhận diện sẽ xuất hiện ở đây...',
                              'Recognized speech will appear here...',
                            )
                          : '"$_recognizedText"',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: _recognizedText.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                        fontWeight: _recognizedText.isNotEmpty
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: _recognizedText.isNotEmpty
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.amber.shade800,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_queryResult != null && _queryResult!.isQuery) ...[
              const SizedBox(height: 16),
              _buildQueryResultCard(_queryResult!),
            ],
            if (_multiResults.length > 1) ...[
              const SizedBox(height: 16),
              _buildMultiResultsCard(),
            ] else if (_parseResult != null && _parseResult!.success) ...[
              const SizedBox(height: 16),
              _buildSingleResultCard(_parseResult!),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.beeGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Text('🐝', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(
                            'Chú Ong Chi Tiêu gợi ý',
                            'Smart Bee Voice Suggestions',
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.onPrimary,
                          ),
                        ),
                        Text(
                          tr(
                            'Chạm vào câu lệnh mẫu để thử ngay:',
                            'Tap a sample phrase below to test instantly:',
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.onPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tr('🍯 Gợi ý', '🍯 Tips'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickPrompts.map((prompt) {
                final lower = prompt.toLowerCase();
                final isQuestion =
                    prompt.endsWith('?') ||
                    prompt.contains('bao nhiêu') ||
                    prompt.contains('tóm tắt') ||
                    prompt.contains('tiêu nhiều') ||
                    prompt.contains('thống kê') ||
                    lower.contains('how much') ||
                    lower.contains('summary');
                return ActionChip(
                  label: Text(
                    prompt,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isQuestion
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  backgroundColor: isQuestion
                      ? AppColors.primary.withValues(alpha: 0.16)
                      : AppColors.surfaceElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isQuestion
                          ? AppColors.primary.withValues(alpha: 0.45)
                          : AppColors.border,
                    ),
                  ),
                  avatar: isQuestion
                      ? const Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: AppColors.primaryDark,
                        )
                      : const Text('🐝', style: TextStyle(fontSize: 12)),
                  onPressed: () => _applyQuickPrompt(prompt),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueryResultCard(VoiceQueryResult q) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primaryDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                tr('Chú Ong AI trả lời', 'Smart Bee AI Answer'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            q.answer,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          if (q.stats.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: q.stats.map((s) {
                final c = s.isNegative ? AppColors.expense : AppColors.income;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: c,
                        ),
                      ),
                      Text(
                        s.value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: c,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            tr(
              'Hỏi thêm hoặc nói để ghi giao dịch mới 👆',
              'Ask another question or speak to log a new transaction 👆',
            ),
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiResultsCard() {
    final total = _multiResults.fold<double>(0, (s, r) => s + r.amount);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.65),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🐝', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    tr(
                      'Tách được ${_multiResults.length} giao dịch cùng lúc!',
                      'Detected ${_multiResults.length} transactions at once!',
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppFormatters.formatCurrency(total),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int idx = 0; idx < _multiResults.length; idx++) ...[
            Builder(
              builder: (_) {
                final item = _multiResults[idx];
                final isInc = item.type == TransactionType.income;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.category.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.category.icon,
                          color: item.category.color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              item.category.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: item.category.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isInc ? '+' : '-'}${AppFormatters.formatCurrency(item.amount)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isInc ? AppColors.income : AppColors.expense,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _multiResults.removeAt(idx);
                            if (_multiResults.length == 1) {
                              _parseResult = _multiResults.first;
                            }
                          });
                        },
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 6),
          _buildDateSelectorRow(),
          const SizedBox(height: 12),
          _buildConfirmButton(
            icon: Icons.done_all_rounded,
            label: tr(
              'Lưu tất cả ${_multiResults.length} giao dịch',
              'Save All ${_multiResults.length} Transactions',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleResultCard(VoiceParseResult p) {
    final isInc = p.type == TransactionType.income;
    final typeColor = isInc ? AppColors.income : AppColors.expense;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(p.category.icon, color: p.category.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isInc
                                ? tr('Thu nhập', 'Income')
                                : tr('Chi tiêu', 'Expense'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: typeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          p.category.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.category.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${isInc ? '+' : '-'}${AppFormatters.formatCurrency(p.amount)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: typeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDateSelectorRow(),
          const SizedBox(height: 12),
          _buildConfirmButton(
            icon: Icons.check_rounded,
            label: tr('Xác nhận & Lưu giao dịch', 'Confirm & Save Transaction'),
          ),
        ],
      ),
    );
  }
}
