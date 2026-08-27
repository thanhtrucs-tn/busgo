// favorite_screen.dart
// Man hinh hien thi danh sach cac tuyen xe buyt yeu thich.
// Co the bo yeu thich hoac bam vao tuyen de xem chi tiet.

import 'package:flutter/material.dart';

import '../models/bus_route.dart';
import '../services/favorite_service.dart';
import 'route_detail_screen.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tuyến yêu thích')),
      body: ListenableBuilder(
        // Lang nghe FavoriteService de cap nhat khi them/bo yeu thich.
        listenable: FavoriteService.instance,
        builder: (context, _) {
          final List<BusRoute> routes =
              FavoriteService.instance.favoriteRoutes;

          // Neu chua co tuyen yeu thich nao thi hien thong bao.
          if (routes.isEmpty) {
            return const Center(
              child: Text('Chưa có tuyến yêu thích nào'),
            );
          }

          return ListView.builder(
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      route.routeNumber,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(route.name),
                  subtitle: Text('${route.startPoint} → ${route.endPoint}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bam vao tim do se bo yeu thich.
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () {
                          FavoriteService.instance.toggle(route.id);
                        },
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RouteDetailScreen(route: route),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}