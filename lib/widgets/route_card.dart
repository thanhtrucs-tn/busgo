// route_card.dart
// Card hien thi mot tuyen xe buyt, dung chung cho nhieu man hinh:
// danh sach tuyen, danh sach yeu thich, danh sach tuyen di qua mot tram.

import 'package:flutter/material.dart';

import '../models/bus_route.dart';
import '../services/favorite_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class RouteCard extends StatelessWidget {
  const RouteCard({
    super.key,
    required this.route,
    this.onTap,
    this.showFavorite = true,
  });

  final BusRoute route;
  final VoidCallback? onTap;
  final bool showFavorite;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _RouteBadge(number: route.routeNumber),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 15,
                          color: colors.error,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${route.startPoint} → ${route.endPoint}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.tr('stops_count', params: {
                          'count': '${route.displayStopCount}',
                        }),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (showFavorite)
                IconButton(
                  tooltip: 'Yêu thích',
                  padding: EdgeInsets.zero,
                  icon: ListenableBuilder(
                    listenable: FavoriteService.instance,
                    builder: (context, _) {
                      final bool fav =
                          FavoriteService.instance.isFavorite(route.id);
                      return Icon(
                        fav ? Icons.favorite : Icons.favorite_border,
                        color: fav ? colors.error : colors.outlineVariant,
                      );
                    },
                  ),
                  onPressed: () {
                    FavoriteService.instance.toggle(route.id);
                  },
                ),
              Icon(Icons.chevron_right, color: colors.outlineVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// _RouteBadge: hinh vuong bo goc hien so tuyen, mau chu dao.
class _RouteBadge extends StatelessWidget {
  const _RouteBadge({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        number,
        style: TextStyle(
          color: colors.onPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}