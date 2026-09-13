// google_sign_in_button.dart
// Nút "Đăng nhập nhanh bằng Google" dùng chung cho màn hình Đăng nhập
// và Đăng ký. Tự chọn đúng giao diện theo nền tảng:
//   - Android/iOS/macOS : nút trắng tự vẽ, mở hộp thoại chọn tài khoản Google.
//   - Web               : đúng widget GSI renderButton() (Google bắt buộc).
//   - Windows/Linux...  : không hiện gì (plugin không hỗ trợ).
//
// Sau khi có được ID token, widget gọi callback onIdToken để màn hình
// đưa token lên backend (POST /api/auth/google) và kiểm soát điều hướng.
//
// ID token gửi lên server là MẬT đối với server: server tự xác minh với
// Google, app KHÔNG được tự coi token là đã xác thực.

import 'package:flutter/material.dart';

import 'google_sign_in_button_stub.dart'
    if (dart.library.js_interop) 'google_sign_in_button_web.dart'
    as google_button;

/// Nút đăng nhập nhanh bằng Google.
///
/// [onIdToken]  : gọi khi có ID token hợp lệ từ Google, màn hình gửi lên server.
/// [onError]    : gọi khi Google thất bại (hủy chọn thì KHÔNG gọi).
/// [label]      : chữ hiển thị trên nút (khác nhau giữa màn hình Đăng nhập/Đăng ký).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onIdToken,
    this.onError,
    required this.label,
  });

  final ValueChanged<String> onIdToken;
  final ValueChanged<String>? onError;
  final String label;

  @override
  Widget build(BuildContext context) {
    return google_button.buildGoogleSignInButton(
      label: label,
      onIdToken: onIdToken,
      onError: onError,
    );
  }
}
