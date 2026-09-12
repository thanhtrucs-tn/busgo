// profile_service.dart
// Quản lý HỒ SƠ CÁ NHÂN của tài khoản đang đăng nhập.
//
// ĐÂY LÀ ĐIỂM SỬA LỖI RÒ RỈ DỮ LIỆU GIỮA CÁC TÀI KHOẢN:
//  - Hồ sơ là nguồn dữ liệu TẬP TRUNG từ backend (GET/PUT /api/profile/me),
//    backend chỉ trả hồ sơ theo user_id trong JWT.
//  - Không còn dùng một khóa SharedPreferences chung cho mọi tài khoản.
//    Mỗi lần đăng nhập, loadForUser() XÓA SẠCH dữ liệu trong bộ nhớ rồi
//    tải hồ sơ của đúng tài khoản đó từ server.
//  - Khi đăng xuất, clear() xóa toàn bộ dữ liệu trong bộ nhớ và dọn cả
//    các khóa cũ còn sót lại trong SharedPreferences.
// Kế thừa ChangeNotifier để giao diện cập nhật khi hồ sơ/trạng thái tải đổi.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

// Kết quả lưu hồ sơ trả về cho màn hình chỉnh sửa.
class ProfileResult {
  const ProfileResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class ProfileService extends ChangeNotifier {
  // Singleton: chỉ có một đối tượng duy nhất trong cả app.
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  // Các khóa cũ từng dùng để lưu hồ sơ chung (cần dọn khi đăng xuất).
  static const List<String> _legacyKeys = [
    'profile_name',
    'profile_email',
    'profile_phone',
    'profile_birthday',
    'profile_avatar',
    'profile_addresses',
    'profile_default_index',
    'profile_location_lat',
    'profile_location_lng',
  ];

  // ID tài khoản mà hồ sơ hiện tại thuộc về (null = chưa đăng nhập).
  int? _userId;

  // Trạng thái đang tải hồ sơ từ server (để hiện vòng xoay, tránh nháy dữ liệu cũ).
  bool _loading = false;

  // Dữ liệu hồ sơ trong bộ nhớ (mặc định RỖNG, không dùng dữ liệu mẫu).
  String _name = '';
  String _email = '';
  String _phone = '';
  DateTime? _birthday;
  Uint8List? _avatarBytes;
  List<String> _addresses = <String>[];
  int _defaultAddressIndex = 0;
  double? _locationLat;
  double? _locationLng;

  int? get userId => _userId;
  bool get isLoading => _loading;
  String get name => _name;
  String get email => _email;
  String get phone => _phone;
  DateTime? get birthday => _birthday;
  Uint8List? get avatarBytes => _avatarBytes;
  List<String> get addresses => List.unmodifiable(_addresses);
  int get defaultAddressIndex => _defaultAddressIndex;
  double? get locationLat => _locationLat;
  double? get locationLng => _locationLng;

  /// Ký tự đầu tiên của tên (dùng làm avatar mặc định khi chưa chọn ảnh).
  String get initial {
    final trimmed = _name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1);
  }

  // Tải hồ sơ của ĐÚNG tài khoản vừa đăng nhập từ backend.
  // Dữ liệu cũ trong bộ nhớ bị xóa ngay từ đầu để không hiện nhầm tài khoản trước.
  Future<ProfileResult> loadForUser(int userId) async {
    _userId = userId;
    _resetFields();
    _loading = true;
    notifyListeners();

    // Dọn dữ liệu hồ sơ dùng chung còn sót lại của phiên bản lỗi trước.
    await purgeLegacyCache();

    final result = await ApiService.instance.get('/profile/me', protected: true);

    if (result.success && result.data != null) {
      _applyJson(_payload(result.data!));
      _loading = false;
      notifyListeners();
      return ProfileResult(success: true, message: result.message);
    }

    // Lỗi mạng/server: giữ hồ sơ rỗng, KHÔNG dùng lại dữ liệu tài khoản khác.
    _loading = false;
    notifyListeners();
    return ProfileResult(success: false, message: result.message);
  }

  // Lưu hồ sơ lên backend rồi cập nhật lại dữ liệu trong bộ nhớ theo phản hồi.
  // Tham số null nghĩa là giữ nguyên giá trị hiện tại.
  Future<ProfileResult> save({
    String? name,
    String? email,
    String? phone,
    DateTime? birthday,
    Uint8List? avatarBytes,
    List<String>? addresses,
    int? defaultAddressIndex,
    double? locationLat,
    double? locationLng,
  }) async {
    if (_userId == null) {
      return const ProfileResult(
        success: false,
        message: 'Chưa đăng nhập, vui lòng đăng nhập lại',
      );
    }

    final effectiveBirthday = birthday ?? _birthday;
    final effectiveAvatar = avatarBytes ?? _avatarBytes;

    final body = <String, dynamic>{
      'name': (name ?? _name).trim(),
      'email': (email ?? _email).trim(),
      'phone': (phone ?? _phone).trim(),
      'birthday': effectiveBirthday == null ? null : _dateOnly(effectiveBirthday),
      'avatar': effectiveAvatar == null ? null : base64Encode(effectiveAvatar),
      'addresses': addresses ?? _addresses,
      'defaultAddressIndex': defaultAddressIndex ?? _defaultAddressIndex,
      'locationLat': locationLat ?? _locationLat,
      'locationLng': locationLng ?? _locationLng,
    };

    final result =
        await ApiService.instance.put('/profile/me', body: body, protected: true);

    if (result.success && result.data != null) {
      _applyJson(_payload(result.data!));
      notifyListeners();
      return ProfileResult(success: true, message: result.message);
    }
    return ProfileResult(success: false, message: result.message);
  }

  // Đăng xuất: xóa toàn bộ hồ sơ trong bộ nhớ + dọn dữ liệu cũ trên thiết bị.
  Future<void> clear() async {
    _userId = null;
    _resetFields();
    notifyListeners();

    await purgeLegacyCache();
  }

  // Dọn các khóa hồ sơ dùng chung do phiên bản lỗi trước đây ghi vào máy.
  // Được gọi lúc mở app, khi đăng nhập và khi đăng xuất để chắc chắn không
  // còn dữ liệu của tài khoản cũ trên thiết bị.
  Future<void> purgeLegacyCache() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _legacyKeys) {
      await prefs.remove(key);
    }
  }

  void _resetFields() {
    _name = '';
    _email = '';
    _phone = '';
    _birthday = null;
    _avatarBytes = null;
    _addresses = <String>[];
    _defaultAddressIndex = 0;
    _locationLat = null;
    _locationLng = null;
  }

  // Gán dữ liệu hồ sơ từ JSON backend trả về.
  void _applyJson(Map<String, dynamic> json) {
    _name = (json['name'] as String?) ?? '';
    _email = (json['email'] as String?) ?? '';
    _phone = (json['phone'] as String?) ?? '';

    final birthdayStr = json['birthday'] as String?;
    _birthday = (birthdayStr == null || birthdayStr.isEmpty)
        ? null
        : DateTime.tryParse(birthdayStr);

    final avatar = json['avatar'] as String?;
    _avatarBytes = (avatar == null || avatar.isEmpty) ? null : base64Decode(avatar);

    final list = json['addresses'];
    _addresses = list is List
        ? list.map((item) => item.toString()).toList()
        : <String>[];

    _defaultAddressIndex = (json['defaultAddressIndex'] as num?)?.toInt() ?? 0;
    _locationLat = (json['locationLat'] as num?)?.toDouble();
    _locationLng = (json['locationLng'] as num?)?.toDouble();
  }

  // Lấy phần dữ liệu thật bên trong phản hồi chuẩn { success, message, data }.
  Map<String, dynamic> _payload(Map<String, dynamic> response) {
    final inner = response['data'];
    return inner is Map<String, dynamic> ? inner : response;
  }

  String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
