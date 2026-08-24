// bus_stop_list_screen.dart
// Man hinh hien thi danh sach cac tram xe buyt.
// Tap vao mot tram de chuyen sang man hinh ban do.

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import 'map_screen.dart';

class BusStopListScreen extends StatelessWidget {
  const BusStopListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách trạm')),
      body: ListView.builder(
        itemCount: sampleStops.length,
        itemBuilder: (context, index) {
          final stop = sampleStops[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.place, color: Colors.green),
              title: Text(stop.name),
              subtitle: Text(stop.address),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapScreen()),
                );
              },
            ),
          );
        },
      ),
    );
  }
}