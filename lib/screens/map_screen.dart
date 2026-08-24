// map_screen.dart
// Man hinh ban do dung OpenStreetMap (flutter_map).
// Khong can API key, chay duoc tren Windows, Chrome va Android.
// Hien thi vi tri cac tram (Marker) va lo trinh noi cac tram (Polyline).

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/sample_data.dart';
import '../models/bus_stop.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.stops});

  // Danh sach tram can hien thi.
  // Neu khong truyen thi hien thi toan bo tram trong du lieu mau.
  final List<BusStop>? stops;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

// StatefulWidget vi can giu MapController de dieu chinh camera.
class _MapScreenState extends State<MapScreen> {
  // Dung de dieu khien camera cua ban do (zoom, di chuyen).
  final MapController _mapController = MapController();

  // Danh sach tram se ve len ban do.
  List<BusStop> get _stops => widget.stops ?? sampleStops;

  // Tao cac Marker tu danh sach tram.
  List<Marker> _buildMarkers() {
    return _stops.map((stop) {
      return Marker(
        point: LatLng(stop.latitude, stop.longitude),
        width: 40,
        height: 40,
        // Cham vao marker se hien thong tin tram.
        child: GestureDetector(
          onTap: () => _showStopInfo(stop),
          child: const Icon(Icons.location_pin, color: Colors.red, size: 36),
        ),
      );
    }).toList();
  }

  // Tao duong noi (lo trinh) di qua cac tram theo thu tu.
  List<Polyline> _buildPolylines() {
    final points =
        _stops.map((s) => LatLng(s.latitude, s.longitude)).toList();

    // Can it nhat 2 diem moi ve duoc duong.
    if (points.length < 2) return [];

    return [
      Polyline(points: points, strokeWidth: 4, color: Colors.green),
    ];
  }

  // Di chuyen camera de nhin thay tat ca cac tram.
  void _fitBounds() {
    if (_stops.isEmpty) return;

    // Neu chi co 1 tram thi chi can di chuyen camera den tram do.
    if (_stops.length == 1) {
      _mapController.move(
        LatLng(_stops.first.latitude, _stops.first.longitude),
        15,
      );
      return;
    }

    double minLat = _stops.first.latitude;
    double maxLat = _stops.first.latitude;
    double minLng = _stops.first.longitude;
    double maxLng = _stops.first.longitude;

    for (final stop in _stops) {
      if (stop.latitude < minLat) minLat = stop.latitude;
      if (stop.latitude > maxLat) maxLat = stop.latitude;
      if (stop.longitude < minLng) minLng = stop.longitude;
      if (stop.longitude > maxLng) maxLng = stop.longitude;
    }

    // fitCamera se zoom den vung chua toan bo cac tram.
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        ),
        padding: const EdgeInsets.all(40),
      ),
    );
  }

  // Hien thong tin tram khi nguoi dung cham vao marker.
  void _showStopInfo(BusStop stop) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stop.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(stop.address),
              const SizedBox(height: 4),
              Text('${stop.latitude}, ${stop.longitude}'),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bản đồ')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          // Vi tri ban dau cua camera (trung tam TP.HCM).
          initialCenter: const LatLng(10.7756, 106.6985),
          initialZoom: 12,
          // Khi ban do tao xong, tu dong zoom de thay het cac tram.
          onMapReady: _fitBounds,
        ),
        children: [
          // Lop nen ban do (OpenStreetMap, khong can API key).
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.busgo',
          ),
          // Lop marker cac tram.
          MarkerLayer(markers: _buildMarkers()),
          // Lop duong lo trinh.
          PolylineLayer(polylines: _buildPolylines()),
        ],
      ),
    );
  }
}