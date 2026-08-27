// bus_route_list_screen.dart
// Man hinh hien thi danh sach cac tuyen xe buyt.
// Co o tim kiem de loc tuyen va nut trai tim de yeu thich.
// Tap vao tuyen de chuyen sang man hinh chi tiet.

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/bus_route.dart';
import '../services/favorite_service.dart';
import 'route_detail_screen.dart';

class BusRouteListScreen extends StatefulWidget {
  const BusRouteListScreen({super.key});

  @override
  State<BusRouteListScreen> createState() => _BusRouteListScreenState();
}

// StatefulWidget vi tu khoa tim kiem thay doi khi nguoi dung go chu.
class _BusRouteListScreenState extends State<BusRouteListScreen> {
  String _query = '';

  // Loc danh sach tuyen theo tu khoa tim kiem.
  List<BusRoute> get _filteredRoutes {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return sampleRoutes;

    return sampleRoutes.where((route) {
      return route.routeNumber.toLowerCase().contains(query) ||
          route.name.toLowerCase().contains(query) ||
          route.startPoint.toLowerCase().contains(query) ||
          route.endPoint.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách tuyến')),
      body: ListenableBuilder(
        // Lang nghe FavoriteService de cap nhat trai tim khi doi trang thai.
        listenable: FavoriteService.instance,
        builder: (context, _) {
          final routes = _filteredRoutes;

          return Column(
            children: [
              // O tim kiem.
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm theo số tuyến hoặc tên',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _query = '');
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _query = value);
                  },
                ),
              ),

              // Danh sach tuyen (da duoc loc).
              Expanded(
                child: routes.isEmpty
                    ? const Center(child: Text('Không tìm thấy tuyến nào'))
                    : ListView.builder(
                        itemCount: routes.length,
                        itemBuilder: (context, index) {
                          final BusRoute route = routes[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                child: Text(
                                  route.routeNumber,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(route.name),
                              subtitle: Text(
                                '${route.startPoint} → ${route.endPoint}',
                              ),
                              // Nut yeu thich + mui ten.
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      FavoriteService.instance
                                              .isFavorite(route.id)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: FavoriteService.instance
                                              .isFavorite(route.id)
                                          ? Colors.red
                                          : null,
                                    ),
                                    onPressed: () {
                                      FavoriteService.instance
                                          .toggle(route.id);
                                    },
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RouteDetailScreen(route: route),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}