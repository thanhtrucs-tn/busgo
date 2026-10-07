
import 'package:shared_preferences/shared_preferences.dart';

class RememberMeService {
  // Singleton: chỉ có một đối tượng duy nhất trong cả ứng dụng.
  RememberMeService._();
  static final RememberMeService instance = RememberMeService._();

  // Các key dùng để lưu dữ liệu vào bộ nhớ.
  static const String _keyEnabled = 'remember_me_enabled';
  static const String _keyUsername = 'remembered_username';

  // Trạng thái ghi nhớ hiện tại.
  bool _enabled = false;

  // Tên đăng nhập đã được ghi nhớ (rỗng nếu chưa ghi nhớ).
  String _username = '';

  bool get enabled => _enabled;
  String get username => _username;

  // Đọc dữ liệu ghi nhớ từ bộ nhớ (gọi một lần khi mở app).
  // Ví dụ: await RememberMeService.instance.load();
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_keyEnabled) ?? false;
    _username = prefs.getString(_keyUsername) ?? '';
  }

  // Lưu (hoặc xóa) tên đăng nhập đã ghi nhớ.
  // Gọi sau khi đăng nhập thành công theo trạng thái ô tick của người dùng.
  //
  // Ví dụ:
  //   await RememberMeService.instance.saveRemembered(
  //     remembered: true,
  //     username: 'abc',
  //   );
  Future<void> saveRemembered({
    required bool remembered,
    required String username,
  }) async {
    _enabled = remembered;
    _username = remembered ? username : '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, remembered);
    if (remembered) {
      // Bật ghi nhớ: lưu tên đăng nhập để lần sau điền sẵn.
      await prefs.setString(_keyUsername, username);
    } else {
      // Không ghi nhớ: xóa tên đã lưu cũ nếu có.
      await prefs.remove(_keyUsername);
    }
  }

  // Xóa toàn bộ thông tin ghi nhớ (dùng khi người dùng muốn hủy ghi nhớ hẳn).
  Future<void> clear() async {
    _enabled = false;
    _username = '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEnabled);
    await prefs.remove(_keyUsername);
  }
}
