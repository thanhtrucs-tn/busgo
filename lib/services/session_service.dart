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
import 'favorite_service.dart';
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
  // Đồng thời TẢI LẠI hồ sơ của đúng tài khoản này từ backend: dữ liệu hồ sơ
  // của tài khoản trước bị xóa trước khi tải, tránh rò rỉ giữa các tài khoản.
  // Ví dụ: await SessionService.instance.login(user);
  Future<void> login(UserAccount user) async {
    _currentUser = user;
    // Xóa hồ sơ cũ + tải hồ sơ mới theo user.id (nguồn dữ liệu là server).
    await ProfileService.instance.loadForUser(user.id);
    // Nạp danh sách tuyến yêu thích riêng của tài khoản này.
    await FavoriteService.instance.loadForUser(user.id);
    notifyListeners();
  }

  // Đăng xuất: xóa JWT khỏi thiết bị + xóa hồ sơ/yêu thích/phiên trong bộ nhớ.
  // Sau khi gọi, app phải chuyển về màn hình Đăng nhập.
  Future<void> logout() async {
    // Xóa token + user trong secure storage (JWT không còn giá trị).
    await AuthService.instance.logout();
    // Xóa toàn bộ hồ sơ (tên, điện thoại, địa chỉ, ảnh...) khỏi bộ nhớ và cache.
    await ProfileService.instance.clear();
    // Xóa danh sách yêu thích khỏi bộ nhớ để không lộ dữ liệu tài khoản cũ.
    await FavoriteService.instance.clear();
    _currentUser = null;
    notifyListeners();
  }
}
