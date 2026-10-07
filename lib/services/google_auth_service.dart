

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/google_config.dart';

class GoogleAuthService {
  // Singleton: chỉ có một đối tượng duy nhất trong cả ứng dụng.
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  // GoogleSignIn chỉ cho phép initialize() đúng MỘT lần trong vòng đời app.
  bool _initialized = false;

  // Nền tảng hiện tại có dùng được luồng GoogleSignIn authenticate() không?
  // Web và Windows/Linux không nằm trong danh sách này.
  bool get canSignInWithGoogle =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  // Cho biết có nên hiện nút "Đăng nhập bằng Google" không:
  // Android/iOS/macOS + Web hiện; Windows/Linux và nền tảng khác ẩn.
  bool get isGoogleSignInAvailable => canSignInWithGoogle || kIsWeb;

  // Khởi tạo plugin Google Sign-In (tối đa 1 lần).
  //  - clientId       : OAuth client ID loại Android (tùy chọn).
  //  - serverClientId : OAuth client ID loại Web - server dùng để xác minh token.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await GoogleSignIn.instance.initialize(
      clientId: _nonEmpty(GoogleConfig.androidClientId),
      serverClientId: _nonEmpty(GoogleConfig.webClientId),
    );
  }

  // Mở hộp thoại Google để người dùng chọn tài khoản (chỉ Android/iOS/macOS).
  // - Thành công  -> trả về tài khoản Google (lấy authentication.idToken).
  // - Người dùng hủy -> trả về null (không phải lỗi).
  Future<GoogleSignInAccount?> signInInteractive() async {
    await initialize();
    try {
      return await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      // Hủy chọn tài khoản thì coi như không làm gì, không coi là lỗi.
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  String? _nonEmpty(String value) => value.trim().isEmpty ? null : value.trim();
}
