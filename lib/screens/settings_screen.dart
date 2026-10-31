import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../utils/app_localizations.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final UserModel? user;
  final VoidCallback onClearAllData;
  final VoidCallback onOpenVoiceAssistant;
  final VoidCallback onLogout;
  final VoidCallback onReplayOnboarding;
  final VoidCallback onGoToSavings;

  const SettingsScreen({
    super.key,
    this.user,
    required this.onClearAllData,
    required this.onOpenVoiceAssistant,
    required this.onLogout,
    required this.onReplayOnboarding,
    required this.onGoToSavings,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _toggleDarkMode(bool val) {
    AppTheme.themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
    StorageService.instance.saveThemeMode(val ? 'dark' : 'light');
    if (mounted) setState(() {});
  }

  void _changeLanguage(String langCode) {
    AppLocalizations.setLanguage(langCode);
    StorageService.instance.saveLanguage(langCode);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.themeModeNotifier.value == ThemeMode.dark;
    final currentLang = AppLocalizations.currentLang;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(tr('Cài Đặt & Tiện Ích', 'Settings & Preferences')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin người dùng
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _sectionCardDecoration(radius: 24),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      gradient: AppColors.beeGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.user != null && widget.user!.name.isNotEmpty
                            ? widget.user!.name[0].toUpperCase()
                            : '🐝',
                        style: const TextStyle(
                          color: AppColors.onPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user != null && widget.user!.name.isNotEmpty
                              ? widget.user!.name
                              : tr('Chú Ong Thông Minh', 'Smart Bee User'),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.user != null && widget.user!.email.isNotEmpty
                              ? widget.user!.email
                              : tr(
                                  'Quản Lý Tiêu Dùng AI 🐝',
                                  'AI Bee Expense Manager 🐝',
                                ),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            _buildSectionTitle(
              tr('TIỆN ÍCH & GIAO DIỆN', 'APPEARANCE & LANGUAGE'),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _sectionCardDecoration(),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildIconBox(
                        isDarkMode
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        AppColors.primaryDark,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(
                                'Chế độ Tối (Dark Mode)',
                                'Dark Mode (Bee Black)',
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isDarkMode
                                  ? tr(
                                      'Đang bật nền Đen Tổ Ong & Vàng',
                                      'Active: Bee Black & Honey Gold',
                                    )
                                  : tr(
                                      'Đang bật nền Sáng Kem Mật Ong',
                                      'Active: Warm Honey Light Mode',
                                    ),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isDarkMode,
                        onChanged: _toggleDarkMode,
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primary.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ],
                  ),
                  Divider(color: AppColors.border, height: 20),
                  Row(
                    children: [
                      _buildIconBox(
                        Icons.translate_rounded,
                        AppColors.primaryDark,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('Ngôn ngữ ứng dụng', 'App Language'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentLang == 'en'
                                  ? 'English (US)'
                                  : 'Tiếng Việt (VN)',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _langOptionChip(
                              'vi',
                              '🇻🇳 VI',
                              currentLang == 'vi',
                            ),
                            const SizedBox(width: 4),
                            _langOptionChip(
                              'en',
                              '🇬🇧 EN',
                              currentLang == 'en',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(color: AppColors.border, height: 20),
                  _settingTile(
                    icon: Icons.savings_rounded,
                    iconColor: AppColors.primaryDark,
                    title: tr(
                      'Hũ Mật Tích Lũy & Tiết kiệm',
                      'Honey Jar Savings Goals',
                    ),
                    subtitle: tr(
                      'Đặt hạn mức và theo dõi tiến độ hoàn thành',
                      'Set targets and track your savings progress',
                    ),
                    onTap: widget.onGoToSavings,
                  ),
                  Divider(color: AppColors.border, height: 20),
                  _settingTile(
                    icon: Icons.auto_stories_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: tr(
                      'Xem lại hướng dẫn giới thiệu',
                      'Replay Welcome Guide',
                    ),
                    subtitle: tr(
                      'Các nguyên tắc kiểm soát chi tiêu 50/30/20',
                      'Learn the 50/30/20 smart budgeting rule',
                    ),
                    onTap: widget.onReplayOnboarding,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            _buildSectionTitle(tr('TRỢ LÝ GIỌNG NÓI AI', 'AI VOICE ASSISTANT')),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _sectionCardDecoration(),
              child: Column(
                children: [
                  _settingTile(
                    icon: Icons.mic_rounded,
                    iconColor: AppColors.primaryDark,
                    title: tr(
                      'Kích hoạt Micro & Trợ lý ảo',
                      'Activate Microphone & AI Assistant',
                    ),
                    subtitle: tr(
                      'Nói câu lệnh để ghi chép nhanh hoặc hỏi đáp',
                      'Speak commands to log expenses or ask questions',
                    ),
                    onTap: widget.onOpenVoiceAssistant,
                  ),
                  Divider(color: AppColors.border, height: 20),
                  _settingTile(
                    icon: Icons.tips_and_updates_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: tr(
                      'Gợi ý các câu lệnh thông minh',
                      'Smart Voice Command Tips',
                    ),
                    subtitle: tr(
                      'Xem cách nói để trợ lý nhận diện chuẩn xác nhất',
                      'See example phrases for accurate voice recognition',
                    ),
                    onTap: () => _showVoiceGuideDialog(context),
                  ),
                  Divider(color: AppColors.border, height: 20),
                  _settingTile(
                    icon: Icons.language_rounded,
                    iconColor: AppColors.income,
                    title: tr(
                      'Ngôn ngữ nhận diện giọng nói',
                      'Voice Recognition Language',
                    ),
                    subtitle: currentLang == 'en'
                        ? 'English (en-US) — Tap to switch to Vietnamese'
                        : 'Tiếng Việt (vi-VN) — Chạm để đổi sang Tiếng Anh',
                    onTap: () =>
                        _changeLanguage(currentLang == 'vi' ? 'en' : 'vi'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            _buildSectionTitle(tr('DỮ LIỆU & TÀI KHOẢN', 'DATA & ACCOUNT')),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _sectionCardDecoration(),
              child: Column(
                children: [
                  _settingTile(
                    icon: Icons.delete_sweep_rounded,
                    iconColor: AppColors.expense,
                    title: tr(
                      'Đặt lại toàn bộ giao dịch',
                      'Reset All Transactions',
                    ),
                    subtitle: tr(
                      'Xóa sạch dữ liệu để nhập lại từ đầu',
                      'Clear all transaction records and start fresh',
                    ),
                    onTap: widget.onClearAllData,
                  ),
                  Divider(color: AppColors.border, height: 20),
                  _settingTile(
                    icon: Icons.logout_rounded,
                    iconColor: const Color(0xFFDC2626),
                    title: tr('Đăng xuất tài khoản', 'Sign Out'),
                    subtitle: tr(
                      'Thoát tài khoản hiện tại',
                      'Log out of your current account',
                    ),
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Center(
              child: Column(
                children: [
                  Text(
                    tr(
                      '🐝 Phiên bản 2.3.0 (Bee Edition)',
                      '🐝 Version 2.3.0 (Bee Edition)',
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr(
                      'Quản Lý Tiêu Dùng Thông Minh & Tiết Kiệm Tự Động',
                      'Smart Expense Tracking & Automated Honey Jar Savings',
                    ),
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _sectionCardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.border, width: 1.2),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildIconBox(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _langOptionChip(String code, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _changeLanguage(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _buildIconBox(icon, iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showVoiceGuideDialog(BuildContext context) {
    final examples = [
      tr(
        '• "Ăn sáng 35k" -> Ăn uống, 35.000đ',
        '• "Coffee 50k" -> Food & Dining',
      ),
      tr(
        '• "Ăn phở 45k, cà phê 30k và đổ xăng 70k" -> Tách 3 giao dịch',
        '• "Lunch 50k, coffee 30k and taxi 60k" -> Logs 3 items',
      ),
      tr(
        '• "Đổ xăng xe 70 nghìn" -> Di chuyển, 70.000đ',
        '• "Taxi 70k" -> Transport',
      ),
      tr(
        '• "Tiền điện 600 nghìn" -> Hóa đơn, 600.000đ',
        '• "Internet bill 600k" -> Bills & Utilities',
      ),
      tr(
        '• "Lương tháng này 18 triệu" -> Thu nhập, 18.000.000đ',
        '• "Salary 18m" -> Income, 18,000,000đ',
      ),
      tr(
        '• "Hôm nay tôi đã tiêu bao nhiêu?" -> Báo cáo ngày',
        '• "How much did I spend today?" -> Daily summary',
      ),
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.record_voice_over_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr('Mẹo Lệnh Giọng Nói', 'Voice Command Tips'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(
                'Ứng dụng nhận diện từ ngữ hàng ngày cực nhanh:',
                'Speak naturally to log expenses or ask questions:',
              ),
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ...examples.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  item,
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              tr('Đã hiểu', 'Got it'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          tr('Đăng xuất tài khoản?', 'Sign out of account?'),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          tr(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản hiện tại?',
            'Are you sure you want to sign out of your current account?',
          ),
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              tr('Hủy', 'Cancel'),
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onLogout();
            },
            child: Text(tr('Đăng xuất', 'Sign Out')),
          ),
        ],
      ),
    );
  }
}
