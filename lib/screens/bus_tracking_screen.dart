// bus_tracking_screen.dart
// Man hinh theo doi vi tri cac xe buyt tren ban do.
// Day la DU LIEU MO PHONG (xe tu dong di chuyen), khong phai GPS that.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/sample_data.dart';
import '../l10n/app_localizations.dart';
import '../models/bus.dart';
import '../theme/app_theme.dart';

class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({super.key});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  final MapController _mapController = MapController();

  // Danh sach cac xe dang duoc theo doi (co vi tri hien tai).
  late List<_TrackedBus> _trackedBuses;

  // Bo hen gio: cu moi 2 giay cap nhat vi tri mot lan.
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Khoi tao vi tri ban dau cho tung xe tu du lieu mau.
    _trackedBuses = sampleBuses.map((bus) {
      return _TrackedBus(
        info: bus,
        position: LatLng(bus.latitude, bus.longitude),
        waypoints: _buildWaypoints(bus.routeId),
      );
    }).toList();

    // Cap nhat vi tri xe theo chu ky.
    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _updatePositions(),
    );
  }

  @override
  void dispose() {
    // Luon huy Timer khi man hinh bi dong de tranh loi.
    _timer?.cancel();
    super.dispose();
  }

  // Lay cac diem (LatLng) tren tuyen cua xe de xe di theo.
  List<LatLng> _buildWaypoints(String routeId) {
    for (final route in sampleRoutes) {
      if (route.id == routeId) {
        return route.stops
            .map((s) => LatLng(s.latitude, s.longitude))
            .toList();
      }
    }
    return [];
  }

  // Mo phong xe di chuyen den tram tiep theo.
  void _updatePositions() {
    setState(() {
      for (final tracked in _trackedBuses) {
        if (tracked.waypoints.isEmpty) continue;

        final target = tracked.waypoints[tracked.targetIndex % tracked.waypoints.length];

        final dLat = target.latitude - tracked.position.latitude;
        final dLng = target.longitude - tracked.position.longitude;
        final distance = sqrt(dLat * dLat + dLng * dLng);

        // Moi lan cap nhat xe di duoc mot doan nho.
        const double step = 0.002;

        if (distance < step) {
          // Da den tram, chuyen sang tram tiep theo.
          tracked.position = target;
          tracked.targetIndex++;
        } else {
          // Di chuyen mot buoc ve phia tram.
          tracked.position = LatLng(
            tracked.position.latitude + dLat / distance * step,
            tracked.position.longitude + dLng / distance * step,
          );
        }
      }
    });
  }

  // Tao marker cho tung xe.
  List<Marker> _buildBusMarkers() {
    return _trackedBuses.map((tracked) {
      return Marker(
        point: tracked.position,
        width: 64,
        height: 70,
        child: GestureDetector(
          onTap: () => _showBusInfo(tracked),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.colors.error,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: context.colors.error,
                  size: 18,
                ),
              ),
              Text(
                tracked.info.busNumber,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: context.colors.error,
                  shadows: const [
                    Shadow(color: Colors.white, blurRadius: 3),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // Hien thong tin xe khi cham vao marker.
  void _showBusInfo(_TrackedBus tracked) {
    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: colors.error,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('bus_label', params: {
                        'number': tracked.info.busNumber,
                      }),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('status_active'),
                    style: TextStyle(fontSize: 13.5, color: colors.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.my_location,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${context.tr('position_label')} '
                    '${tracked.position.latitude.toStringAsFixed(5)}, '
                    '${tracked.position.longitude.toStringAsFixed(5)}',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                context.tr('simulated_note'),
                style: TextStyle(
                  color: colors.outline,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Di chuyen camera de nhin thay cac xe.
  void _fitToBuses() {
    if (_trackedBuses.isEmpty) return;

    if (_trackedBuses.length == 1) {
      _mapController.move(_trackedBuses.first.position, 14);
      return;
    }

    double minLat = _trackedBuses.first.position.latitude;
    double maxLat = _trackedBuses.first.position.latitude;
    double minLng = _trackedBuses.first.position.longitude;
    double maxLng = _trackedBuses.first.position.longitude;

    for (final tracked in _trackedBuses) {
      if (tracked.position.latitude < minLat) minLat = tracked.position.latitude;
      if (tracked.position.latitude > maxLat) maxLat = tracked.position.latitude;
      if (tracked.position.longitude < minLng) minLng = tracked.position.longitude;
      if (tracked.position.longitude > maxLng) maxLng = tracked.position.longitude;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        ),
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('tracking_title'))),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(10.7756, 106.6985),
              initialZoom: 12,
              onMapReady: _fitToBuses,
            ),
            children: [
              TileLayer(
                // Server tile Esri World Street Map (mien phi, khong can API key).
                // CartoDB basemaps gio bao loi "API KEY REQUIRED" khi khong co key.
                urlTemplate:
                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.example.busgo',
              ),
              MarkerLayer(markers: _buildBusMarkers()),

              // Ghi nguon ban do.
              const SimpleAttributionWidget(
                source: Text('Bản đồ © Esri — Dữ liệu © OpenStreetMap contributors'),
              ),
            ],
          ),

          // Bang thong bao du lieu mo phong o goc tren.
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('tracking_banner'),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Lop luu thong tin theo doi cua mot xe.
class _TrackedBus {
  final Bus info; // thong tin goc (bien so, trang thai)
  final List<LatLng> waypoints; // cac diem xe se di qua
  LatLng position; // vi tri hien tai
  int targetIndex = 0; // chi so tram tiep theo

  _TrackedBus({
    required this.info,
    required this.position,
    required this.waypoints,
  });
}