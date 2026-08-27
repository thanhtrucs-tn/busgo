// favorite_service.dart
// Quan ly danh sach tuyen xe buyt yeu thich.
// Luu tru cuc bo bang shared_preferences (khong can backend).
// Ke thua ChangeNotifier de thong bao cho giao dien khi du lieu thay doi.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sample_data.dart';
import '../models/bus_route.dart';

class FavoriteService extends ChangeNotifier {
  // Singleton: chi co mot doi tuong duy nhat trong ca app.
  FavoriteService._();
  static final FavoriteService instance = FavoriteService._();

  // Key dung de luu vao bo nho.
  static const String _key = 'favorite_route_ids';

  // Danh sach id cac tuyen duoc yeu thich.
  final Set<String> _favoriteIds = <String>{};

  // Kiem tra mot tuyen co duoc yeu thich hay khong.
  bool isFavorite(String routeId) => _favoriteIds.contains(routeId);

  // Doc danh sach yeu thich tu bo nho (goi mot lan khi mo app).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? <String>[];

    _favoriteIds
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }

  // Them hoac bo yeu thich (toggle).
  Future<void> toggle(String routeId) async {
    if (_favoriteIds.contains(routeId)) {
      _favoriteIds.remove(routeId);
    } else {
      _favoriteIds.add(routeId);
    }

    // Bao cho giao dien biet du lieu da thay doi.
    notifyListeners();

    // Luu lai vao bo nho de lan sau mo app van con.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _favoriteIds.toList());
  }

  // Lay danh sach cac tuyen yeu thich (doi chieu voi sampleRoutes).
  List<BusRoute> get favoriteRoutes {
    return sampleRoutes.where((r) => _favoriteIds.contains(r.id)).toList();
  }
}