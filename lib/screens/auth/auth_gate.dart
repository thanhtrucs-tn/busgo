// auth_gate.dart
// Cổng kiểm tra SESSION khi mở ứng dụng - màn hình đầu tiên của app.
//
// Quy trình (theo yêu cầu "KIỂM TRA SESSION"):
//   1. Kiểm tra token trong secure storage.
//   2. Nếu KHÔNG có token        -> hiện màn hình Đăng nhập.
//   3. Nếu CÓ token              -> gọi GET /api/auth/me.
//   4. Token hợp lệ              -> vào thẳng Trang chủ.
//   5. Token hết hạn / không đúng -> xóa token -> hiện màn hình Đăng nhập.
//
// Trong lúc kiểm tra, hiện màn hình chờ (logo + vòng xoay) để
// không bị "nháy" giữa các màn hình.

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Hướng đi sau khi kiểm tra xong: 'home' hoặc 'login'.
  String? _destination;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  // Kiểm tra token và quyết định hướng đi.
  Future<void> _checkSession() async {
    final result = await AuthService.instance.checkSession();

    if (!mounted) return;

    if (result.success && result.user != null) {
      // Token hợp lệ -> khôi phục phiên và vào Trang chủ.
      SessionService.instance.login(result.user!);
      setState(() => _destination = 'home');
    } else {
      // Không có token / token hết hạn / lỗi mạng -> vào màn hình Đăng nhập.
      setState(() => _destination = 'login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Đang kiểm tra: hiện màn hình chờ.
    if (_destination == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo BusGo quen thuộc.
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: colors.onPrimary,
                  size: 46,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'BusGo',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      );
    }

    // Đã xác định hướng: Trang chủ hoặc màn hình Đăng nhập.
    return _destination == 'home'
        ? const HomeScreen()
        : const LoginScreen();
  }
}