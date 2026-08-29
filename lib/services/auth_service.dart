// auth_service.dart
// Dịch vụ gọi API đăng ký / đăng nhập từ máy chủ (Node.js + MySQL).
// Sử dụng gói http đã có sẵn trong dự án.
//
// Các chức năng:
//  - register(username, password): tạo tài khoản mới.
//  - login(username, password): đăng nhập, trả về UserAccount nếu thành công.
//
// Ví dụ sử dụng:
//   final result = await AuthService.instance.login(username: 'abc', password: '123456');
//   if (result.success) { ... } else { print(result.message); }

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/user_account.dart';

// Kết quả trả về từ máy chủ: cho biết thành công/thất bại,
// thông điệp hiển thị cho người dùng và dữ liệu (nếu có).
class AuthResult {
  const AuthResult({required this.success, required this.message, this.user});

  final bool success;
  final String message;
  final UserAccount? user;
}

class AuthService {
  // Singleton: chỉ có một đối tượng duy nhất trong cả ứng dụng.
  AuthService._();
  static final AuthService instance = AuthService._();

  // Thời gian tối đa chờ máy chủ phản hồi.
  static const Duration _timeout = Duration(seconds: 10);

  // Đăng ký tài khoản mới với tên đăng nhập và mật khẩu.
  // Trả về AuthResult; khi thành công, user là null (chưa đăng nhập).
  Future<AuthResult> register({
    required String username,
    required String password,
  }) {
    return _post('/auth/register', {
      'username': username,
      'password': password,
    });
  }

  // Đăng nhập với tên đăng nhập và mật khẩu.
  // Khi thành công, AuthResult.user chứa thông tin tài khoản.
  Future<AuthResult> login({
    required String username,
    required String password,
  }) {
    return _post('/auth/login', {'username': username, 'password': password});
  }

  // Gọi chung một request POST dạng JSON tới máy chủ và phân tích phản hồi.
  // Được tách riêng để hai chức năng trên ngắn gọn, dễ bảo trì.
  Future<AuthResult> _post(String path, Map<String, String> body) async {
    try {
      // Gửi yêu cầu POST với dữ liệu JSON.
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$path'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      // Giải mã nội dung dạng UTF-8 để tiếng Việt không bị lỗi font.
      // Ví dụ: thông điệp "Đăng nhập thành công".
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      final success = json['success'] as bool? ?? false;
      final message =
          json['message'] as String? ?? 'Có lỗi xảy ra, vui lòng thử lại';
      UserAccount? user;
      if (success && json['data'] is Map<String, dynamic>) {
        user = UserAccount.fromJson(json['data'] as Map<String, dynamic>);
      }
      return AuthResult(success: success, message: message, user: user);
    } catch (_) {
      // Không kết nối được máy chủ (tắt mạng, backend chưa chạy, ...).
      return const AuthResult(
        success: false,
        message: 'Không thể kết nối máy chủ, vui lòng kiểm tra lại',
      );
    }
  }
}
