// route_detail_screen.dart
// Man hinh xem chi tiet mot tuyen xe buyt:
// so tuyen, ten, diem bat dau/ket thuc, thoi gian hoat dong,
// danh sach tram dang timeline va cac xe buyt dang hoat dong tren tuyen.

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../l10n/app_localizations.dart';
import '../models/bus.dart';
import '../models/bus_route.dart';
import '../services/favorite_service.dart';
import '../theme/app_theme.dart';

class RouteDetailScreen extends StatelessWidget {
  const RouteDetailScreen({super.key, required this.route});

  // Tuyen xe buyt dang duoc xem.
  final BusRoute route;

  @override
  Widget build(BuildContext context) {
    // Loc cac xe buyt thuoc tuyen nay (theo routeId).
    final List<Bus> buses =
        sampleBuses.where((bus) => bus.routeId == route.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('route_no', params: {'number': route.routeNumber}),
        ),
        actions: [
          // Nut yeu thich tren AppBar, trang thai tu cap nhat.
          ListenableBuilder(
            listenable: FavoriteService.instance,
            builder: (context, _) {
              final bool fav = FavoriteService.instance.isFavorite(route.id);
              return IconButton(
                tooltip: 'Yêu thích',
                icon: Icon(
                  fav ? Icons.favorite : Icons.favorite_border,
                  color: fav ? context.colors.error : context.colors.onPrimary,
                ),
                onPressed: () {
                  FavoriteService.instance.toggle(route.id);
                },
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Phan dau: so tuyen + ten tuyen trong khoi hero.
          _buildHeader(context),

          const SizedBox(height: 16),

          // Card thong tin co ban.
          _buildInfoCard(context),

          const SizedBox(height: 20),

          // Tieu de danh sach tram (kem so luong).
          _buildSectionTitle(
            context,
            context.tr('journey'),
            context.tr('stops_count', params: {'count': '${route.stops.length}'}),
          ),
          const SizedBox(height: 8),

          // Hien thi tung tram theo dang timeline, danh so thu tu 1, 2, 3...
          for (int i = 0; i < route.stops.length; i++)
            _buildStopTimeline(context, i),

          const SizedBox(height: 12),

          // Tieu de danh sach xe buyt.
          _buildSectionTitle(
            context,
            context.tr('buses_on_route'),
            buses.isEmpty
                ? null
                : context.tr('bus_count', params: {'count': '${buses.length}'}),
          ),
          const SizedBox(height: 8),

          // Neu khong co xe nao thi hien thong bao.
          if (buses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                context.tr('no_active_buses'),
                style: TextStyle(color: context.colors.onSurfaceVariant),
              ),
            )
          else
            for (final bus in buses) _buildBusTile(bus),
        ],
      ),
    );
  }

  // Phan dau man hinh: so tuyen trong o trang + ten tuyen.
  Widget _buildHeader(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.onPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              route.routeNumber,
              style: TextStyle(
                color: colors.primary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${route.startPoint} → ${route.endPoint}',
                  style: TextStyle(color: colors.onPrimary.withValues(alpha: 0.85), fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.onPrimary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, color: colors.onPrimary, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        context.tr('service_hours', params: {
                          'time': route.operatingTime,
                        }),
                        style: TextStyle(
                          color: colors.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card thong tin co ban cua tuyen.
  Widget _buildInfoCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            _InfoTile(
              icon: Icons.directions,
              label: context.tr('start_point'),
              value: route.startPoint,
            ),
            _InfoTile(
              icon: Icons.flag_outlined,
              label: context.tr('end_point'),
              value: route.endPoint,
            ),
            _InfoTile(
              icon: Icons.schedule,
              label: context.tr('operating_time'),
              value: route.operatingTime,
            ),
            _InfoTile(
              icon: Icons.layers_outlined,
              label: context.tr('num_stops'),
              value: context.tr('stops_count', params: {
                'count': '${route.stops.length}',
              }),
            ),
          ],
        ),
      ),
    );
  }

  // Tieu de mot phan noi dung + so lieu kem theo.
  Widget _buildSectionTitle(BuildContext context, String title, String? badge) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: context.colors.onSurface,
            ),
          ),
          const Spacer(),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.colors.onPrimaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Mot tram duoi dang timeline: so thu tu noi voi duong ke dung.
  Widget _buildStopTimeline(BuildContext context, int index) {
    final colors = context.colors;
    final stop = route.stops[index];
    final bool isFirst = index == 0;
    final bool isLast = index == route.stops.length - 1;

    // Mau cua vong tron so thu tu theo vi tri tren tuyen.
    final Color circleColor = isFirst
        ? colors.primary
        : (isLast ? colors.secondary : colors.primaryContainer);
    final Color circleTextColor = (isFirst || isLast)
        ? colors.onPrimary
        : colors.onPrimaryContainer;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: circleColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: circleTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                // Duong ke noi tiep cac tram (tru tram cuoi).
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 16, bottom: isLast ? 0 : 8),
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              stop.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                          if (isFirst)
                            _StopTag(
                              label: context.tr('stop_start_tag'),
                              color: colors.primary,
                            ),
                          if (isLast)
                            _StopTag(
                              label: context.tr('stop_end_tag'),
                              color: colors.secondary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stop.address,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mot xe buyt duoi dang Card, hien bien so + trang thai.
  Widget _buildBusTile(Bus bus) {
    final bool active = bus.status == 'active';

    return Builder(
      builder: (context) {
        final colors = context.colors;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.directions_bus, color: colors.onPrimary, size: 24),
            ),
            title: Text(
              bus.busNumber,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              active ? context.tr('bus_active') : context.tr('bus_stopped'),
              style: const TextStyle(fontSize: 12.5),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: active
                    ? colors.primaryContainer
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                active ? context.tr('bus_active') : context.tr('bus_stopped'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Nhan nho hien tren tram dau / tram cuoi cua tuyen.
class _StopTag extends StatelessWidget {
  const _StopTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}

// Mot dong thong tin (icon + nhan + gia tri) trong card thong tin.
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: colors.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}