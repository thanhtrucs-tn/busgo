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
import '../models/user_location.dart';
import '../services/location_service.dart';
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
  // Dung để điều khiển camera của bản đồ.
  final MapController _mapController = MapController();

  // Lay danh sach tram se ve: uu tien du lieu truyen vao, nguoc lai dung du lieu mau.
  List<MapStop> get _stops => widget.stops ?? sampleStops;

  // Duong lo trinh that su theo mang luoi giao thong (lay tu OSRM).
  // null = chua tai xong hoac loi mang -> van dung cach noi thang cu.
  List<LatLng>? _roadRoute;

  // Vi tri hien tai cua nguoi dung (null = chua lay duoc / chua bam nut).
  UserLocation? _currentLocation;

  // Dang lay vi tri GPS hay khong (hien vong xoay tren nut).
  bool _isLocating = false;

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

  // ------------------------------------------------------------
  // GPS: LẤY VỊ TRÍ HIỆN TẠI CỦA NGƯỜI DÙNG.
  // Quy trình (theo yêu cầu):
  //   Bấm nút "Vị trí hiện tại"
  //   -> Kiểm tra GPS bật chưa
  //   -> Kiểm tra / xin quyền vị trí
  //   -> Lấy latitude + longitude
  //   -> Hiển thị marker "Vị trí của bạn" + di chuyển camera đến đó.
  // Mọi lỗi đều hiện thông báo tiếng Việt, KHÔNG crash app.
  // ------------------------------------------------------------
  Future<void> _locateMe() async {
    // Chống bấm nhiều lần khi đang xử lý.
    if (_isLocating) return;
    setState(() => _isLocating = true);

    // Gọi service GPS tập trung (xin quyền + lấy tọa độ).
    final result = await LocationService.instance.getCurrentLocation();

    // Bảo vệ: kiểm tra lại sau await.
    if (!mounted) return;
    setState(() => _isLocating = false);

    if (result.success && result.location != null) {
      final loc = result.location!;
      setState(() => _currentLocation = loc);

      // Di chuyển camera đến vị trí người dùng (zoom 16 để thấy rõ).
      _mapController.move(LatLng(loc.latitude, loc.longitude), 16);
    } else {
      // Lỗi -> hiện thông báo thân thiện, ví dụ:
      // "Vui lòng bật định vị (GPS) để sử dụng chức năng này".
      await _showLocationError(result.error ?? 'Không lấy được vị trí');
    }
  }

  // Hiện thông báo lỗi GPS.
  // Nếu quyền bị từ chối VĨNH VIỄN -> hiện thêm nút "Mở Cài đặt" để
  // người dùng tự cấp lại quyền trong Settings của hệ thống.
  Future<void> _showLocationError(String message) async {
    final bool deniedForever = message.contains('vĩnh viễn');

    if (!deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    // Từ chối vĩnh viễn: cần mở Settings hệ thống.
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quyền vị trí'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Mở Cài đặt'),
          ),
        ],
      ),
    );

    if (openSettings == true) {
      // Mở trang Cài đặt của hệ thống để cấp lại quyền.
      await LocationService.openAppSettings();
    }
  }

  // ------------------------------------------------------------
  // TÌM TRẠM GẦN NHẤT: sử dụng GPS + công thức Haversine.
  // Vị trí chỉ dùng cục bộ (GPS -> Flutter -> Map), KHÔNG gửi lên server.
  // Kết quả: hiện danh sách trạm gần nhất kèm khoảng cách (km).
  // ------------------------------------------------------------
  Future<void> _showNearbyStops() async {
    // Bước 1: lấy vị trí hiện tại.
    final result = await LocationService.instance.getCurrentLocation();
    if (!mounted) return;

    if (!result.success || result.location == null) {
      await _showLocationError(result.error ?? 'Không lấy được vị trí');
      return;
    }

    final loc = result.location!;
    final colors = context.colors;

    // Bước 2: tính khoảng cách từ người dùng đến từng trạm,
    // sắp xếp tăng dần, lấy 3 trạm gần nhất.
    final sorted = [..._stops].map((stop) {
      final distance = LocationService.distanceKm(
        loc,
        UserLocation(
          latitude: stop.latitude,
          longitude: stop.longitude,
        ),
      );
      return (stop: stop, distance: distance);
    }).toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));

    final nearest = sorted.take(3).toList();

    // Bước 3: hiện bottom sheet danh sách trạm gần.
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trạm gần bạn nhất',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}',
                style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              for (final item in nearest)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.place, color: colors.error, size: 22),
                  ),
                  title: Text(
                    item.stop.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${item.stop.latitude.toStringAsFixed(4)}, '
                    '${item.stop.longitude.toStringAsFixed(4)}',
                  ),
                  trailing: Text(
                    // Ví dụ: "0.8 km" - làm tròn 1 chữ số thập phân.
                    '${item.distance.toStringAsFixed(1)} km',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Marker "Vị trí của bạn" (chấm xanh nổi bật trên bản đồ).
  List<Marker> _buildUserMarkers() {
    if (_currentLocation == null) return [];
    return [
      Marker(
        point: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
        width: 40,
        height: 40,
        // Chấm xanh dương truyền thống kiểu "vị trí của tôi".
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.fromBorderSide(
                BorderSide(color: Colors.white, width: 3),
              ),
            ),
            child: const Icon(Icons.my_location, size: 10, color: Colors.white),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Mau lay tu theme de giao dien hien thi dung che do sang/toi.
    final colors = context.colors;

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
          // Lop marker cac tram + marker "Vị trí của bạn".
          MarkerLayer(markers: [..._buildMarkers(), ..._buildUserMarkers()]),
          // Lop duong lo trinh noi cac tram.
          PolylineLayer(polylines: _buildPolylines()),
        ],
      ),
      // Nhom nut GPS o goc duoi phai:
      //  1. "VỊ TRÍ HIỆN TẠI" - lay GPS + di chuyen camera
      //  2. "Tram gan toi"     - GPS + tinh khoang cach den tram gan nhat
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Nút "Vị trí hiện tại" (theo yêu cầu).
          FloatingActionButton.extended(
            heroTag: 'locate_me',
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            onPressed: _isLocating ? null : _locateMe,
            icon: _isLocating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.my_location),
            label: const Text('Vị trí hiện tại'),
          ),
          const SizedBox(height: 10),
          // Nút phụ "Trạm gần tôi" (GPS + Haversine, không cần server).
          FloatingActionButton.small(
            heroTag: 'nearby_stops',
            backgroundColor: colors.surface,
            foregroundColor: colors.primary,
            tooltip: 'Trạm gần tôi',
            onPressed: _showNearbyStops,
            child: const Icon(Icons.near_me),
          ),
        ],
      ),
    );
  }
}