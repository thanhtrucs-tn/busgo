// favorite_screen.dart
// Man hinh hien thi danh sach cac tuyen xe buyt yeu thich.
// Co the bo yeu thich hoac bam vao tuyen de xem chi tiet.

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/bus_route.dart';
import '../services/favorite_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/route_card.dart';
import 'route_detail_screen.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

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
                    '${FavoriteService.instance.favoriteRoutes.length}',
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
      body: ListenableBuilder(
        // Lang nghe FavoriteService de cap nhat khi them/bo yeu thich.
        listenable: FavoriteService.instance,
        builder: (context, _) {
          final List<BusRoute> routes =
              FavoriteService.instance.favoriteRoutes;

          // Neu chua co tuyen yeu thich nao thi hien thong bao.
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
      ),
    );
  }
}