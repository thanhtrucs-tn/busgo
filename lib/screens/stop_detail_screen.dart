// stop_detail_screen.dart
// Man hinh chi tiet mot tram xe buyt:
// thong tin tram + cac tuyen di qua tram + xem vi tri tren ban do.

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../l10n/app_localizations.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../theme/app_theme.dart';
import '../widgets/route_card.dart';
import 'map_screen.dart';
import 'route_detail_screen.dart';

class StopDetailScreen extends StatelessWidget {
  const StopDetailScreen({super.key, required this.stop});

  // Tram dang duoc xem.
  final BusStop stop;

  @override
  Widget build(BuildContext context) {
    // Tim cac tuyen xe buyt di qua tram nay.
    final List<BusRoute> routes = routesThroughStop(stop.id);

    return Scaffold(
      appBar: AppBar(title: Text(stop.name, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Card thong tin tram.
          Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: context.colors.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.place,
                          color: context.colors.error,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop.name,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: context.colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr('stop_type'),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: context.colors.outlineVariant,
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.location_on_outlined,
                    label: context.tr('address'),
                    value: stop.address,
                    iconColor: context.colors.error,
                  ),
                  _InfoTile(
                    icon: Icons.explore_outlined,
                    label: context.tr('coordinates'),
                    value: '${stop.latitude}, ${stop.longitude}',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Nut xem vi tri tram tren ban do.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapScreen(
                        stops: [
                          MapStop(
                            name: stop.name,
                            latitude: stop.latitude,
                            longitude: stop.longitude,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map),
                label: Text(context.tr('view_on_map')),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Tieu de danh sach cac tuyen di qua tram.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  context.tr('routes_through'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.colors.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    context.tr('route_count', params: {'count': '${routes.length}'}),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Neu khong co tuyen nao thi hien thong bao.
          if (routes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                context.tr('no_routes_through'),
                style: TextStyle(color: context.colors.onSurfaceVariant),
              ),
            )
          else
            for (final route in routes)
              RouteCard(
                route: route,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteDetailScreen(route: route),
                    ),
                  );
                },
              ),
        ],
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
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor ?? colors.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}