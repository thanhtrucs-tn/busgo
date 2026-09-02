// register_screen.dart
// Màn hình ĐĂNG KÝ TÀI KHOẢN của ứng dụng BusGo.
//
// Người dùng nhập TÊN ĐĂNG NHẬP và MẬT KHẨU để tạo tài khoản mới.
// Dữ liệu được gửi lên API /api/auth/register (backend Node.js + MySQL)
// rồi lưu vào bảng users của database TEST_123.
//
// Luồng hoạt động:
//  Đăng ký thành công -> quay về màn hình đăng nhập
//  và tự động điền sẵn tên đăng nhập vừa tạo.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Quản lý trạng thái và kiểm tra dữ liệu của biểu mẫu.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Bộ điều khiển ô nhập dữ liệu.
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  // Ẩn/hiện mật khẩu khi nhập.
  bool _obscurePassword = true;

  // Đang xử lý đăng ký hay không (hiện vòng xoay tải).
  bool _isLoading = false;

  @override
  void dispose() {
    // Giải phóng bộ điều khiển để tránh rò rỉ bộ nhớ.
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Xử lý nút "ĐĂNG KÝ".
  Future<void> _handleRegister() async {
    // Dừng nếu dữ liệu chưa hợp lệ.
    if (!_formKey.currentState!.validate()) return;

    // Chống bấm gửi nhiều lần khi đang xử lý.
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final email = _emailController.text.trim();

    // Gọi API đăng ký tài khoản trên máy chủ.
    // Backend: kiểm tra trùng tên/email, băm mật khẩu bcrypt,
    // lưu database TEST_123, tạo JWT (đăng ký xong là đã có token).
    final result = await AuthService.instance.register(
      username: username,
      password: password,
      email: email,
    );

    // Bảo vệ: tránh dùng context sau khi màn hình đã bị hủy.
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      // Đăng ký thành công: quay về màn hình đăng nhập,
      // đồng thời trả về tên đăng nhập để bên kia điền sẵn (autofill).
      // Ví dụ: vừa đăng ký tài khoản "abc" -> màn hình đăng nhập điền sẵn "abc".
      Navigator.of(context).pop(username);
    } else {
      // Hiện thông báo lỗi trả về từ máy chủ.
      // Ví dụ: "Tên đăng nhập đã tồn tại, vui lòng chọn tên khác".
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký tài khoản')),
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
                  // Tiêu đề giới thiệu màn hình.
                  Text(
                    'Tạo tài khoản mới',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nhập tên đăng nhập và mật khẩu để bắt đầu',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Ô nhập TÊN ĐĂNG NHẬP (tối đa 32 ký tự, chỉ chữ/số/gạch dưới).
                  TextFormField(
                    controller: _usernameController,
                    maxLength: 32,
                    textInputAction: TextInputAction.next,
                    // Chặn gõ ký tự đặc biệt / khoảng trắng ngay khi nhập.
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9_]'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập',
                      hintText: 'Chữ, số, gạch dưới · 3-32 ký tự',
                      prefixIcon: Icon(Icons.person_outline),
                      counterText: '',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Vui lòng nhập tên đăng nhập';
                      if (text.length < 3 || text.length > 32) {
                        return 'Tên đăng nhập phải có từ 3 đến 32 ký tự';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(text)) {
                        return 'Tên đăng nhập chỉ gồm chữ cái, số và dấu gạch dưới';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Ô nhập EMAIL (TÙY CHỌN, tối đa 48 ký tự).
                  // Nếu có email, có thể đăng nhập bằng email và dùng
                  // cho các tính năng khác sau này. Không bắt buộc.
                  TextFormField(
                    controller: _emailController,
                    maxLength: 48,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Email (không bắt buộc)',
                      prefixIcon: Icon(Icons.email_outlined),
                      counterText: '',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null; // Không bắt buộc
                      if (text.length > 48) {
                        return 'Email tối đa 48 ký tự';
                      }
                      // Kiểm tra định dạng, ví dụ: abc@example.com.
                      final regex = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      );
                      if (!regex.hasMatch(text)) {
                        return 'Email không đúng định dạng, ví dụ: abc@example.com';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Ô nhập MẬT KHẨU (tối đa 64 ký tự theo database).
                  TextFormField(
                    controller: _passwordController,
                    maxLength: 64,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      hintText: 'Từ 6 đến 64 ký tự',
                      prefixIcon: const Icon(Icons.lock_outline),
                      counterText: '',
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
                      if (text.length < 6 || text.length > 64) {
                        return 'Mật khẩu phải có từ 6 đến 64 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Ô nhập lại MẬT KHẨU để xác nhận (tránh gõ sai).
                  TextFormField(
                    controller: _confirmController,
                    maxLength: 64,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleRegister(),
                    decoration: const InputDecoration(
                      labelText: 'Xác nhận mật khẩu',
                      hintText: 'Nhập lại mật khẩu',
                      prefixIcon: Icon(Icons.lock_outline),
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng xác nhận mật khẩu';
                      }
                      if (value != _passwordController.text) {
                        return 'Mật khẩu xác nhận không khớp';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Nút "ĐĂNG KÝ" (hiện vòng xoay khi đang xử lý).
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _handleRegister,
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
                              'ĐĂNG KÝ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
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
