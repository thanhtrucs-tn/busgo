// session_service.dart
// Quản lý PHIÊN ĐĂNG NHẬP hiện tại của ứng dụng (trạng thái trong bộ nhớ).
//
// Khác biệt giữa các "lớp lưu trữ":
//  - TokenStorage   : lưu JWT + user vào secure storage (bền vững).
//  - SessionService : giữ USER đang đăng nhập trong bộ nhớ (nhanh, tức thời).
//  - RememberMeService: lưu TÊN đăng nhập để autofill ô nhập (không phải JWT).
//
// Khi ĐĂNG XUẤT: gọi AuthService.logout() để xóa JWT trên thiết bị,
// rồi xóa user khỏi bộ nhớ -> màn hình quay về Đăng nhập.

import 'package:flutter/foundation.dart';

import '../models/user_account.dart';
import 'auth_service.dart';
import 'profile_service.dart';

class SessionService extends ChangeNotifier {
  // Singleton: chỉ có một đối tượng duy nhất trong cả ứng dụng.
  SessionService._();
  static final SessionService instance = SessionService._();

  // Tài khoản đang đăng nhập (null nghĩa là chưa đăng nhập).
  UserAccount? _currentUser;

  UserAccount? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Lưu tài khoản vừa đăng nhập thành công vào phiên hiện tại.
  // Đồng thời đồng bộ tên/email lên ProfileService - một nguồn dữ liệu chung
  // để Trang cài đặt / Hồ sơ luôn khớp với Trang chủ.
  // Ví dụ: SessionService.instance.login(user);
  void login(UserAccount user) {
    _currentUser = user;
    // Cập nhật bộ nhớ ProfileService ngay (không cần chờ lưu vào đĩa).
    ProfileService.instance.syncFromSession(user);
    notifyListeners();
  }

  // Đăng xuất: xóa JWT khỏi thiết bị + xóa user khỏi bộ nhớ.
  // Sau khi gọi, app phải chuyển về màn hình Đăng nhập.
  Future<void> logout() async {
    // Xóa token + user trong secure storage (JWT không còn giá trị).
    await AuthService.instance.logout();
    // Xóa tên/email khỏi ProfileService để không lộ tài khoản cũ.
    await ProfileService.instance.clearIdentity();
    _currentUser = null;
    notifyListeners();
  }
}