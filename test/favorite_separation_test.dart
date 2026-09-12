// favorite_separation_test.dart
// Test hồi quy: danh sách TUYẾN YÊU THÍCH không được rò rỉ giữa các tài khoản.
//
// FavoriteService lưu riêng theo từng tài khoản với khóa
// 'favorite_route_ids_<userId>' và xóa dữ liệu trong bộ nhớ khi đăng xuất.

import 'package:busgo/services/favorite_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('yêu thích của tài khoản A không lộ sang tài khoản B', () async {
    final fav = FavoriteService.instance;
    await fav.clear();

    await fav.loadForUser(1);
    await fav.toggle('1');
    expect(fav.isFavorite('1'), isTrue);

    // Đăng nhập tài khoản B: danh sách phải rỗng.
    await fav.loadForUser(2);
    expect(fav.isFavorite('1'), isFalse);
    expect(fav.favoriteRoutes, isEmpty);

    await fav.toggle('2');
    expect(fav.isFavorite('2'), isTrue);

    // Quay lại tài khoản A: vẫn còn đúng yêu thích cũ.
    await fav.loadForUser(1);
    expect(fav.isFavorite('1'), isTrue);
    expect(fav.isFavorite('2'), isFalse);
  });

  test('clear() xóa yêu thích khi đăng xuất', () async {
    final fav = FavoriteService.instance;
    await fav.loadForUser(1);
    await fav.toggle('1');

    await fav.clear();

    expect(fav.isFavorite('1'), isFalse);
    expect(fav.favoriteRoutes, isEmpty);
  });

  test('purgeLegacyCache() dọn khóa yêu thích dùng chung cũ', () async {
    SharedPreferences.setMockInitialValues({
      'favorite_route_ids': ['1', '2'],
    });

    await FavoriteService.instance.purgeLegacyCache();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('favorite_route_ids'), isNull);
  });
}
