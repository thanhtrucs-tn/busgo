// home_screen.dart
// Man hinh chinh (Home) cua ung dung BusGo.
// Day la man hinh dau tien nguoi dung nhin thay khi mo app.
// Cac the chuc nang co the chuyen sang man hinh tuong ung.

import 'package:flutter/material.dart';

import 'bus_route_list_screen.dart';
import 'bus_stop_list_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BusGo'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Logo ung dung: hinh tron co icon xe buyt o giua.
            CircleAvatar(
              radius: 48,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(
                Icons.directions_bus,
                size: 48,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'BusGo',
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 8),

            Text(
              'Theo dõi tuyến xe buýt của bạn',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 32),

            // Loi 2 cot cac the chuc nang.
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _FeatureCard(
                    icon: Icons.list_alt,
                    title: 'Danh sách tuyến',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BusRouteListScreen(),
                        ),
                      );
                    },
                  ),
                  _FeatureCard(
                    icon: Icons.search,
                    title: 'Tìm trạm',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BusStopListScreen(),
                        ),
                      );
                    },
                  ),
                  _FeatureCard(
                    icon: Icons.map,
                    title: 'Bản đồ',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MapScreen(),
                        ),
                      );
                    },
                  ),
                  _FeatureCard(
                    icon: Icons.favorite,
                    title: 'Yêu thích',
                    onTap: () {
                      // Chuc nang yeu thich se duoc lam o Phase 9.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chức năng sẽ có ở Phase 9')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// _FeatureCard la widget nho hien thi mot the chuc nang (icon + tieu de).
// Khi nguoi dung chay vao thi goi onTap (chuyen man hinh).
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}