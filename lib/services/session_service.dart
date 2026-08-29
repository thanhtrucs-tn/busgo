// session_service.dart
// Quản lý PHIÊN ĐĂNG NHẬP hiện tại của ứng dụng.
// Giữ thông tin tài khoản đang đăng nhập để các màn hình khác
// dùng chung (ví dụ: hiển thị lời chào "Hello, <tên>" trên trang chủ).
//
// Khác biệt với RememberMeService:
//  - RememberMeService: lưu TÊN tài khoản để autofill ô đăng nhập.
//  - SessionService: giữ tài khoản đang ĐĂNG NHẬP trong phiên làm việc.
//
// Khi người dùng đăng xuất -> logout() -> màn hình quay về đăng nhập,
// nhưng tên ghi nhớ (RememberMeService) vẫn còn để autofill.

import 'package:flutter/foundation.dart';

import '../models/user_account.dart';

class SessionService extends ChangeNotifier {
  // Singleton: chỉ có một đối tượng duy nhất trong cả ứng dụng.
  SessionService._();
  static final SessionService instance = SessionService._();

  // Tài khoản đang đăng nhập (null nghĩa là chưa đăng nhập).
  UserAccount? _currentUser;

  UserAccount? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Lưu tài khoản vừa đăng nhập thành công vào phiên hiện tại.
  // Ví dụ: SessionService.instance.login(user);
  void login(UserAccount user) {
    _currentUser = user;
    notifyListeners();
  }

  // Đăng xuất: xóa tài khoản khỏi phiên hiện tại.
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
