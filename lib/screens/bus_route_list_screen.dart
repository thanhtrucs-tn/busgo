// bus_route_list_screen.dart
// Màn hình DANH SÁCH TUYẾN xe buýt.
// Dữ liệu lấy từ API backend thông qua TransitService.
// Có ô tìm kiếm (lọc cục bộ), trạng thái loading/lỗi/không có dữ liệu.
// Bấm vào tuyến để mở màn hình chi tiết.

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

class BusRouteListScreen extends StatefulWidget {
  const BusRouteListScreen({super.key});

  @override
  State<BusRouteListScreen> createState() => _BusRouteListScreenState();
}

class _BusRouteListScreenState extends State<BusRouteListScreen> {
  String _query = '';

  // Trạng thái tải dữ liệu.
  bool _loading = true;
  String? _error;
  List<BusRoute> _routes = const [];

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  // Gọi API lấy danh sách tuyến.
  Future<void> _loadRoutes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final routes = await TransitService.instance.fetchRoutes();
      if (!mounted) return;
      setState(() {
        _routes = routes;
        _loading = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err is TransitException
            ? err.message
            : context.tr('load_error');
        _loading = false;
      });
    }
  }

  // Lọc danh sách tuyến theo từ khóa tìm kiếm (ở phía app).
  List<BusRoute> get _filteredRoutes {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _routes;

    return _routes.where((route) {
      return route.routeNumber.toLowerCase().contains(query) ||
          route.name.toLowerCase().contains(query) ||
          route.startPoint.toLowerCase().contains(query) ||
          route.endPoint.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('route_list_title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(message: _error!, onRetry: _loadRoutes)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListenableBuilder(
      // Lắng nghe FavoriteService để cập nhật trái tim khi đổi trạng thái.
      listenable: FavoriteService.instance,
      builder: (context, _) {
        final routes = _filteredRoutes;

        return Column(
          children: [
            // Ô tìm kiếm.
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: context.tr('search_route_hint'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => _query = '');
                          },
                        ),
                ),
                onChanged: (value) {
                  setState(() => _query = value);
                },
              ),
            ),

            // Danh sách tuyến (đã được lọc).
            Expanded(
              child: routes.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off,
                      message: context.tr('no_routes_found'),
                    )
                  : ListView.builder(
                      itemCount: routes.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                            child: Text(
                              context.tr('routes_active', params: {
                                'count': '${routes.length}',
                              }),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          );
                        }

                        final BusRoute route = routes[index - 1];

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
                    ),
            ),
          ],
        );
      },
    );
  }
}
