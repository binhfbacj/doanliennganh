import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';
import '../utils/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onFinish();
    }
  }

  BoxDecoration _cardBox() => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(32),
    border: Border.all(color: AppColors.border, width: 1.2),
  );

  @override
  Widget build(BuildContext context) {
    final slides = [
      (
        tr(
          'Tiền Biến Mất Trước Khi\nBạn Nhận Ra?',
          'Does Your Money Disappear\nBefore You Notice?',
        ),
        tr(
          'Bạn quên theo dõi chi phí, hóa đơn ngày càng nhiều và bạn không bao giờ biết chắc tiền của mình thực sự đi về đâu.',
          'Forgotten expenses and mounting bills make it hard to know where your hard-earned money actually goes.',
        ),
        _buildSlide1Illustration(),
      ),
      (
        tr(
          'Kiểm Soát Tiền Của Bạn\nNgay Hôm Nay',
          'Take Full Control of Your\nFinances Today',
        ),
        tr(
          'Theo dõi chi phí trong vài giây, xem tiền của bạn được chi vào đâu và kiểm soát ngân sách mà không bị căng thẳng.',
          'Track expenses in seconds, visualize your spending habits, and stay on top of your budget stress-free.',
        ),
        _buildSlide2Illustration(),
      ),
      (
        tr(
          'Ghi Chép Bằng Giọng Nói AI\nSiêu Nhanh',
          'Super Fast AI Voice\nExpense Logging',
        ),
        tr(
          'Chỉ cần bấm micro và nói tự nhiên: "Ăn sáng 35k", "Đổ xăng 70k" — AI sẽ tự động phân loại và lưu lại ngay lập tức.',
          'Just tap the mic and say "Breakfast 35k" or "Gas 70k" — AI automatically categorizes and logs it for you.',
        ),
        _buildSlide3Illustration(),
      ),
      (
        tr(
          'Nhận Phân Tích Thông Minh\nTừ Chú Ong 🐝',
          'Smart Spending Insights\nfrom Smart Bee 🐝',
        ),
        tr(
          'Phân tích thói quen chi tiêu của bạn và nhận lời khuyên ngân sách cá nhân hóa mỗi ngày.',
          'Analyze your spending habits and get personalized budget advice every day.',
        ),
        _buildSlide4Illustration(),
      ),
      (
        tr(
          'Sẵn Sàng Làm Chủ\nTài Chính Cá Nhân',
          'Ready to Master Your\nPersonal Finances',
        ),
        tr(
          'Bắt đầu ghi chép các khoản chi tiêu thật của bạn ngay hôm nay để xây dựng hũ mật tiết kiệm vững chắc!',
          'Start tracking your daily expenses today and build your golden honey jar of savings!',
        ),
        _buildSlide5Illustration(),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 64),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 1.2),
                    ),
                    child: Text(
                      '${_currentPage + 1} / $_totalPages',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onFinish,
                    child: Text(
                      tr('Bỏ qua', 'Skip'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: slides.length,
                itemBuilder: (_, i) => _buildSlide(
                  title: slides[i].$1,
                  subtitle: slides[i].$2,
                  illustration: slides[i].$3,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(_totalPages, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  GestureDetector(
                    onTap: _nextPage,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.beeGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _currentPage == _totalPages - 1
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        color: AppColors.onPrimary,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide({
    required String title,
    required String subtitle,
    required Widget illustration,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 345),
                  child: illustration,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide1Illustration() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardBox(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _glowingQuestion('?', 32, AppColors.primary, 0.5),
              const SizedBox(width: 24),
              _glowingQuestion('?', 48, AppColors.expense, 0.7),
              const SizedBox(width: 24),
              _glowingQuestion('?', 32, AppColors.primaryDark, 0.5),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 3),
            ),
            child: const Center(
              child: Text('🤔', style: TextStyle(fontSize: 62)),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.expense.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.expense.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.trending_down_rounded,
                  color: AppColors.expense,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  tr('Tiền đi đâu mất rồi?', 'Where did all my money go?'),
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowingQuestion(
    String q,
    double fontSize,
    Color color,
    double glowAlpha,
  ) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: glowAlpha),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        q,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSlide2Illustration() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardBox(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.beeGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'FINANCIAL FREEDOM 🐝',
              style: TextStyle(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Container(
            width: 8,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.45),
                width: 3,
              ),
            ),
            child: const Center(
              child: Text('🐝✨', style: TextStyle(fontSize: 44)),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            tr(
              'Làm chủ ví tiền & Tiết kiệm thông minh',
              'Master your wallet & Save smartly',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide3Illustration() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardBox(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.beeGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 24,
                  spreadRadius: 4,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.mic_rounded,
              color: AppColors.onPrimary,
              size: 42,
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                tr('🎙️ "Ăn sáng 35k"', '🎙️ "Breakfast 35k"'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.income.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.income.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.income,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(
                          'Đã nhận diện: Ăn uống',
                          'Recognized: Food & Dining',
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.income,
                        ),
                      ),
                      Text(
                        tr(
                          'Số tiền: -35.000 ₫ (Tự động lưu)',
                          'Amount: -35,000 ₫ (Auto-saved)',
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide4Illustration() {
    final bullets = [
      (tr('Hóa đơn & Nhà:', 'Bills & Rent:'), '8.000.000₫', AppColors.primary),
      (tr('Ăn uống:', 'Food & Dining:'), '2.500.000₫', AppColors.expense),
      (tr('Mua sắm:', 'Shopping:'), '1.250.000₫', AppColors.income),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardBox(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: Text('🐝', style: TextStyle(fontSize: 36))),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                tr(
                  'Tháng này tôi đã tiêu bao nhiêu?',
                  'How much did I spend this month?',
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(
                    'Tháng này bạn đã chi 11.750.000₫. Dưới đây là các danh mục lớn nhất:',
                    'You spent 11,750,000₫ this month. Here are your top categories:',
                  ),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                for (final b in bullets)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: b.$3,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${b.$1} ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          b.$2,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide5Illustration() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _cardBox(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              gradient: AppColors.beeGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 28,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: AppColors.onPrimary,
              size: 54,
            ),
          ),
          const SizedBox(height: 20),
          const Text('🐝  🍯  ✨', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 14),
          Text(
            tr('Mọi thứ đã sẵn sàng!', 'Everything is Ready!'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tr(
              'Hãy bấm nút dấu tích để vào ngay Trang chủ quản lý chi tiêu.',
              'Tap the check button below to enter your Smart Bee Home.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
