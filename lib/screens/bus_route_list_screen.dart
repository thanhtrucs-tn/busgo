// bus_route_list_screen.dart
// Man hinh hien thi danh sach cac tuyen xe buyt.
// Co o tim kiem de loc tuyen va nut trai tim de yeu thich.
// Tap vao tuyen de chuyen sang man hinh chi tiet.

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../l10n/app_localizations.dart';
import '../models/bus_route.dart';
import '../services/favorite_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/route_card.dart';
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
      appBar: AppBar(title: Text(context.tr('route_list_title'))),
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

              // Danh sach tuyen (da duoc loc).
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
                                  builder: (_) => RouteDetailScreen(
                                    route: route,
                                  ),
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
      ),
    );
  }
}