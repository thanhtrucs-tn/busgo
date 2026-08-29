// settings_service.dart
// Quan ly cac cau hinh (settings) cua ung dung: che do toi, ngon ngu,
// va cac tuy chon thong bao. Luu tru cuc bo bang shared_preferences.
// Ke thua ChangeNotifier de thong bao cho giao dien khi cau hinh thay doi.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  // Singleton: chi co mot doi tuong duy nhat trong ca app.
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  // Key dung de luu vao bo nho.
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyLanguage = 'language';
  static const String _keyNotifyArrival = 'notify_arrival';
  static const String _keyNotifyIssue = 'notify_issue';

  bool _darkMode = false;
  String _language = 'vi';
  bool _notifyArrival = true;
  bool _notifyIssue = true;

  bool get darkMode => _darkMode;
  String get language => _language;
  bool get notifyArrival => _notifyArrival;
  bool get notifyIssue => _notifyIssue;

  // Doc toan bo cau hinh tu bo nho (goi mot lan khi mo app).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _darkMode = prefs.getBool(_keyDarkMode) ?? false;
    _language = prefs.getString(_keyLanguage) ?? 'vi';
    _notifyArrival = prefs.getBool(_keyNotifyArrival) ?? true;
    _notifyIssue = prefs.getBool(_keyNotifyIssue) ?? true;

    notifyListeners();
  }

  // Bat/tat che do toi va luu lai.
  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  // Doi ngon ngu va luu lai.
  Future<void> setLanguage(String value) async {
    _language = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, value);
  }

  // Bat/tat thong bao xe den tram va luu lai.
  Future<void> setNotifyArrival(bool value) async {
    _notifyArrival = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifyArrival, value);
  }

  // Bat/tat thong bao su co tuyen xe va luu lai.
  Future<void> setNotifyIssue(bool value) async {
    _notifyIssue = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifyIssue, value);
  }
}