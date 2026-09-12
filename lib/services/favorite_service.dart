// favorite_service.dart
// Quan ly danh sach tuyen xe buyt yeu thich.
//
// QUAN TRONG (sua loi ro ri giua cac tai khoan):
//  - Yeu thich duoc luu RIENG theo tung tai khoan voi khoa
//    'favorite_route_ids_<userId>' thay vi mot khoa chung cho moi nguoi.
//  - Khi dang nhap / khoi phuc phien: loadForUser(userId) xoa du lieu trong
//    bo nho truoc, roi nap dung danh sach cua tai khoan do.
//  - Khi dang xuat: clear() xoa danh sach trong bo nho de khong lo du lieu.
// Ke thua ChangeNotifier de thong bao cho giao dien khi du lieu thay doi.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sample_data.dart';
import '../models/bus_route.dart';

class FavoriteService extends ChangeNotifier {
  // Singleton: chi co mot doi tuong duy nhat trong ca app.
  FavoriteService._();
  static final FavoriteService instance = FavoriteService._();

  // Khoa cu dung chung cho moi tai khoan (can don bo khi mo app).
  static const String _legacyKey = 'favorite_route_ids';

  // Khoa luu yeu thich theo tung tai khoan.
  static String _keyFor(int userId) => 'favorite_route_ids_$userId';

  // Tai khoan dang dang nhap ma danh sach yeu thich thuoc ve.
  int? _userId;

  // Danh sach id cac tuyen duoc yeu thich.
  final Set<String> _favoriteIds = <String>{};

  // Kiem tra mot tuyen co duoc yeu thich hay khong.
  bool isFavorite(String routeId) => _favoriteIds.contains(routeId);

  // Nap yeu thich cua DUNG tai khoan vua dang nhap.
  // Xoa danh sach cu ngay tu dau de khong hien nham cua tai khoan truoc.
  Future<void> loadForUser(int userId) async {
    _userId = userId;
    _favoriteIds.clear();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_keyFor(userId)) ?? <String>[];

    _favoriteIds
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }

  // Them hoac bo yeu thich (toggle) cho tai khoan hien tai.
  Future<void> toggle(String routeId) async {
    if (_favoriteIds.contains(routeId)) {
      _favoriteIds.remove(routeId);
    } else {
      _favoriteIds.add(routeId);
    }

    // Bao cho giao dien biet du lieu da thay doi.
    notifyListeners();

    // Chua dang nhap thi chi giu trong bo nho, khong luu xuong may.
    if (_userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFor(_userId!), _favoriteIds.toList());
  }

  // Dang xuat: xoa danh sach trong bo nho (khong hien du lieu tai khoan cu).
  // Danh sach da luu rieng cua tung tai khoan van con cho lan dang nhap sau.
  Future<void> clear() async {
    _userId = null;
    _favoriteIds.clear();
    notifyListeners();
  }

  // Don khoa yeu thich dung chung cua phien ban cu (ro ri giua cac tai khoan).
  Future<void> purgeLegacyCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyKey);
  }

  // Lay danh sach cac tuyen yeu thich (doi chieu voi sampleRoutes).
  List<BusRoute> get favoriteRoutes {
    return sampleRoutes.where((r) => _favoriteIds.contains(r.id)).toList();
  }
}
