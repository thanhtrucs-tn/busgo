// route_detail_screen.dart
// Man hinh xem chi tiet mot tuyen xe buyt:
// so tuyen, ten, diem bat dau/ket thuc, thoi gian hoat dong,
// danh sach tram va cac xe buyt dang hoat dong tren tuyen.

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/bus.dart';
import '../models/bus_route.dart';

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
      appBar: AppBar(title: Text('Tuyến ${route.routeNumber}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Phan dau: logo so tuyen + ten tuyen.
          _buildHeader(context),

          const SizedBox(height: 16),

          // Card thong tin co ban.
          _buildInfoCard(context),

          const SizedBox(height: 16),

          // Tieu de danh sach tram (kem so luong).
          Text(
            'Danh sách trạm (${route.stops.length} trạm)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          // Hien thi tung tram, danh so thu tu 1, 2, 3...
          for (int i = 0; i < route.stops.length; i++)
            _buildStopTile(context, i),

          const SizedBox(height: 16),

          // Tieu de danh sach xe buyt.
          Text(
            'Xe buýt trên tuyến',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          // Neu khong co xe nao thi hien thong bao.
          if (buses.isEmpty)
            const Text('Không có xe buýt đang hoạt động')
          else
            for (final bus in buses) _buildBusTile(bus),
        ],
      ),
    );
  }

  // Phan dau man hinh: so tuyen trong hinh tron + ten tuyen.
  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            route.routeNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          route.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          '${route.startPoint} → ${route.endPoint}',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  // Card thong tin co ban cua tuyen.
  Widget _buildInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(label: 'Số tuyến', value: route.routeNumber),
            _InfoRow(label: 'Điểm bắt đầu', value: route.startPoint),
            _InfoRow(label: 'Điểm kết thúc', value: route.endPoint),
            _InfoRow(label: 'Thời gian hoạt động', value: route.operatingTime),
            _InfoRow(label: 'Số trạm', value: '${route.stops.length}'),
          ],
        ),
      ),
    );
  }

  // Mot tram duoi dang Card, co danh so thu tu.
  Widget _buildStopTile(BuildContext context, int index) {
    final stop = route.stops[index];
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(stop.name),
        subtitle: Text('${stop.address}\n${stop.latitude}, ${stop.longitude}'),
        isThreeLine: true,
      ),
    );
  }

  // Mot xe buyt duoi dang Card, hien bien so + trang thai.
  Widget _buildBusTile(Bus bus) {
    final String statusText = bus.status == 'active' ? 'Đang hoạt động' : 'Dừng';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.directions_bus),
        title: Text(bus.busNumber),
        subtitle: Text(statusText),
        trailing: const Icon(Icons.chevron_right),
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