import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/app_localizations.dart';
import '../utils/app_theme.dart';

class AuthScreen extends StatefulWidget {
  final Function(UserModel user) onAuthSuccess;

  const AuthScreen({super.key, required this.onAuthSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isRegisterMode = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_isRegisterMode) {
      final name = _nameController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();

      if (name.isEmpty) {
        return _showSnack(
          tr(
            'Vui lòng nhập họ và tên của bạn.',
            'Please enter your full name.',
          ),
          isError: true,
        );
      }
      if (email.isEmpty || !email.contains('@')) {
        return _showSnack(
          tr(
            'Vui lòng nhập địa chỉ email hợp lệ.',
            'Please enter a valid email address.',
          ),
          isError: true,
        );
      }
      if (password.length < 6) {
        return _showSnack(
          tr(
            'Mật khẩu cần tối thiểu 6 ký tự.',
            'Password must be at least 6 characters.',
          ),
          isError: true,
        );
      }
      if (password != confirmPassword) {
        return _showSnack(
          tr(
            'Mật khẩu nhập lại không khớp. Vui lòng kiểm tra lại!',
            'Passwords do not match. Please check again!',
          ),
          isError: true,
        );
      }

      setState(() => _isLoading = true);
      final res = await AuthService.instance.register(
        name: name,
        email: email,
        password: password,
      );
      setState(() => _isLoading = false);

      if (res.success && res.user != null) {
        if (!mounted) return;
        _showSnack(
          tr(
            'Tạo tài khoản thành công! Chào mừng bạn.',
            'Account created successfully! Welcome.',
          ),
        );
        widget.onAuthSuccess(res.user!);
      } else {
        _showSnack(
          res.message ?? tr('Đăng ký thất bại.', 'Sign up failed.'),
          isError: true,
        );
      }
    } else {
      if (email.isEmpty || password.isEmpty) {
        return _showSnack(
          tr(
            'Vui lòng điền email và mật khẩu.',
            'Please enter your email and password.',
          ),
          isError: true,
        );
      }

      setState(() => _isLoading = true);
      final res = await AuthService.instance.login(
        email: email,
        password: password,
      );
      setState(() => _isLoading = false);

      if (res.success && res.user != null) {
        if (!mounted) return;
        _showSnack(tr('Đăng nhập thành công!', 'Signed in successfully!'));
        widget.onAuthSuccess(res.user!);
      } else {
        _showSnack(
          res.message ?? tr('Đăng nhập không thành công.', 'Sign in failed.'),
          isError: true,
        );
      }
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);
    final res = await AuthService.instance.register(
      name: tr('Chú Ong Mới', 'Smart Bee Guest'),
      email:
          'guest_${DateTime.now().millisecondsSinceEpoch}@caitieuthongminh.vn',
      password: 'guest_password_123',
    );
    setState(() => _isLoading = false);

    if (res.success && res.user != null && mounted) {
      widget.onAuthSuccess(res.user!);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    final fg = isError ? Colors.white : AppColors.onPrimary;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: fg,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: fg,
                  fontWeight: isError ? null : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.expense : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      _buildTabSwitcher(),
                      const SizedBox(height: 20),
                      _buildFormCard(),
                      const SizedBox(height: 20),
                      _buildGuestButton(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.beeGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 44),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.onPrimary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.onPrimary.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Text('🐝', style: TextStyle(fontSize: 38)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('Chú Ong Chi Tiêu', 'Smart Bee Finance'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      'Quản lý tài chính & Ghi chép bằng Giọng nói AI',
                      'Smart Expense Tracking & AI Voice Assistant',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.onPrimary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
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

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              tr('Tạo tài khoản', 'Create Account'),
              _isRegisterMode,
              () => setState(() => _isRegisterMode = true),
            ),
          ),
          Expanded(
            child: _buildTab(
              tr('Đăng nhập', 'Sign In'),
              !_isRegisterMode,
              () => setState(() => _isRegisterMode = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: active ? AppColors.beeGradient : null,
          borderRadius: BorderRadius.circular(13),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active ? AppColors.onPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark ? 0.45 : 0.06,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isRegisterMode) ...[
            _buildInputField(
              label: tr('Họ và tên', 'Full Name'),
              controller: _nameController,
              hint: tr('Ví dụ: Nguyễn Văn An', 'e.g. Alex Nguyen'),
              icon: Icons.person_outline_rounded,
              capitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
            ),
            const SizedBox(height: 16),
          ],
          _buildInputField(
            label: tr('Địa chỉ Email', 'Email Address'),
            controller: _emailController,
            hint: 'name@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email, AutofillHints.username],
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: tr('Mật khẩu', 'Password'),
            controller: _passwordController,
            hint: tr('Tối thiểu 6 ký tự', 'At least 6 characters'),
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            autofillHints: _isRegisterMode
                ? const [AutofillHints.newPassword]
                : const [AutofillHints.password],
            onToggleObscure: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          if (_isRegisterMode) ...[
            const SizedBox(height: 16),
            _buildInputField(
              label: tr('Xác nhận lại mật khẩu', 'Confirm Password'),
              controller: _confirmPasswordController,
              hint: tr('Nhập lại mật khẩu ở trên', 'Re-enter your password'),
              icon: Icons.lock_reset_rounded,
              obscure: _obscureConfirmPassword,
              autofillHints: const [AutofillHints.newPassword],
              onToggleObscure: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    bool obscure = false,
    Iterable<String>? autofillHints,
    VoidCallback? onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: capitalization,
          obscureText: obscure,
          autofillHints: autofillHints,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            fillColor: AppColors.background,
            prefixIcon: Icon(icon, color: AppColors.textMuted),
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _isLoading ? null : _submit,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: _isLoading ? null : AppColors.beeGradient,
              color: _isLoading ? AppColors.border : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isLoading
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: AppColors.onPrimary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      _isRegisterMode
                          ? tr('Đăng Ký Tài Khoản', 'Create Account')
                          : tr('Đăng Nhập Ngay', 'Sign In Now'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _continueAsGuest,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundColor: AppColors.primaryDark,
        ),
        icon: const Icon(
          Icons.bolt_rounded,
          size: 18,
          color: AppColors.primaryDark,
        ),
        label: Text(
          tr(
            'Trải nghiệm nhanh không cần đăng ký',
            'Continue as Guest without signing up',
          ),
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
