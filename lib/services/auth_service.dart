

import 'dart:convert';

import '../models/user_account.dart';
import 'api_service.dart';
import 'token_storage.dart';

// Kết quả xác thực trả về cho màn hình.
class AuthResult {
  const AuthResult({required this.success, required this.message, this.user});

  final bool success;
  final String message;

  // Tài khoản đã đăng nhập (null khi thất bại).
  final UserAccount? user;
}

class AuthService {
  // Singleton: chỉ có một đối tượng duy nhất trong cả ứng dụng.
  AuthService._();
  static final AuthService instance = AuthService._();

  // ------------------------------------------------------------
  // ĐĂNG NHẬP.
  // Gửi:  { identifier, password }  (identifier = tên đăng nhập HOẶC email)
  // Nhận: { success, message, token, user }
  // Khi thành công: lưu token + user vào secure storage.
  // ------------------------------------------------------------
  Future<AuthResult> login({
    required String identifier,
    required String password,
  }) async {
    // Gọi API login (PUBLIC - không cần token).
    final result = await ApiService.instance.post(
      '/auth/login',
      body: {'identifier': identifier, 'password': password},
    );

    if (result.success && result.data != null) {
      // Lưu token + user an toàn.
      await _persistSession(result.data!);
      // Trả user để màn hình chuyển sang trang chủ.
      return AuthResult(
        success: true,
        message: result.message,
        user: UserAccount.fromJson(_userJson(result.data!)),
      );
    }
    return AuthResult(success: false, message: result.message);
  }

  // ------------------------------------------------------------
  // ĐĂNG KÝ tài khoản mới.
  // Gửi: { username, password, email?, name? }
  // ------------------------------------------------------------
  Future<AuthResult> register({
    required String username,
    required String password,
    String? email,
    String? name,
  }) async {
    final result = await ApiService.instance.post(
      '/auth/register',
      body: {
        'username': username,
        'password': password,
        'email': email ?? '',
        'name': name ?? '',
      },
    );

    if (result.success && result.data != null) {
      // Backend trả kèm token -> lưu luôn để người dùng vào thẳng trang chủ.
      await _persistSession(result.data!);
      return AuthResult(
        success: true,
        message: result.message,
        user: UserAccount.fromJson(_userJson(result.data!)),
      );
    }
    return AuthResult(success: false, message: result.message);
  }

  // ------------------------------------------------------------
  // ĐĂNG NHẬP / ĐĂNG KÝ NHANH BẰNG GOOGLE.
  // Gửi:  { idToken }  (ID token lấy từ GoogleSignIn ở app)
  // Backend tự XÁC MINH token với Google rồi:
  //   - Tài khoản Google đã có  -> đăng nhập.
  //   - Chưa có                 -> tự tạo tài khoản mới (đăng ký nhanh).
  // Trả về: { success, message, token, user } như đăng nhập thường.
  // ------------------------------------------------------------
  Future<AuthResult> googleLogin(String idToken) async {
    final result = await ApiService.instance.post(
      '/auth/google',
      body: {'idToken': idToken},
    );

    if (result.success && result.data != null) {
      await _persistSession(result.data!);
      return AuthResult(
        success: true,
        message: result.message,
        user: UserAccount.fromJson(_userJson(result.data!)),
      );
    }
    return AuthResult(success: false, message: result.message);
  }

  // ------------------------------------------------------------
  // KIỂM TRA SESSION khi mở app.
  //   1. Đọc token trong secure storage.
  //   2. Không có token          -> chưa đăng nhập.
  //   3. Có token -> gọi GET /api/auth/me.
  //   4. Token hợp lệ            -> đăng nhập (session ok).
  //   5. Token hết hạn/sai       -> xóa token (session hết hạn).
  //   Lỗi mạng                   -> giữ token, trả session hết hạn
  //                                (người dùng phải đăng nhập lại khi online).
  // ------------------------------------------------------------
  Future<AuthResult> checkSession() async {
    // Bước 1: đọc token.
    final token = await TokenStorage.instance.readToken();
    if (token == null || token.isEmpty) {
      // Bước 2: không có token.
      return const AuthResult(success: false, message: 'Chưa đăng nhập');
    }

    // Bước 3: gọi API protected /api/auth/me (ApiService tự gửi Bearer).
    final result = await ApiService.instance.get('/auth/me', protected: true);

    if (result.success && result.data != null) {
      // Bước 4: token hợp lệ -> trả user hiện tại.
      final user = UserAccount.fromJson(_userJson(result.data!));
      return AuthResult(success: true, message: result.message, user: user);
    }

    // Phân biệt lỗi mạng với token hết hạn.
    if (_isNetworkError(result.message)) {
      // Lỗi mạng: KHÔNG xóa token (phiên vẫn còn giá trị).
      return const AuthResult(
        success: false,
        message: 'Không thể kết nối máy chủ',
      );
    }

    // Bước 5: token sai/hết hạn -> xóa token và user đã lưu.
    await TokenStorage.instance.clear();
    return const AuthResult(
      success: false,
      message: 'Phiên đăng nhập đã hết hạn',
    );
  }

  // ------------------------------------------------------------
  // ĐĂNG XUẤT: xóa JWT + user khỏi secure storage.
  // ------------------------------------------------------------
  Future<void> logout() async {
    await TokenStorage.instance.clear();
  }

  // Lưu token + user vào secure storage sau khi đăng nhập/đăng ký.
  Future<void> _persistSession(Map<String, dynamic> data) async {
    final payload = _payload(data);
    final token = payload['token'] as String? ?? '';
    if (token.isNotEmpty) {
      await TokenStorage.instance.save(token: token, user: _userJson(data));
    }
  }

  // Lấy phần dữ liệu thật bên trong phản hồi chuẩn { success, message, data }.
  // Vẫn chấp nhận dạng cũ (token/user nằm ngay ở tầng trên) để tương thích.
  Map<String, dynamic> _payload(Map<String, dynamic> data) {
    final inner = data['data'];
    return inner is Map<String, dynamic> ? inner : data;
  }

  // Lấy phần "user" từ phản hồi JSON của backend.
  // Ví dụ login:   { success, message, data: { token, user: { id, username, ... } } }
  // Ví dụ /me:     { success, message, data: { id, username, name, email, role } }
  Map<String, dynamic> _userJson(Map<String, dynamic> data) {
    final payload = _payload(data);
    final user = payload['user'];
    final decoded = user is String ? jsonDecode(user) : user;
    if (decoded is Map<String, dynamic>) return decoded;
    // /auth/me trả user trực tiếp trong data, không bọc trong "user".
    return payload;
  }

  // Kiểm tra có phải lỗi mạng hay không (dựa vào message của ApiService).
  bool _isNetworkError(String message) {
    return message.contains('Không thể kết nối máy chủ');
  }
}
