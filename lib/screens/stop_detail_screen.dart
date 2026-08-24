// stop_detail_screen.dart
// Man hinh chi tiet mot tram xe buyt:
// thong tin tram + cac tuyen di qua tram + xem vi tri tren ban do.

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';
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
      appBar: AppBar(title: Text(stop.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card thong tin tram.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Địa chỉ', value: stop.address),
                  _InfoRow(label: 'Vĩ độ', value: '${stop.latitude}'),
                  _InfoRow(label: 'Kinh độ', value: '${stop.longitude}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Nut xem vi tri tram tren ban do.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MapScreen(stops: [stop]),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('Xem vị trí trên bản đồ'),
            ),
          ),

          const SizedBox(height: 16),

          // Tieu de danh sach cac tuyen di qua tram.
          Text(
            'Các tuyến đi qua trạm (${routes.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          // Neu khong co tuyen nao thi hien thong bao.
          if (routes.isEmpty)
            const Text('Không có tuyến nào đi qua trạm này')
          else
            for (final route in routes)
              Card(
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
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RouteDetailScreen(route: route),
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

// Widget nho hien thi mot dong thong tin (nhan + gia tri).
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}