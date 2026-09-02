// profile_service.dart
// Quan ly thong tin ho so ca nhan cua nguoi dung: ten, email, so dien thoai,
// ngay sinh, anh dai dien, danh sach dia chi va dia chi mac dinh.
// Luu tru cuc bo bang shared_preferences (khong can backend).
// Ke thua ChangeNotifier de thong bao cho giao dien khi ho so thay doi.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_account.dart';

class ProfileService extends ChangeNotifier {
  // Singleton: chi co mot doi tuong duy nhat trong ca app.
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  // Key dung de luu vao bo nho.
  static const String _kName = 'profile_name';
  static const String _kEmail = 'profile_email';
  static const String _kPhone = 'profile_phone';
  static const String _kBirthday = 'profile_birthday';
  static const String _kAvatar = 'profile_avatar';
  static const String _kAddresses = 'profile_addresses';
  static const String _kDefaultIndex = 'profile_default_index';
  static const String _kLocationLat = 'profile_location_lat';
  static const String _kLocationLng = 'profile_location_lng';

  // Du lieu ho so (mac dinh la nguoi dung mau).
  String _name = 'Nguyễn Văn A';
  String _email = 'nguyenvana@example.com';
  String _phone = '';
  DateTime? _birthday;
  Uint8List? _avatarBytes;
  List<String> _addresses = <String>[];
  int _defaultAddressIndex = 0;

  // Toa do GPS cua dia chi chinh (lay khi user bam "Lay vi tri hien tai").
  double? _locationLat;
  double? _locationLng;

  String get name => _name;
  String get email => _email;
  String get phone => _phone;
  DateTime? get birthday => _birthday;
  Uint8List? get avatarBytes => _avatarBytes;
  List<String> get addresses => List.unmodifiable(_addresses);
  int get defaultAddressIndex => _defaultAddressIndex;
  double? get locationLat => _locationLat;
  double? get locationLng => _locationLng;

  /// Ky tu dau tien cua ten (dung lam avatar mac dinh khi chua chon anh).
  String get initial {
    final trimmed = _name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1);
  }

  // Doc toan bo ho so tu bo nho (goi mot lan khi mo app).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _name = prefs.getString(_kName) ?? 'Nguyễn Văn A';
    _email = prefs.getString(_kEmail) ?? 'nguyenvana@example.com';
    _phone = prefs.getString(_kPhone) ?? '';
    _birthday = DateTime.tryParse(prefs.getString(_kBirthday) ?? '');

    final avatar = prefs.getString(_kAvatar) ?? '';
    _avatarBytes = avatar.isEmpty ? null : base64Decode(avatar);

    _addresses = prefs.getStringList(_kAddresses) ?? <String>[];
    _defaultAddressIndex = prefs.getInt(_kDefaultIndex) ?? 0;
    _locationLat = prefs.getDouble(_kLocationLat);
    _locationLng = prefs.getDouble(_kLocationLng);

    notifyListeners();
  }

  // Luu ho so moi vao bo nho (cac truong null se giu gia tri hien tai).
  Future<void> save({
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
    _name = name ?? _name;
    _email = email ?? _email;
    _phone = phone ?? _phone;
    _birthday = birthday;
    _avatarBytes = avatarBytes;
    _addresses = addresses ?? _addresses;
    _defaultAddressIndex = defaultAddressIndex ?? _defaultAddressIndex;
    _locationLat = locationLat;
    _locationLng = locationLng;

    // Bao cho giao dien biet ho so da thay doi.
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, _name);
    await prefs.setString(_kEmail, _email);
    await prefs.setString(_kPhone, _phone);
    await prefs.setString(
      _kBirthday,
      _birthday?.toIso8601String() ?? '',
    );
    await prefs.setString(
      _kAvatar,
      _avatarBytes == null ? '' : base64Encode(_avatarBytes!),
    );
    await prefs.setStringList(_kAddresses, _addresses);
    await prefs.setInt(_kDefaultIndex, _defaultAddressIndex);
    if (_locationLat == null || _locationLng == null) {
      await prefs.remove(_kLocationLat);
      await prefs.remove(_kLocationLng);
    } else {
      await prefs.setDouble(_kLocationLat, _locationLat!);
      await prefs.setDouble(_kLocationLng, _locationLng!);
    }
  }

  // Đồng bộ TÊN + EMAIL từ tài khoản đang đăng nhập (nguồn dữ liệu chung).
  // Được gọi mỗi khi đăng nhập / khôi phục phiên để mọi màn hình
  // (Trang cài đặt, Hồ sơ...) hiển thị đúng tài khoản vừa đăng nhập.
  Future<void> syncFromSession(UserAccount user) async {
    // Ưu tiên tên hiển thị; không có thì dùng tên đăng nhập.
    _name = user.name.isNotEmpty ? user.name : user.username;
    _email = user.email;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, _name);
    await prefs.setString(_kEmail, _email);
  }

  // Xóa TÊN + EMAIL khi đăng xuất để không lưu lại dữ liệu tài khoản cũ.
  Future<void> clearIdentity() async {
    _name = '';
    _email = '';
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, _name);
    await prefs.setString(_kEmail, _email);
  }
}