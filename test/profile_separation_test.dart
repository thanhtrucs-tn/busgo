// profile_separation_test.dart
// Test hồi quy cho lỗi RÒ RỈ DỮ LIỆU giữa các tài khoản.
//
// Kiểm tra ProfileService:
//  - Không còn khởi tạo bằng dữ liệu mẫu ("Nguyễn Văn A").
//  - Không đọc hồ sơ cũ từ các khóa SharedPreferences dùng chung.
//  - clear() (gọi khi đăng xuất) xóa sạch dữ liệu trong bộ nhớ và cache cũ.

import 'package:busgo/services/profile_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mỗi test dùng bộ nhớ giả cho SharedPreferences (không cần plugin thật).
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('TC-07a: hồ sơ mặc định RỖNG, không còn dữ liệu mẫu', () async {
    await ProfileService.instance.clear();

    expect(ProfileService.instance.userId, isNull);
    expect(ProfileService.instance.isLoading, isFalse);
    expect(ProfileService.instance.name, '');
    expect(ProfileService.instance.email, '');
    expect(ProfileService.instance.phone, '');
    expect(ProfileService.instance.addresses, isEmpty);
    expect(ProfileService.instance.initial, '?');
  });

  test('TC-07b: không đọc hồ sơ cũ từ SharedPreferences dùng chung', () async {
    // Giả lập dữ liệu tài khoản trước còn sót trên thiết bị.
    SharedPreferences.setMockInitialValues({
      'profile_name': 'Nguyễn Văn A',
      'profile_phone': '0900000000',
      'profile_addresses': ['Địa chỉ của tài khoản trước'],
    });

    // ProfileService không được lấy dữ liệu này làm hồ sơ hiện tại.
    expect(ProfileService.instance.name, '');
    expect(ProfileService.instance.phone, '');
    expect(ProfileService.instance.addresses, isEmpty);
  });

  test('TC-07c: clear() xóa sạch cache hồ sơ cũ trên thiết bị', () async {
    SharedPreferences.setMockInitialValues({
      'profile_name': 'Nguyễn Văn A',
      'profile_email': 'a@example.com',
      'profile_phone': '0900000000',
      'profile_addresses': ['Địa chỉ của A'],
      'profile_default_index': 0,
    });

    await ProfileService.instance.clear();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('profile_name'), isNull);
    expect(prefs.getString('profile_email'), isNull);
    expect(prefs.getString('profile_phone'), isNull);
    expect(prefs.getStringList('profile_addresses'), isNull);
    expect(prefs.getInt('profile_default_index'), isNull);

    expect(ProfileService.instance.userId, isNull);
    expect(ProfileService.instance.name, '');
    expect(ProfileService.instance.phone, '');
    expect(ProfileService.instance.addresses, isEmpty);
  });

  test('TC-07d: purgeLegacyCache() dọn dữ liệu cũ ngay khi mở app', () async {
    SharedPreferences.setMockInitialValues({
      'profile_name': 'Nguyễn Văn A',
      'profile_email': 'a@example.com',
      'profile_phone': '0900000000',
      'profile_avatar': 'YWJj',
      'profile_addresses': ['Địa chỉ của A'],
      'profile_default_index': 0,
      'profile_location_lat': 10.7,
      'profile_location_lng': 106.7,
    });

    await ProfileService.instance.purgeLegacyCache();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('profile_name'), isNull);
    expect(prefs.getString('profile_email'), isNull);
    expect(prefs.getString('profile_phone'), isNull);
    expect(prefs.getString('profile_avatar'), isNull);
    expect(prefs.getStringList('profile_addresses'), isNull);
    expect(prefs.getInt('profile_default_index'), isNull);
    expect(prefs.getDouble('profile_location_lat'), isNull);
    expect(prefs.getDouble('profile_location_lng'), isNull);
  });
}
