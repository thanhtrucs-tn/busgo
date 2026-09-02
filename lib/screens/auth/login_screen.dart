// login_screen.dart
// Màn hình ĐĂNG NHẬP của ứng dụng BusGo.
//
// Đặc điểm thiết kế (theo yêu cầu):
//  - Chỉ đăng nhập bằng tên đăng nhập + mật khẩu lưu trong MySQL.
//  - KHÔNG có phần "Quên mật khẩu".
//  - KHÔNG có nút "Đăng nhập bằng Google".
//  - Có ô tick "Ghi nhớ đăng nhập": khi tích, tên đăng nhập được lưu lại
//    và sẽ tự điền sẵn (autofill) vào lần sau kể cả sau khi đăng xuất.
//
// Luồng chuyển màn hình:
//  Đăng nhập thành công -> vào thẳng Trang chủ (HomeScreen, có chữ "Hello").
//  Bấm "Đăng ký"         -> mở RegisterScreen.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/remember_me_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Quản lý trạng thái và kiểm tra dữ liệu của biểu mẫu.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Bộ điều khiển nội dung ô nhập tên đăng nhập và mật khẩu.
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Trạng thái tick của ô "Ghi nhớ đăng nhập".
  bool _rememberMe = false;

  // Ẩn/hiện mật khẩu khi nhập (bảo mật khi ở nơi đông người).
  bool _obscurePassword = true;

  // Đang xử lý đăng nhập hay không (hiện vòng xoay tải).
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _applyRememberedData();
  }

  @override
  void dispose() {
    // Giải phóng bộ điều khiển để tránh rò rỉ bộ nhớ.
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Điền sẵn tên đăng nhập đã được ghi nhớ từ lần trước (autofill).
  // Ví dụ: trước đó tick "Ghi nhớ", đăng nhập rồi đăng xuất -> vẫn thấy tên cũ.
  void _applyRememberedData() {
    _rememberMe = RememberMeService.instance.enabled;
    _usernameController.text = RememberMeService.instance.username;
  }

  // Xử lý nút "ĐĂNG NHẬP".
  Future<void> _handleLogin() async {
    // Dừng nếu dữ liệu chưa hợp lệ (validator sẽ hiện thông báo lỗi).
    if (!_formKey.currentState!.validate()) return;

    // Chống bấm gửi nhiều lần khi đang xử lý.
    if (_isLoading) return;
    setState(() => _isLoading = true);

    // Lấy dữ liệu từ ô nhập (tên đăng nhập HOẶC email).
    final identifier = _usernameController.text.trim();
    final password = _passwordController.text;

    // Gọi API đăng nhập trên máy chủ:
    // backend kiểm tra tài khoản + mật khẩu (bcrypt), tạo JWT,
    // AuthService lưu token vào secure storage và trả về user.
    final result = await AuthService.instance.login(
      identifier: identifier,
      password: password,
    );

    // Bảo vệ: tránh dùng context sau khi màn hình đã bị hủy.
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      // Lưu (hoặc xóa) tên đăng nhập tùy theo ô tích "Ghi nhớ đăng nhập".
      await RememberMeService.instance.saveRemembered(
        remembered: _rememberMe,
        username: identifier,
      );

      // Ghi nhận phiên đăng nhập để các màn hình khác dùng chung.
      if (result.user != null) {
        SessionService.instance.login(result.user!);
      }

      // Bảo vệ: kiểm tra lại sau khi await để không dùng context đã bị hủy.
      if (!mounted) return;

      // Vào thẳng Trang chủ (có chữ "Hello" và nút đăng xuất).
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      // Bảo vệ: kiểm tra lại sau khi await để không dùng context đã bị hủy.
      if (!mounted) return;

      // Hiện thông báo lỗi trả về từ máy chủ, ví dụ: "Tên đăng nhập hoặc mật khẩu không đúng".
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  // Mở màn hình đăng ký; khi đăng ký thành công, tự điền tên vừa đăng ký.
  Future<void> _openRegister() async {
    final newUsername = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const RegisterScreen()));
    if (newUsername != null && mounted) {
      _usernameController.text = newUsername;
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo hình tròn giống với trang chủ (thương hiệu BusGo).
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_bus,
                        color: colors.onPrimary,
                        size: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Tiêu đề màn hình.
                  Text(
                    'Đăng nhập BusGo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chào mừng bạn quay trở lại',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Ô nhập TÊN ĐĂNG NHẬP (hoặc email).
                  // maxLength đủ cho cả username (32) lẫn email (48).
                  TextFormField(
                    controller: _usernameController,
                    maxLength: 48,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập',
                      hintText: 'Tên đăng nhập hoặc email',
                      prefixIcon: Icon(Icons.person_outline),
                      counterText: '', // Ẩn bộ đếm ký tự cho gọn giao diện.
                    ),
                    // Kiểm tra hợp lệ trước khi gửi lên máy chủ.
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Vui lòng nhập tên đăng nhập';
                      if (text.length < 3) {
                        return 'Tên đăng nhập tối thiểu 3 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Ô nhập MẬT KHẨU.
                  // maxLength 64 khớp với giới hạn mật khẩu đã mã hóa trong database.
                  TextFormField(
                    controller: _passwordController,
                    maxLength: 64,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      hintText: 'Nhập mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      counterText: '',
                      // Nút con mắt để ẩn/hiện mật khẩu.
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final text = value ?? '';
                      if (text.isEmpty) return 'Vui lòng nhập mật khẩu';
                      if (text.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                      return null;
                    },
                  ),

                  // Ô tick "Ghi nhớ đăng nhập".
                  // Khi tích: lưu tên đăng nhập để sau đăng xuất/mở lại vẫn điền sẵn.
                  CheckboxListTile(
                    value: _rememberMe,
                    onChanged: (value) =>
                        setState(() => _rememberMe = value ?? false),
                    title: const Text('Ghi nhớ đăng nhập'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  const SizedBox(height: 6),

                  // Nút "ĐĂNG NHẬP" (hiện vòng xoay khi đang xử lý).
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'ĐĂNG NHẬP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Đường dẫn chuyển sang màn hình đăng ký tài khoản mới.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Chưa có tài khoản?',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                      TextButton(
                        onPressed: _openRegister,
                        child: const Text('Đăng ký ngay'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
