// bus_route_list_screen.dart
// Man hinh hien thi danh sach cac tuyen xe buyt.
// Co o tim kiem de loc tuyen theo so hieu hoac ten.
// Tap vao mot tuyen de chuyen sang man hinh chi tiet.

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/bus_route.dart';
import 'route_detail_screen.dart';

class BusRouteListScreen extends StatefulWidget {
  const BusRouteListScreen({super.key});

  @override
  State<BusRouteListScreen> createState() => _BusRouteListScreenState();
}

// State chua du lieu thay doi (tu khoa tim kiem).
// StatefulWidget can vi tu khoa tim kiem thay doi khi nguoi dung go chu.
class _BusRouteListScreenState extends State<BusRouteListScreen> {
  // Tu khoa tim kiem nguoi dung nhap vao.
  String _query = '';

  // Loc danh sach tuyen theo tu khoa tim kiem.
  // getter: duoc tinh lai moi khi goi (sau moi lan setState).
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
    final routes = _filteredRoutes;

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách tuyến')),
      body: Column(
        children: [
          // O tim kiem o dau man hinh.
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm theo số tuyến hoặc tên',
                prefixIcon: const Icon(Icons.search),
                // Nut "X" de xoa tu khoa, chi hien khi co chu.
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
              // Goi moi khi nguoi dung go chu.
              onChanged: (value) {
                // setState bao Flutter ve lai giao dien.
                setState(() => _query = value);
              },
            ),
          ),

          // Danh sach tuyen (da duoc loc).
          Expanded(
            child: routes.isEmpty
                // Neu khong co tuyen nao khop thi hien thong bao.
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
                          subtitle:
                              Text('${route.startPoint} → ${route.endPoint}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Chuyen sang man hinh chi tiet.
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
      ),
    );
  }
}