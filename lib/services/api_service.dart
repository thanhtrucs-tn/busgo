

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_storage.dart';

// Kết quả phản hồi chung: thành công/thất bại + message + dữ liệu (nếu có).
class ApiResult {
  const ApiResult({required this.success, required this.message, this.data});

  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  // Phần dữ liệu thật server trả về trong khóa "data"
  // (có thể là Map hoặc List tùy endpoint).
  dynamic get payload => data?['data'];
}

class ApiService {
  // Singleton: chỉ có một đối tượng duy nhất trong cả ứng dụng.
  ApiService._();
  static final ApiService instance = ApiService._();

  // Thời gian tối đa chờ máy chủ phản hồi.
  static const Duration _timeout = Duration(seconds: 10);

  // ---- CÁC HÀM GỌI CHUNG (GET / POST) ----
  // Mỗi hàm tự thêm header Authorization nếu có token.

  // Gọi GET, ví dụ: ApiService.instance.get('/auth/me', protected: true);
  // query: các tham số trên URL, ví dụ {'direction': '0'}.
  Future<ApiResult> get(
    String path, {
    Map<String, String>? query,
    bool protected = false,
  }) async {
    return _send(method: 'GET', path: path, query: query, protected: protected);
  }

  // Gọi POST, ví dụ: ApiService.instance.post('/auth/login', body: {...});
  Future<ApiResult> post(
    String path, {
    Map<String, dynamic>? body,
    bool protected = false,
  }) async {
    return _send(method: 'POST', path: path, body: body, protected: protected);
  }

  // Gọi PUT, ví dụ: ApiService.instance.put('/profile/me', body: {...}, protected: true);
  Future<ApiResult> put(
    String path, {
    Map<String, dynamic>? body,
    bool protected = false,
  }) async {
    return _send(method: 'PUT', path: path, body: body, protected: protected);
  }

  // Triển khai chung cho mọi request (tránh lặp code).
  Future<ApiResult> _send({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool protected = false,
  }) async {
    try {
      // Xây dựng URL đầy đủ: baseUrl + đường dẫn (+ tham số query nếu có).
      var uri = Uri.parse('${ApiConfig.baseUrl}$path');
      if (query != null && query.isNotEmpty) {
        uri = uri.replace(queryParameters: query);
      }

      // Header cơ bản: loại nội dung JSON.
      final headers = <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
      };

      // TỰ ĐỘNG thêm Authorization: Bearer <token> nếu API cần đăng nhập.
      if (protected) {
        final token = await TokenStorage.instance.readToken();
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      // Gửi request theo phương thức.
      final http.Response response;
      if (method == 'GET') {
        response = await http.get(uri, headers: headers).timeout(_timeout);
      } else if (method == 'PUT') {
        response = await http
            .put(uri, headers: headers, body: jsonEncode(body ?? {}))
            .timeout(_timeout);
      } else {
        response = await http
            .post(uri, headers: headers, body: jsonEncode(body ?? {}))
            .timeout(_timeout);
      }

      // Giải mã nội dung UTF-8 để tiếng Việt không bị lỗi font.
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final map = json is Map<String, dynamic> ? json : <String, dynamic>{};

      return ApiResult(
        success: map['success'] as bool? ?? false,
        message:
            map['message'] as String? ?? _messageForStatus(response.statusCode),
        data: map,
      );
    } catch (_) {
      // Không kết nối được máy chủ (tắt mạng, backend chưa chạy...).
      return const ApiResult(
        success: false,
        message: 'Không thể kết nối máy chủ, vui lòng kiểm tra lại',
      );
    }
  }

  // Thông điệp dự phòng theo mã lỗi HTTP (khi server không trả message).
  String _messageForStatus(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Phiên đăng nhập hết hạn, vui lòng đăng nhập lại';
      case 403:
        return 'Bạn không có quyền truy cập tính năng này';
      case 404:
        return 'Không tìm thấy đường dẫn yêu cầu';
      case 500:
        return 'Lỗi máy chủ, vui lòng thử lại sau';
      default:
        return 'Có lỗi xảy ra, vui lòng thử lại';
    }
  }
}
