// home_screen.dart
// Man hinh chinh (Home) cua ung dung BusGo.
// Thiet ke phang, toi gian; mau sac lay tu theme (che do sang/toi),
// van ban lay tu he thong da ngon ngu (vi/en).

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import 'auth/login_screen.dart';
import 'bus_route_list_screen.dart';
import 'bus_stop_list_screen.dart';
import 'bus_tracking_screen.dart';
import 'favorite_screen.dart';
import 'map_screen.dart';
import 'notification_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Muc dang chon trong thanh menu duoi cung.
  int _selectedIndex = 0;

  // Chuyen sang mot man hinh khac va quay ve muc "Trang chủ" khi tro lai.
  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() => _selectedIndex = 0);
  }

  // Xu ly khi chon mot muc trong thanh menu duoi cung.
  void _onNavSelected(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 1:
        _open(const MapScreen());
      case 2:
        _open(const NotificationScreen());
      case 3:
        _open(const SettingsScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      // Top bar xanh la: tieu de "BusGo" va nut DANG XUAT o goc phai.
      appBar: AppBar(
        title: const Text('BusGo'),
        actions: [
          // Nut dang xuat: quay ve man hinh dang nhap,
          // ten dang nhap da ghi nho van con de tu dien san (autofill).
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),

      // Than chinh: logo + ten + slogan, luoi 6 the chuc nang.
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
        child: Column(
          children: [
            // Loi chao "Hello" hien thi ten tai khoan dang dang nhap.
            // Vi du: "Hello, admin!" - lay tu SessionService.
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Hello, ${SessionService.instance.currentUser?.username ?? 'bạn'}!',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Logo hinh tron xanh co icon xe buyt trang.
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_bus,
                color: colors.onPrimary,
                size: 52,
              ),
            ),
            const SizedBox(height: 16),

            // Ten ung dung + khau hieu.
            Text(
              'BusGo',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('home_slogan'),
              style: TextStyle(color: colors.onSurface, fontSize: 15),
            ),
            const SizedBox(height: 28),

            // Luoi 2 cot cac the chuc nang.
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.2,
                children: [
                  _FlatCard(
                    icon: Icons.map,
                    label: context.tr('feature_map'),
                    onTap: () => _open(const MapScreen()),
                  ),
                  _FlatCard(
                    icon: Icons.explore,
                    label: context.tr('feature_tracking'),
                    onTap: () => _open(const BusTrackingScreen()),
                  ),
                  _FlatCard(
                    icon: Icons.list_alt,
                    label: context.tr('feature_routes'),
                    onTap: () => _open(const BusRouteListScreen()),
                  ),
                  _FlatCard(
                    icon: Icons.search,
                    label: context.tr('feature_stops'),
                    onTap: () => _open(const BusStopListScreen()),
                  ),
                  _FlatCard(
                    icon: Icons.favorite,
                    label: context.tr('feature_favorites'),
                    onTap: () => _open(const FavoriteScreen()),
                  ),
                  _FlatCard(
                    icon: Icons.bar_chart,
                    label: context.tr('feature_stats'),
                    onTap: () => _open(
                      _PlaceholderScreen(
                        title: context.tr('feature_stats'),
                        icon: Icons.bar_chart,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Nut tron "VA" (tro ly ao) goc phai duoi.
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        onPressed: () => _showVirtualAssistant(context),
        child: const Text(
          'VA',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),

      // Thanh menu duoi cung: Trang chu, Ban do, Thong bao, Cai dat.
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: colors.primary,
          indicatorColor: colors.onPrimary.withValues(alpha: 0.18),
          height: 64,
          iconTheme: WidgetStateProperty.resolveWith(
            (_) => IconThemeData(color: colors.onPrimary),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (_) => TextStyle(
              color: colors.onPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onNavSelected,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: context.tr('nav_home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.map_outlined),
              selectedIcon: const Icon(Icons.map),
              label: context.tr('nav_map'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.notifications_outlined),
              selectedIcon: const Icon(Icons.notifications),
              label: context.tr('nav_notifications'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: context.tr('nav_settings'),
            ),
          ],
        ),
      ),
    );
  }

  // Hoi lai truoc khi dang xuat, tranh nguoi dung bam nham.
  // Sau khi dang xuat: xoa phien hien tai va quay ve man hinh dang nhap.
  // Ten dang nhap da ghi nho van con duoc giu lai de autofill.
  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Xoa tai khoan khoi phien hien tai.
      SessionService.instance.logout();

      // Quay ve man hinh dang nhap.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // Hien bang thong tin nho khi bam nut "VA".
  void _showVirtualAssistant(BuildContext context) {
    final colors = context.colors;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'VA',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.tr('va_title'),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('va_msg'),
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// _FlatCard: the chuc nang phang - mau theo theme, icon + nhan ben tren.
class _FlatCard extends StatelessWidget {
  const _FlatCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: colors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// _PlaceholderScreen: man hinh tam cho cac tinh nang chua hoan thien.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyState(
        icon: icon,
        message: context.tr('coming_soon', params: {'name': title}),
      ),
    );
  }
}
