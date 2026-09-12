// main.dart
// Day la diem bat dau cua ung dung BusGo.
// File nay khoi tao app, cau hinh giao dien chung (theme sang/toi),
// ca hong da ngon ngu (vi/en) va che do toi tu SettingsService.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/auth/auth_gate.dart';
import 'services/favorite_service.dart';
import 'services/profile_service.dart';
import 'services/remember_me_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Can dong nay truoc khi dung plugin (shared_preferences).
  WidgetsFlutterBinding.ensureInitialized();

  // Dọn dữ liệu hồ sơ / yêu thích dùng chung còn sót lại từ phiên bản lỗi
  // trước đây (mỗi lần mở app), để không hiển thị nhầm của tài khoản cũ.
  await ProfileService.instance.purgeLegacyCache();
  await FavoriteService.instance.purgeLegacyCache();

  // Cau hinh (theme/ngon ngu) doc tu bo nho.
  // Ho so ca nhan va yeu thich KHONG doc luc mo app: chi tai theo dung
  // tai khoan sau khi dang nhap / khoi phuc phien (tranh ro ri du lieu).
  await SettingsService.instance.load();

  // Doc ten dang nhap da ghi nho de tu dong dien san tren man hinh dang nhap.
  await RememberMeService.instance.load();

  runApp(const BusGoApp());
}

// BusGoApp la widget goc (root) cua ung dung.
// StatefulWidget vi can lang nghe SettingsService de doi theme va ngon ngu.
class BusGoApp extends StatefulWidget {
  const BusGoApp({super.key});

  @override
  State<BusGoApp> createState() => _BusGoAppState();
}

class _BusGoAppState extends State<BusGoApp> {
  @override
  void initState() {
    super.initState();
    // Cap nhat lai app ngay khi cau hinh thay doi (vd: doi ngon ngu, che do toi).
    SettingsService.instance.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    SettingsService.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusGo',
      // An banner "DEBUG" o goc man hinh khi chay app.
      debugShowCheckedModeBanner: false,
      // He thong da ngon ngu: vi (mac dinh) va en.
      locale: Locale(SettingsService.instance.language),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Giao dien theo mau xanh la + kem; ho tro che do toi.
      theme: buildAppTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: SettingsService.instance.darkMode
          ? ThemeMode.dark
          : ThemeMode.light,
      // Man hinh dau tien hien thi khi mo app la AUTH_GATE:
      // kiem tra JWT trong secure storage, hop le thi vao trang chu,
      // khong thi ve man hinh dang nhap.
      home: const AuthGate(),
    );
  }
}
