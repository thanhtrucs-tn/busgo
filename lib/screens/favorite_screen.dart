// favorite_screen.dart
// Màn hình danh sách TUYẾN YÊU THÍCH.
// Tuyến được lấy từ API rồi lọc theo danh sách id đã lưu (FavoriteService).
// Có thể bỏ yêu thích hoặc bấm vào tuyến để xem chi tiết.

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/bus_route.dart';
import '../services/favorite_service.dart';
import '../services/transit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/route_card.dart';
import 'route_detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  bool _loading = true;
  String? _error;
  List<BusRoute> _allRoutes = const [];

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final routes = await TransitService.instance.fetchRoutes();
      if (!mounted) return;
      setState(() {
        _allRoutes = routes;
        _loading = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error =
            err is TransitException ? err.message : context.tr('load_error');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('favorites_title')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: ListenableBuilder(
                listenable: FavoriteService.instance,
                builder: (context, _) {
                  return Text(
                    '${_favoriteRoutes.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.onPrimary,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(message: _error!, onRetry: _loadRoutes)
              : _buildBody(),
    );
  }

  // Lọc các tuyến yêu thích từ danh sách tuyến lấy được.
  List<BusRoute> get _favoriteRoutes {
    final ids = FavoriteService.instance.favoriteIds;
    return _allRoutes.where((route) => ids.contains(route.id)).toList();
  }

  Widget _buildBody() {
    return ListenableBuilder(
      // Lắng nghe FavoriteService để cập nhật khi thêm/bỏ yêu thích.
      listenable: FavoriteService.instance,
      builder: (context, _) {
        final routes = _favoriteRoutes;

        // Nếu chưa có tuyến yêu thích nào thì hiện thông báo.
        if (routes.isEmpty) {
          return EmptyState(
            icon: Icons.favorite_border,
            message: context.tr('favorites_empty'),
          );
        }

        return ListView.builder(
          itemCount: routes.length,
          itemBuilder: (context, index) {
            final route = routes[index];

            return RouteCard(
              route: route,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RouteDetailScreen(route: route),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
