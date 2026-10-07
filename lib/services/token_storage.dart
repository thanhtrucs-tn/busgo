

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  // Singleton: chỉ có một đối tượng duy nhất trong cả ứng dụng.
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  // Đối tượng lưu trữ an toàn của hệ thống.
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Khóa dùng để lưu trong secure storage.
  static const String _keyToken = 'jwt_token';
  static const String _keyUser = 'jwt_user';

  // Lưu token + thông tin user sau khi đăng nhập thành công.
  // Ví dụ: await TokenStorage.instance.save(token: 'eyJ...', user: {...});
  Future<void> save({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    try {
      await _storage.write(key: _keyToken, value: token);
      await _storage.write(key: _keyUser, value: jsonEncode(user));
    } catch (_) {
      // Không crash app nếu secure storage lỗi.
    }
  }

  // Đọc token đã lưu (null nếu chưa đăng nhập hoặc không đọc được).
  Future<String?> readToken() async {
    try {
      return await _storage.read(key: _keyToken);
    } catch (_) {
      return null;
    }
  }

  // Đọc thông tin user đã lưu (null nếu chưa có).
  Future<Map<String, dynamic>?> readUser() async {
    try {
      final raw = await _storage.read(key: _keyUser);
      if (raw == null || raw.isEmpty) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // Xóa toàn bộ (thường gọi khi đăng xuất hoặc token hết hạn).
  Future<void> clear() async {
    try {
      await _storage.delete(key: _keyToken);
      await _storage.delete(key: _keyUser);
    } catch (_) {
      // Bỏ qua nếu không xóa được.
    }
  }
}
