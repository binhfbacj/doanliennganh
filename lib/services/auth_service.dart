import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/app_localizations.dart';

class AuthResult {
  final bool success;
  final String? message;
  final UserModel? user;

  const AuthResult({required this.success, this.message, this.user});
}

class AuthService {
  static const String _keyCurrentUser = 'app_current_user';
  static const String _keyRegisteredUsers = 'app_registered_users';

  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  /// Lấy thông tin người dùng đang đăng nhập
  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyCurrentUser);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      return UserModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  /// Đăng ký tài khoản mới
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cleanName = name.trim();
      final cleanEmail = email.trim().toLowerCase();
      final cleanPassword = password.trim();

      if (cleanName.isEmpty) {
        return AuthResult(
          success: false,
          message: tr(
            'Vui lòng nhập họ và tên của bạn.',
            'Please enter your full name.',
          ),
        );
      }

      if (cleanEmail.isEmpty ||
          !cleanEmail.contains('@') ||
          !cleanEmail.contains('.')) {
        return AuthResult(
          success: false,
          message: tr('Định dạng email không hợp lệ.', 'Invalid email format.'),
        );
      }

      if (cleanPassword.length < 6) {
        return AuthResult(
          success: false,
          message: tr(
            'Mật khẩu phải có ít nhất 6 ký tự.',
            'Password must be at least 6 characters.',
          ),
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final usersMap = _getUsersMap(prefs);

      // Kiểm tra email đã đăng ký chưa
      if (usersMap.containsKey(cleanEmail)) {
        return AuthResult(
          success: false,
          message: tr(
            'Email này đã được sử dụng. Vui lòng đăng nhập hoặc dùng email khác.',
            'This email is already in use. Please log in or use a different email.',
          ),
        );
      }

      // Tạo user mới
      final newUser = UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: cleanName,
        email: cleanEmail,
        createdAt: DateTime.now(),
      );

      // Lưu thông tin đăng nhập
      usersMap[cleanEmail] = {
        'password': cleanPassword,
        'user': newUser.toJson(),
      };
      await prefs.setString(_keyRegisteredUsers, jsonEncode(usersMap));

      // Đặt làm tài khoản đang hoạt động
      await prefs.setString(_keyCurrentUser, jsonEncode(newUser.toJson()));

      return AuthResult(
        success: true,
        user: newUser,
        message: tr(
          'Đăng ký tài khoản thành công!',
          'Account registered successfully!',
        ),
      );
    } catch (e) {
      debugPrint('Error registering user: $e');
      return AuthResult(
        success: false,
        message: tr(
          'Lỗi khi đăng ký tài khoản: $e',
          'Error registering account: $e',
        ),
      );
    }
  }

  /// Đăng nhập tài khoản
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanPassword = password.trim();

      if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
        return AuthResult(
          success: false,
          message: tr(
            'Vui lòng nhập đầy đủ email và mật khẩu.',
            'Please enter both email and password.',
          ),
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final usersMap = _getUsersMap(prefs);

      if (!usersMap.containsKey(cleanEmail)) {
        return AuthResult(
          success: false,
          message: tr(
            'Tài khoản không tồn tại. Vui lòng chuyển sang tab Đăng ký.',
            'Account not found. Please switch to the Register tab.',
          ),
        );
      }

      final userRecord = usersMap[cleanEmail] as Map<String, dynamic>;
      final savedPassword = userRecord['password'] as String? ?? '';

      if (savedPassword != cleanPassword) {
        return AuthResult(
          success: false,
          message: tr(
            'Mật khẩu không chính xác. Vui lòng thử lại.',
            'Incorrect password. Please try again.',
          ),
        );
      }

      final user = UserModel.fromJson(
        userRecord['user'] as Map<String, dynamic>,
      );

      // Lưu phiên đăng nhập
      await prefs.setString(_keyCurrentUser, jsonEncode(user.toJson()));

      return AuthResult(
        success: true,
        user: user,
        message: tr('Đăng nhập thành công!', 'Logged in successfully!'),
      );
    } catch (e) {
      debugPrint('Error logging in: $e');
      return AuthResult(
        success: false,
        message: tr('Lỗi khi đăng nhập: $e', 'Error logging in: $e'),
      );
    }
  }

  /// Đăng xuất khỏi tài khoản
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyCurrentUser);
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }

  Map<String, dynamic> _getUsersMap(SharedPreferences prefs) {
    final str = prefs.getString(_keyRegisteredUsers);
    if (str == null || str.isEmpty) return {};
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
