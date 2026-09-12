// statistics_screen.dart
// Màn hình THỐNG KÊ của ứng dụng BusGo.
// Dữ liệu lấy từ API backend (tuyến, trạm, xe) + FavoriteService.
// Hiển thị: tổng quan (4 thẻ số), trạm có nhiều tuyến nhất,
// tuyến nhiều trạm nhất và xe đang chạy theo từng tuyến.

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/bus.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../services/favorite_service.dart';
import '../services/transit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _loading = true;
  String? _error;

  List<BusRoute> _routes = const [];
  List<BusStop> _stops = const [];

  // Số xe đang hoạt động theo từng tuyến: { idTuyến: sốXe }.
  final Map<String, int> _busesByRoute = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final routes = await TransitService.instance.fetchRoutes();
      final stops = await TransitService.instance.fetchStops();

      // Lấy xe của từng tuyến (số tuyến ít nên gọi tuần tự là đủ).
      final busesByRoute = <String, int>{};
      for (final route in routes) {
        final buses = await TransitService.instance.fetchRouteBuses(route.id);
        busesByRoute[route.id] =
            buses.where((Bus b) => b.isActive).length;
      }

      if (!mounted) return;
      setState(() {
        _routes = routes;
        _stops = stops;
        _busesByRoute
          ..clear()
          ..addAll(busesByRoute);
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
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('stats_title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Xếp hạng trạm: giảm dần theo số tuyến đi qua.
    final topStops = List.of(_stops)
      ..sort((a, b) => b.routeCount.compareTo(a.routeCount));
    final stopsWithRoutes = topStops.where((s) => s.routeCount > 0).toList();

    // Xếp hạng tuyến: giảm dần theo số trạm dừng.
    final topRoutes = List.of(_routes)
      ..sort((a, b) => b.displayStopCount.compareTo(a.displayStopCount));

    // Tổng số xe đang hoạt động.
    final totalActiveBuses =
        _busesByRoute.values.fold<int>(0, (sum, count) => sum + count);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // ============================ TỔNG QUAN ============================
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.route_outlined,
                value: '${_routes.length}',
                label: context.tr('stats_total_routes'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.directions_bus_outlined,
                value: '$totalActiveBuses',
                label: context.tr('stats_buses_active'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.place_outlined,
                value: '${_stops.length}',
                label: context.tr('stats_total_stops'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ListenableBuilder(
                listenable: FavoriteService.instance,
                builder: (context, _) => _StatCard(
                  icon: Icons.favorite,
                  value: '${FavoriteService.instance.favoriteCount}',
                  label: context.tr('stats_favorite_route'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ========================= TRẠM ĐÔNG TUYẾN NHẤT =========================
        _SectionHeader(
          icon: Icons.leaderboard_outlined,
          title: context.tr('stats_top_stops'),
        ),
        if (stopsWithRoutes.isEmpty)
          EmptyState(
            icon: Icons.place_outlined,
            message: context.tr('stats_no_data'),
          )
        else
          _BarList(
            items: [
              for (final stop in stopsWithRoutes.take(8))
                _BarItem(
                  label: '${stop.name} · ${stop.address}',
                  value: stop.routeCount,
                  suffix: context.tr(
                    'stats_stop_routes',
                    params: {'count': '${stop.routeCount}'},
                  ),
                ),
            ],
          ),

        const SizedBox(height: 18),

        // ========================= TUYẾN NHIỀU TRẠM NHẤT =========================
        _SectionHeader(
          icon: Icons.alt_route,
          title: context.tr('stats_top_routes'),
        ),
        _BarList(
          items: [
            for (final route in topRoutes)
              _BarItem(
                label: 'Tuyến ${route.routeNumber} · ${route.name}',
                value: route.displayStopCount,
                suffix: context.tr(
                  'stats_route_stops',
                  params: {'count': '${route.displayStopCount}'},
                ),
              ),
          ],
        ),

        const SizedBox(height: 18),

        // ========================= XE ĐANG CHẠY THEO TUYẾN =========================
        _SectionHeader(
          icon: Icons.directions_bus,
          title: context.tr('stats_buses_by_route'),
        ),
        if (totalActiveBuses == 0)
          EmptyState(
            icon: Icons.directions_bus_outlined,
            message: context.tr('stats_no_buses'),
          )
        else
          _BarList(
            items: [
              for (final route in _routes)
                if ((_busesByRoute[route.id] ?? 0) > 0)
                  _BarItem(
                    label: 'Tuyến ${route.routeNumber} · ${route.name}',
                    value: _busesByRoute[route.id]!,
                    suffix: context.tr(
                      'bus_count',
                      params: {'count': '${_busesByRoute[route.id]}'},
                    ),
                  ),
            ],
          ),
      ],
    );
  }
}

// Thẻ số tổng quan: icon + giá trị lớn + nhãn.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// Tiêu đề một nhóm thống kê.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// Một hàng số liệu trong bảng xếp hạng.
class _BarItem {
  const _BarItem({
    required this.label,
    required this.value,
    required this.suffix,
  });

  final String label;
  final int value;
  final String suffix;
}

// Danh sách xếp hạng dạng thanh ngang.
class _BarList extends StatelessWidget {
  const _BarList({required this.items});

  final List<_BarItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (items.isEmpty) return const SizedBox.shrink();

    final int maxValue =
        items.map((item) => item.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.suffix,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxValue == 0 ? 0 : item.value / maxValue,
                      minHeight: 7,
                      backgroundColor: colors.surfaceContainerHighest,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
