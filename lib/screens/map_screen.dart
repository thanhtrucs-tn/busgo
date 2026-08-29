// map_screen.dart
// Man hinh ban do dung thu vien flutter_map + latlong2 (chay tren Windows, Android, Web...).
// - Nen ban do: TileLayer tai tile tu Esri World Street Map (mien phi, khong can API key).
// - Overlays: Marker tai cac tram dung va Polyline noi lo trinh giua cac tram.
// - Lo trinh bam theo duong giao thong that: goi API OSRM (dinh tuyen mien phi)
//   de lay toa do duong di giua tung cap tram; neu loi mang thi noi thang.
// - Tu dong camera: tinh vung bao (LatLngBounds) tu danh sach tram,
//   goi MapController.fitCamera() de zoom bao tron toan bo tram khi mo ban do.
// - Kiem tra loi khi khong co du lieu toa do.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

// ========================== DU LIEU MAU ==========================

// Mot tram dung don gian, chi giu cac thong tin can thiet cho ban do.
class MapStop {
  final String name;
  final double latitude;
  final double longitude;

  const MapStop({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

// Danh sach tram dung mau (5 tram tai TP.HCM).
// Duoc dung khi nguoi dung khong truyen danh sach tram rieng vao MapScreen.
const List<MapStop> sampleStops = [
  MapStop(name: 'Bến Thành', latitude: 10.7756, longitude: 106.6985),
  MapStop(name: 'Nhà thờ Đức Bà', latitude: 10.7798, longitude: 106.6992),
  MapStop(name: 'Bưu điện TP.HCM', latitude: 10.7796, longitude: 106.7001),
  MapStop(name: 'Chợ Lớn', latitude: 10.7489, longitude: 106.6500),
  MapStop(name: 'Sân bay Tân Sơn Nhất', latitude: 10.8188, longitude: 106.6523),
];

// ========================== MAN HINH BAN DO ==========================

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.stops});

  // Danh sach tram can hien thi (tu man hinh khac truyen sang).
  // Neu null thi dung sampleStops (du lieu mau) ben tren.
  final List<MapStop>? stops;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

// StatefulWidget vi can giu MapController de dieu chinh camera (zoom, di chuyen).
class _MapScreenState extends State<MapScreen> {
  // Dung de dieu khien camera cua ban do.
  final MapController _mapController = MapController();

  // Lay danh sach tram se ve: uu tien du lieu truyen vao, nguoc lai dung du lieu mau.
  List<MapStop> get _stops => widget.stops ?? sampleStops;

  // Duong lo trinh that su theo mang luoi giao thong (lay tu OSRM).
  // null = chua tai xong hoac loi mang -> van dung cach noi thang cu.
  List<LatLng>? _roadRoute;

  @override
  void initState() {
    super.initState();
    _loadRoadRoute();
  }

  // Goi OSRM (dich vu dinh tuyen mien phi, khong can API key) de lay duong di
  // thuc te giua cac tram, thay vi noi thang bang duong chim.
  Future<void> _loadRoadRoute() async {
    final stops = _stops;
    if (stops.length < 2) return;

    final merged = <LatLng>[];
    for (var i = 0; i < stops.length - 1; i++) {
      final segment = await _fetchRoadSegment(stops[i], stops[i + 1]);
      if (segment != null && segment.length >= 2) {
        // Noi cac doan lai voi nhau, bo diem giong nhau tai tram dung chung.
        if (merged.isNotEmpty) segment.removeAt(0);
        merged.addAll(segment);
      } else {
        // Loi mang hoac khong tim thay duong => noi thang cho doan nay.
        merged.add(LatLng(stops[i].latitude, stops[i].longitude));
        merged.add(LatLng(stops[i + 1].latitude, stops[i + 1].longitude));
      }
    }

    if (!mounted) return;
    setState(() => _roadRoute = merged);
  }

  // Lay duong di (danh sach diem LatLng) giua 2 tram tu API OSRM.
  // Tra ve null neu loi mang / timeout / khong co tuyen duong.
  Future<List<LatLng>?> _fetchRoadSegment(MapStop from, MapStop to) async {
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}',
      ).replace(queryParameters: {
        'overview': 'full',
        'geometries': 'polyline6',
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = data['routes'] as List;
      if (routes.isEmpty) return null;

      final geometry =
          (routes.first as Map<String, dynamic>)['geometry'] as String;
      // Giai ma chuoi polyline6 thanh toa do [lat, lng] va chuyen sang LatLng.
      final coords = decodePolyline(geometry, accuracyExponent: 6);
      final points = coords.map((c) => LatLng(c[0].toDouble(), c[1].toDouble())).toList();
      if (points.length < 2) return null;

      // Gan diem dau/cuoi ve dung toa do tram de duong noi khep kin voi marker.
      points[0] = LatLng(from.latitude, from.longitude);
      points[points.length - 1] = LatLng(to.latitude, to.longitude);
      return points;
    } catch (_) {
      // Bat loi timeout / JSON sai dinh dang... de lui ve cach noi thang.
      return null;
    }
  }

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
          child: Icon(Icons.location_pin, color: context.colors.error, size: 36),
        ),
      );
    }).toList();
  }

  // Tao duong noi (lo trinh) di qua cac tram theo thu tu.
  // Uu tien lo trinh bam theo duong giao thong that (OSRM),
  // neu chua tai xong hoac loi mang thi noi thang giua cac tram.
  List<Polyline> _buildPolylines() {
    final points =
        _roadRoute ??
        _stops.map((s) => LatLng(s.latitude, s.longitude)).toList();

    // Can it nhat 2 diem moi ve duoc duong thang.
    if (points.length < 2) return [];

    return [
      Polyline(points: points, strokeWidth: 4, color: context.colors.primary),
    ];
  }

  // Tinh vung bao (LatLngBounds) tu danh sach tram va zoom camera bao tron toan bo.
  void _fitBounds() {
    // Kiem tra du lieu: khong co tram thi thoi (khong crash).
    if (_stops.isEmpty) return;

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

    // Neu chi co 1 tram thi chi can di chuyen camera den tram do (zoom co dinh).
    if (_stops.length == 1) {
      _mapController.move(
        LatLng(minLat, minLng),
        15,
      );
      return;
    }

    // fitCamera: zoom ve vung chua toan bo cac tram.
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat, minLng), // goc Tay Nam (southwest)
          LatLng(maxLat, maxLng), // goc Dong Bac (northeast)
        ),
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  // Hien thong tin tram khi nguoi dung cham vao marker.
  void _showStopInfo(MapStop stop) {
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
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.place,
                      color: colors.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      stop.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${stop.latitude}, ${stop.longitude}',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kiem tra loi: neu khong co du lieu toa do thi hien thong bao thay vi ban do rong.
    if (_stops.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('map_title'))),
        body: EmptyState(
          icon: Icons.map_outlined,
          message: context.tr('map_no_data'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('map_title'))),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          // Vi tri camera ban dau (trung tam TP.HCM).
          // Sau khi map san sang (onMapReady) se tu dong zoom vaoooo vung cac tram.
          initialCenter: const LatLng(10.7756, 106.6985),
          initialZoom: 13,
          onMapReady: _fitBounds,
        ),
        children: [
          TileLayer(
            // Nen ban do dung Esri World Street Map (mien phi, khong can API key).
            // CartoDB basemaps gio bao loi "API KEY REQUIRED" khi khong co key,
            // con tile.openstreetmap.org bi loi DNS (errno 11001) tren mang nay.
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
            // User-Agent de server tile nhan dien app (khong bi chan).
            userAgentPackageName: 'com.example.busgo',
          ),
          // Ghi nguon ban do.
          const SimpleAttributionWidget(
            source:
                Text('Bản đồ © Esri — Dữ liệu © OpenStreetMap contributors'),
          ),
          // Lop marker cac tram.
          MarkerLayer(markers: _buildMarkers()),
          // Lop duong lo trinh noi cac tram.
          PolylineLayer(polylines: _buildPolylines()),
        ],
      ),
    );
  }
}