// bus_stop_list_screen.dart
// Man hinh hien thi danh sach cac tram xe buyt.
// Co o tim kiem de loc tram theo ten hoac dia chi.
// Tap vao mot tram de xem chi tiet.

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/bus_stop.dart';
import 'stop_detail_screen.dart';

class BusStopListScreen extends StatefulWidget {
  const BusStopListScreen({super.key});

  @override
  State<BusStopListScreen> createState() => _BusStopListScreenState();
}

// StatefulWidget vi tu khoa tim kiem thay doi khi nguoi dung go chu.
class _BusStopListScreenState extends State<BusStopListScreen> {
  String _query = '';

  // Loc danh sach tram theo tu khoa tim kiem.
  List<BusStop> get _filteredStops {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return sampleStops;

    return sampleStops.where((stop) {
      return stop.name.toLowerCase().contains(query) ||
          stop.address.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final stops = _filteredStops;

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách trạm')),
      body: Column(
        children: [
          // O tim kiem tram.
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm theo tên trạm hoặc địa chỉ',
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

          // Danh sach tram (da duoc loc).
          Expanded(
            child: stops.isEmpty
                ? const Center(child: Text('Không tìm thấy trạm nào'))
                : ListView.builder(
                    itemCount: stops.length,
                    itemBuilder: (context, index) {
                      final stop = stops[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.place, color: Colors.green),
                          title: Text(stop.name),
                          subtitle: Text(stop.address),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StopDetailScreen(stop: stop),
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