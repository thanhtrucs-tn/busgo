// google_sign_in_button_web.dart
// Bản triển khai cho nền tảng WEB (chỉ được biên dịch trên web nhờ
// conditional import trong google_sign_in_button.dart).
//
// GSI SDK không cho phép nút tự vẽ: bắt buộc dùng đúng widget
// google_sign_in_web.renderButton(). ID token đến qua stream
// authenticationEvents của GoogleSignIn.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;

import '../config/google_config.dart';

// Nền tảng Web luôn hiện nút Google (nếu đã cấu hình client ID).
Widget buildGoogleSignInButton({
  required String label,
  required ValueChanged<String> onIdToken,
  ValueChanged<String>? onError,
}) {
  return _WebGoogleButton(onIdToken: onIdToken, onError: onError);
}

// GoogleSignIn chỉ được initialize() MỘT lần trong cả vòng đời app.
bool _initialized = false;

Future<void> _initializeWeb() async {
  if (_initialized) return;
  _initialized = true;

  // Web KHÔNG hỗ trợ serverClientId (assert sẽ lỗi nếu truyền vào),
  // chỉ cần clientId loại "Web application".
  final clientId = GoogleConfig.webClientId.trim();
  await GoogleSignIn.instance.initialize(
    clientId: clientId.isEmpty ? null : clientId,
  );
}

class _WebGoogleButton extends StatefulWidget {
  const _WebGoogleButton({required this.onIdToken, this.onError});

  final ValueChanged<String> onIdToken;
  final ValueChanged<String>? onError;

  @override
  State<_WebGoogleButton> createState() => _WebGoogleButtonState();
}

class _WebGoogleButtonState extends State<_WebGoogleButton> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _initializeWeb();

      // Lắng nghe kết quả đăng nhập từ nút GSI chính thức.
      _subscription = GoogleSignIn.instance.authenticationEvents.listen((
        event,
      ) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          final idToken = event.user.authentication.idToken;
          if (idToken != null && idToken.isNotEmpty && mounted) {
            widget.onIdToken(idToken);
          }
        }
      });
    } catch (_) {
      // Bỏ qua lỗi cấu hình: hiện thông báo qua onError khi cần.
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }
    // Nút "Sign in with Google" chuẩn do Google vẽ.
    return gsi_web.renderButton();
  }
}
