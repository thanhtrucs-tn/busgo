// google_sign_in_button_stub.dart
// Bản triển khai cho các nền tảng KHÔNG phải Web (Android/iOS/macOS/desktop).
// File web thật sự là google_sign_in_button_web.dart (xem conditional import
// trong google_sign_in_button.dart).

import 'package:flutter/material.dart';

import '../services/google_auth_service.dart';

// Hiện nút Google theo kiểu native nếu nền tảng hỗ trợ,
// ngược lại (Windows/Linux) không hiện gì.
Widget buildGoogleSignInButton({
  required String label,
  required ValueChanged<String> onIdToken,
  ValueChanged<String>? onError,
}) {
  if (!GoogleAuthService.instance.canSignInWithGoogle) {
    return const SizedBox.shrink();
  }
  return _NativeGoogleButton(
    label: label,
    onIdToken: onIdToken,
    onError: onError,
  );
}

class _NativeGoogleButton extends StatefulWidget {
  const _NativeGoogleButton({
    required this.label,
    required this.onIdToken,
    this.onError,
  });

  final String label;
  final ValueChanged<String> onIdToken;
  final ValueChanged<String>? onError;

  @override
  State<_NativeGoogleButton> createState() => _NativeGoogleButtonState();
}

class _NativeGoogleButtonState extends State<_NativeGoogleButton> {
  // Chống bấm nhiều lần trong lúc hộp thoại Google đang mở.
  bool _busy = false;

  Future<void> _handlePress() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      // Mở hộp thoại chọn tài khoản Google (Android/iOS/macOS).
      final account = await GoogleAuthService.instance.signInInteractive();
      if (account == null) {
        // Người dùng tự hủy chọn tài khoản -> không làm gì thêm.
        return;
      }
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        widget.onError?.call('Không nhận được mã xác thực từ Google');
        return;
      }
      widget.onIdToken(idToken);
    } on Exception {
      widget.onError?.call(
        'Đăng nhập bằng Google thất bại, hãy kiểm tra cấu hình Google OAuth',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 52,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _busy ? null : _handlePress,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_busy)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else ...[
                // Logo Google đơn giản (chữ G màu xanh đặc trưng).
                const _GoogleLogo(),
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Chữ "G" màu xanh Google làm logo đơn giản (không cần thêm asset ảnh).
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF4285F4),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
