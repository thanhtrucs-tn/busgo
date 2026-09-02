// statistics_screen.dart
// Màn hình THỐNG KÊ của ứng dụng BusGo.
// Dữ liệu lấy từ các nguồn dùng chung của app:
//  - sampleRoutes / sampleStops / sampleBuses (dữ liệu mẫu).
//  - FavoriteService (số tuyến yêu thích).
// Hiển thị: tổng quan (4 thẻ số), bảng xếp hạng trạm đông tuyến nhất,
// tuyến nhiều trạm nhất và xe đang chạy theo từng tuyến.

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../l10n/app_localizations.dart';
import '../services/favorite_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Số tuyến đi qua từng trạm: { idTrạm: sốTuyến }.
    final Map<String, int> routeCountByStop = <String, int>{};
    for (final route in sampleRoutes) {
      for (final stop in route.stops) {
        routeCountByStop[stop.id] = (routeCountByStop[stop.id] ?? 0) + 1;
      }
    }

    // Xếp hạng trạm: giảm dần theo số tuyến đi qua.
    final topStops = sampleStops
        .map((stop) => (stop: stop, count: routeCountByStop[stop.id] ?? 0))
        .where((item) => item.count > 0)
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    // Xếp hạng tuyến: giảm dần theo số trạm dừng.
    final topRoutes = List.of(sampleRoutes)
      ..sort((a, b) => b.stops.length.compareTo(a.stops.length));

    // Số xe đang chạy theo từng tuyến: { idTuyến: sốXe }.
    final busesByRoute = <String, int>{};
    for (final bus in sampleBuses) {
      busesByRoute[bus.routeId] = (busesByRoute[bus.routeId] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('stats_title'))),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // ============================ TỔNG QUAN ============================
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.route_outlined,
                  value: '${sampleRoutes.length}',
                  label: context.tr('stats_total_routes'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.directions_bus_outlined,
                  value: '${sampleBuses.length}',
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
                  value: '${sampleStops.length}',
                  label: context.tr('stats_total_stops'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ListenableBuilder(
                  listenable: FavoriteService.instance,
                  builder: (context, _) => _StatCard(
                    icon: Icons.favorite,
                    value: '${FavoriteService.instance.favoriteRoutes.length}',
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
          if (topStops.isEmpty)
            EmptyState(
              icon: Icons.place_outlined,
              message: context.tr('stats_no_data'),
            )
          else
            _BarList(
              items: [
                for (final item in topStops)
                  _BarItem(
                    label: '${item.stop.name} · ${item.stop.address}',
                    value: item.count,
                    suffix: context.tr(
                      'stats_stop_routes',
                      params: {'count': '${item.count}'},
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
                  value: route.stops.length,
                  suffix: context.tr(
                    'stats_route_stops',
                    params: {'count': '${route.stops.length}'},
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
          if (busesByRoute.isEmpty)
            EmptyState(
              icon: Icons.directions_bus_outlined,
              message: context.tr('stats_no_buses'),
            )
          else
            _BarList(
              items: [
                for (final route in sampleRoutes)
                  if ((busesByRoute[route.id] ?? 0) > 0)
                    _BarItem(
                      label: 'Tuyến ${route.routeNumber} · ${route.name}',
                      value: busesByRoute[route.id]!,
                      suffix: context.tr(
                        'bus_count',
                        params: {'count': '${busesByRoute[route.id]}'},
                      ),
                    ),
              ],
            ),
        ],
      ),
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
  const _BarItem({required this.label, required this.value, required this.suffix});

  final String label;
  final int value;
  final String suffix;
}

// Danh sách xếp hạng dạng thanh ngang: mỗi mục là 1 thanh tỉ lệ với giá trị lớn nhất.
class _BarList extends StatelessWidget {
  const _BarList({required this.items});

  final List<_BarItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (items.isEmpty) return const SizedBox.shrink();

    final int maxValue = items
        .map((item) => item.value)
        .reduce((a, b) => a > b ? a : b);

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