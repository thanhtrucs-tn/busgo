// map_screen.dart
// MÀN HÌNH BẢN ĐỒ BusGo.
//
// Chức năng (Phase 4):
//  - Nền bản đồ OpenStreetMap (cấu hình ở config/tile_config.dart) + attribution.
//  - Vị trí hiện tại của người dùng (GPS) + nút quay về vị trí.
//  - Danh sách tuyến lấy từ API, chọn tuyến để vẽ polyline (route_points).
//  - Marker các trạm của tuyến, chuyển chiều đi / chiều về.
//  - Bottom sheet thông tin tuyến và thông tin trạm.
//  - Trạng thái loading / lỗi / không có dữ liệu.
//
// LƯU Ý: marker xe buýt và cập nhật realtime sẽ làm ở Phase 5.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config/tile_config.dart';
import '../l10n/app_localizations.dart';
import '../models/bus.dart';
import '../models/bus_location.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../models/nearby_stop.dart';
import '../models/route_point.dart';
import '../models/route_stop.dart';
import '../models/stop_arrival.dart';
import '../models/user_location.dart';
import '../services/location_service.dart';
import '../services/socket_service.dart';
import '../services/transit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/error_state.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.initialRouteId, this.focusStop});

  // Tuyến cần chọn sẵn khi mở bản đồ (nếu có).
  final String? initialRouteId;

  // Trạm cần căn giữa khi mở bản đồ (dùng từ màn hình chi tiết trạm).
  final BusStop? focusStop;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // Vị trí hiện tại của người dùng.
  UserLocation? _currentLocation;
  bool _isLocating = false;

  // Trạng thái dữ liệu chung (tuyến + trạm).
  bool _loading = true;
  String? _error;
  List<BusRoute> _routes = const [];
  List<BusStop> _stops = const [];

  // Tuyến đang chọn + hình học của tuyến.
  BusRoute? _selectedRoute;
  int _direction = 0; // 0 = chiều đi, 1 = chiều về
  List<RouteStop> _routeStops = const [];
  List<RoutePoint> _routePath = const [];
  bool _routeLoading = false;

  // Từ khóa tìm tuyến.
  String _query = '';

  // Bản đồ đã sẵn sàng chưa (để chỉ di chuyển camera khi an toàn).
  bool _mapReady = false;

  // ------------------- Xe buýt realtime (Phase 5) -------------------
  // Vị trí mới nhất của mỗi xe thuộc tuyến đang chọn: { busId: Bus }.
  final Map<String, Bus> _buses = {};

  StreamSubscription<BusLocation>? _locationSub;
  StreamSubscription<BusStatusUpdate>? _statusSub;
  StreamSubscription<bool>? _connectionSub;

  // Tuyến đã tham gia phòng Socket.IO (để rời đúng phòng khi đổi/bỏ chọn).
  int? _joinedRouteId;

  // Trạng thái kết nối thời gian thực (hiện banner khi mất kết nối).
  bool _socketConnected = true;

  // ---- Trạm gần vị trí người dùng (Phase 6) ----
  List<NearbyStop> _nearbyStops = const [];
  bool _nearbyOnly = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    // Hủy listener và rời phòng Socket.IO để không rò rỉ / không trùng listener.
    _unsubscribeFromRoute();
    _connectionSub?.cancel();
    super.dispose();
  }

  // Tải danh sách tuyến và trạm từ API.
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final routes = await TransitService.instance.fetchRoutes();
      final stops = await TransitService.instance.fetchStops();
      if (!mounted) return;
      setState(() {
        _routes = routes;
        _stops = stops;
        _loading = false;
      });

      // Nếu được yêu cầu chọn sẵn một tuyến thì nạp luôn lộ trình.
      final initialId = widget.initialRouteId;
      if (initialId != null) {
        final match = routes.where((r) => r.id == initialId).toList();
        if (match.isNotEmpty) _selectRoute(match.first);
      }
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error =
            err is TransitException ? err.message : context.tr('load_error');
        _loading = false;
      });
    }
  }

  // Chọn một tuyến: nạp trạm + polyline + xe, và theo dõi realtime.
  Future<void> _selectRoute(BusRoute route) async {
    _unsubscribeFromRoute();

    setState(() {
      _selectedRoute = route;
      _direction = 0;
      _routeStops = const [];
      _routePath = const [];
      _buses.clear();
    });

    _subscribeToRoute(route.id);
    await _loadRouteGeometry();
    await _loadRouteBuses();
  }

  // Tải vị trí mới nhất của các xe thuộc tuyến.
  Future<void> _loadRouteBuses() async {
    final route = _selectedRoute;
    if (route == null) return;

    try {
      final buses = await TransitService.instance.fetchRouteBuses(route.id);
      if (!mounted || _selectedRoute?.id != route.id) return;
      setState(() {
        _buses.clear();
        for (final bus in buses) {
          _buses[bus.id] = bus;
        }
      });
    } catch (_) {
      // Không hiển thị lỗi riêng cho danh sách xe; lộ trình vẫn dùng được.
    }
  }

  // Theo dõi realtime cho một tuyến: nghe sự kiện và tham gia phòng.
  void _subscribeToRoute(String routeId) {
    final id = int.tryParse(routeId);
    if (id == null) return;

    _locationSub =
        SocketService.instance.locationUpdates.listen(_onBusLocation);
    _statusSub = SocketService.instance.statusUpdates.listen(_onBusStatus);
    _connectionSub ??=
        SocketService.instance.connectionUpdates.listen((connected) {
      if (mounted) setState(() => _socketConnected = connected);
    });

    _joinedRouteId = id;
    SocketService.instance.joinRoute(id);
  }

  // Hủy theo dõi tuyến hiện tại và rời phòng Socket.IO.
  void _unsubscribeFromRoute() {
    _locationSub?.cancel();
    _locationSub = null;
    _statusSub?.cancel();
    _statusSub = null;

    final id = _joinedRouteId;
    if (id != null) {
      SocketService.instance.leaveRoute(id);
      _joinedRouteId = null;
    }
    _buses.clear();
  }

  // Nhận vị trí xe mới từ Socket.IO (chỉ cập nhật marker, KHÔNG zoom lại).
  void _onBusLocation(BusLocation location) {
    final route = _selectedRoute;
    if (route == null || location.routeId != route.id) return;
    if (location.isStale()) return; // bỏ qua vị trí quá cũ

    final existing = _buses[location.busId];
    if (!mounted) return;
    setState(() {
      _buses[location.busId] =
          (existing ?? _busFromLocation(location)).copyWith(
        busNumber: location.busCode.isNotEmpty ? location.busCode : null,
        latitude: location.latitude,
        longitude: location.longitude,
        speed: location.speed,
        heading: location.heading,
        updatedAt: location.updatedAt,
      );
    });
  }

  // Nhận cập nhật trạng thái xe từ Socket.IO.
  void _onBusStatus(BusStatusUpdate update) {
    final route = _selectedRoute;
    if (route == null || update.routeId != route.id) return;

    final existing = _buses[update.busId];
    if (existing == null || !mounted) return;
    setState(() {
      _buses[update.busId] = existing.copyWith(status: update.status);
    });
  }

  // Tạo Bus tối thiểu từ payload vị trí (khi xe chưa có trong danh sách).
  Bus _busFromLocation(BusLocation location) {
    return Bus(
      id: location.busId,
      busNumber:
          location.busCode.isNotEmpty ? location.busCode : location.busId,
      routeId: location.routeId,
      latitude: location.latitude,
      longitude: location.longitude,
      status: 'RUNNING',
      speed: location.speed,
      heading: location.heading,
      updatedAt: location.updatedAt,
    );
  }

  // Đổi chiều đi / chiều về và nạp lại lộ trình.
  Future<void> _setDirection(int direction) async {
    if (direction == _direction) return;
    setState(() => _direction = direction);
    await _loadRouteGeometry();
  }

  // Nạp danh sách trạm và đường đi của tuyến đang chọn.
  Future<void> _loadRouteGeometry() async {
    final route = _selectedRoute;
    if (route == null) return;

    setState(() => _routeLoading = true);

    try {
      final stops = await TransitService.instance.fetchRouteStops(
        route.id,
        direction: _direction,
      );
      final path = await TransitService.instance.fetchRoutePath(
        route.id,
        direction: _direction,
      );
      if (!mounted) return;
      setState(() {
        _routeStops = stops;
        _routePath = path;
        _routeLoading = false;
      });
      _fitRouteOnMap();
    } catch (err) {
      if (!mounted) return;
      setState(() => _routeLoading = false);
      _showMessage(
        err is TransitException ? err.message : context.tr('load_error'),
      );
    }
  }

  // Bỏ chọn tuyến, quay về danh sách tuyến.
  void _clearRoute() {
    _unsubscribeFromRoute();
    setState(() {
      _selectedRoute = null;
      _direction = 0;
      _routeStops = const [];
      _routePath = const [];
      _buses.clear();
    });
  }

  // Căn camera bao trọn lộ trình / các trạm của tuyến (chỉ khi đã sẵn sàng).
  void _fitRouteOnMap() {
    if (!_mapReady) return;

    final points = <LatLng>[
      for (final p in _routePath) LatLng(p.latitude, p.longitude),
      for (final rs in _routeStops)
        LatLng(rs.stop.latitude, rs.stop.longitude),
    ];
    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController.move(points.first, 15);
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
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

  // Căn camera bao trọn toàn bộ trạm (lần đầu mở bản đồ).
  void _fitAllStops() {
    if (!_mapReady || _stops.isEmpty) return;

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

  // Khi bản đồ sẵn sàng: căn camera theo trạm focus / tuyến / toàn bộ trạm.
  void _onMapReady() {
    _mapReady = true;

    final focus = widget.focusStop;
    if (focus != null) {
      _mapController.move(LatLng(focus.latitude, focus.longitude), 16);
      return;
    }
    if (_selectedRoute != null) {
      _fitRouteOnMap();
      return;
    }
    if (widget.initialRouteId == null) _fitAllStops();
    _fitRouteOnMap();
  }

  // GPS: lấy vị trí hiện tại và di chuyển camera tới đó.
  Future<void> _locateMe() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    final result = await LocationService.instance.getCurrentLocation();
    if (!mounted) return;
    setState(() => _isLocating = false);

    if (result.success && result.location != null) {
      final loc = result.location!;
      setState(() => _currentLocation = loc);
      if (_mapReady) {
        _mapController.move(LatLng(loc.latitude, loc.longitude), 16);
      }
    } else {
      _showMessage(result.error ?? context.tr('location_error'));
    }
  }

  // Bật/tắt chế độ chỉ hiển thị TRẠM GẦN NHẤT (gọi API /stops/nearby).
  Future<void> _toggleNearby() async {
    // Đang bật -> tắt và hiển thị lại toàn bộ trạm.
    if (_nearbyOnly) {
      setState(() {
        _nearbyOnly = false;
        _nearbyStops = const [];
      });
      return;
    }

    final result = await LocationService.instance.getCurrentLocation();
    if (!mounted) return;

    if (!result.success || result.location == null) {
      _showMessage(result.error ?? context.tr('location_error'));
      return;
    }

    final loc = result.location!;
    setState(() => _currentLocation = loc);

    try {
      final nearby = await TransitService.instance.fetchNearbyStops(
        loc.latitude,
        loc.longitude,
        radius: 3000,
      );
      if (!mounted) return;
      setState(() {
        _nearbyStops = nearby;
        _nearbyOnly = true;
      });

      if (nearby.isEmpty) {
        _showMessage(context.tr('map_no_data'));
        return;
      }
      _showNearbySheet(nearby);
    } catch (err) {
      if (!mounted) return;
      _showMessage(
        err is TransitException ? err.message : context.tr('load_error'),
      );
    }
  }

  // Bottom sheet danh sách trạm gần người dùng (kèm khoảng cách).
  void _showNearbySheet(List<NearbyStop> nearby) {
    final colors = context.colors;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('nearby_only'),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final item in nearby)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.place,
                            color: colors.error,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          item.stop.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(item.stop.address),
                        trailing: Text(
                          item.distanceText,
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hiện thông tin trạm khi chạm marker (kèm danh sách xe đang đến).
  void _showStopInfo(BusStop stop) {
    final colors = context.colors;

    // Khoảng cách từ người dùng đến trạm (nếu đã biết vị trí).
    int? distanceMeters;
    if (_currentLocation != null) {
      distanceMeters = (LocationService.distanceKm(
                _currentLocation!,
                UserLocation(
                  latitude: stop.latitude,
                  longitude: stop.longitude,
                ),
              ) *
              1000)
          .round();
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _StopInfoSheet(
        stop: stop,
        distanceMeters: distanceMeters,
      ),
    );
  }

  // Thông báo nhanh ở đáy màn hình.
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Danh sách trạm hiển thị trên bản đồ (lọc theo chế độ "trạm gần nhất").
  List<BusStop> get _visibleStops =>
      _nearbyOnly ? _nearbyStops.map((item) => item.stop).toList() : _stops;

  List<BusRoute> get _filteredRoutes {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _routes;
    return _routes.where((r) {
      return r.routeNumber.toLowerCase().contains(query) ||
          r.name.toLowerCase().contains(query) ||
          r.startPoint.toLowerCase().contains(query) ||
          r.endPoint.toLowerCase().contains(query);
    }).toList();
  }

  // Marker các trạm: nếu đang chọn tuyến thì chỉ hiện trạm của tuyến đó.
  List<Marker> _buildStopMarkers() {
    final colors = context.colors;

    if (_selectedRoute == null) {
      return [
        for (final stop in _visibleStops)
          Marker(
            point: LatLng(stop.latitude, stop.longitude),
            width: 34,
            height: 34,
            child: GestureDetector(
              onTap: () => _showStopInfo(stop),
              child: Icon(
                Icons.location_pin,
                color: colors.error,
                size: 30,
              ),
            ),
          ),
      ];
    }

    return [
      for (int i = 0; i < _routeStops.length; i++)
        Marker(
          point: LatLng(
            _routeStops[i].stop.latitude,
            _routeStops[i].stop.longitude,
          ),
          width: 38,
          height: 38,
          child: GestureDetector(
            onTap: () => _showStopInfo(_routeStops[i].stop),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
    ];
  }

  // Marker vị trí người dùng (chấm xanh).
  List<Marker> _buildUserMarkers() {
    if (_currentLocation == null) return [];
    return [
      Marker(
        point: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
        width: 40,
        height: 40,
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

  // Marker xe buýt của tuyến đang chọn (vị trí mới nhất mỗi xe).
  List<Marker> _buildBusMarkers() {
    if (_selectedRoute == null) return [];
    final colors = context.colors;

    return [
      for (final bus in _buses.values)
        if (bus.hasLocation)
          Marker(
            point: LatLng(bus.latitude, bus.longitude),
            width: 72,
            height: 60,
            child: GestureDetector(
              onTap: () => _showBusInfo(bus),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  Text(
                    bus.busNumber,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: colors.error,
                      shadows: const [
                        Shadow(color: Colors.white, blurRadius: 3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    ];
  }

  // Thông tin xe khi chạm marker (bottom sheet tạm thời).
  void _showBusInfo(Bus bus) {
    final colors = context.colors;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.error,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        bus.busNumber,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (bus.speed != null)
                  Text(
                    'Tốc độ: ${bus.speed!.toStringAsFixed(0)} km/h',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Vị trí: ${bus.latitude.toStringAsFixed(5)}, '
                  '${bus.longitude.toStringAsFixed(5)}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
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
          ),
        );
      },
    );
  }

  // Polyline lộ trình của tuyến đang chọn.
  List<Polyline> _buildPolylines() {
    if (_routePath.length < 2) return [];
    final color = _parseColor(_selectedRoute?.color) ?? context.colors.primary;
    return [
      Polyline(
        points: [for (final p in _routePath) LatLng(p.latitude, p.longitude)],
        strokeWidth: 5,
        color: color,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ---------------------------- BẢN ĐỒ ----------------------------
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(10.7756, 106.6985),
              initialZoom: 13,
              onMapReady: _onMapReady,
            ),
            children: [
              TileLayer(
                urlTemplate: TileConfig.current.urlTemplate,
                userAgentPackageName: TileConfig.current.userAgentPackageName,
              ),
              // Attribution đặt ở góc trên bên phải để không bị bottom sheet che.
              SimpleAttributionWidget(
                source: Text(TileConfig.current.attribution),
                alignment: Alignment.topRight,
              ),
              PolylineLayer(polylines: _buildPolylines()),
              MarkerLayer(
                markers: [..._buildStopMarkers(), ..._buildUserMarkers()],
              ),
              // Marker xe buýt vẽ trên cùng để luôn nổi bật.
              MarkerLayer(markers: _buildBusMarkers()),
            ],
          ),

          // --------------------- NÚT ZOOM + VỊ TRÍ ---------------------
          Positioned(
            right: 12,
            bottom: 250,
            child: Column(
              children: [
                _RoundButton(
                  icon: Icons.add,
                  onTap: () {
                    final camera = _mapController.camera;
                    _mapController.move(camera.center, camera.zoom + 1);
                  },
                ),
                const SizedBox(height: 8),
                _RoundButton(
                  icon: Icons.remove,
                  onTap: () {
                    final camera = _mapController.camera;
                    _mapController.move(camera.center, camera.zoom - 1);
                  },
                ),
                const SizedBox(height: 8),
                _RoundButton(
                  icon: Icons.my_location,
                  busy: _isLocating,
                  onTap: _locateMe,
                ),
                const SizedBox(height: 8),
                _RoundButton(
                  icon: _nearbyOnly ? Icons.near_me_disabled : Icons.near_me,
                  onTap: _toggleNearby,
                ),
              ],
            ),
          ),

          // ------------------------ THANH TÌM KIẾM ------------------------
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 28, left: 12, right: 12),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    _RoundButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  if (Navigator.of(context).canPop()) const SizedBox(width: 8),
                  Expanded(
                    child: Material(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      elevation: 2,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: context.tr('map_search_hint'),
                          prefixIcon: const Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => setState(() => _query = ''),
                                ),
                        ),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Banner mất kết nối thời gian thực (chỉ hiện khi đang theo tuyến).
          if (_selectedRoute != null && !_socketConnected)
            Positioned(
              top: 84,
              left: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: context.colors.error.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('socket_disconnected'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Trạng thái loading / lỗi.
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ErrorState(message: _error!, onRetry: _loadData),
                ),
              ),
            ),

          // ------------------------- BOTTOM SHEET -------------------------
          if (!_loading && _error == null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _buildBottomPanel(),
            ),
        ],
      ),
    );
  }

  // Bảng dưới cùng: danh sách tuyến hoặc thông tin tuyến đang chọn.
  Widget _buildBottomPanel() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.42,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: _selectedRoute == null
              ? _buildRouteListPanel()
              : _buildRouteInfoPanel(_selectedRoute!),
        ),
      ),
    );
  }

  // Danh sách tuyến để người dùng chọn.
  Widget _buildRouteListPanel() {
    final colors = context.colors;
    final routes = _filteredRoutes;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.directions_bus, size: 18, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              context.tr('map_routes'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              context.tr('routes_active', params: {'count': '${routes.length}'}),
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (routes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              context.tr('map_no_routes'),
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: routes.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: colors.outlineVariant,
              ),
              itemBuilder: (context, index) {
                final route = routes[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _RouteBadge(number: route.routeNumber),
                  title: Text(
                    route.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    context.tr('stops_count', params: {
                      'count': '${route.displayStopCount}',
                    }),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectRoute(route),
                );
              },
            ),
          ),
      ],
    );
  }

  // Thông tin tuyến đang chọn + chuyển chiều + danh sách trạm.
  Widget _buildRouteInfoPanel(BusRoute route) {
    final colors = context.colors;
    final color = _parseColor(route.color) ?? colors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _RouteBadge(number: route.routeNumber, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${route.startPoint} → ${route.endPoint}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: context.tr('close'),
              icon: const Icon(Icons.close),
              onPressed: _clearRoute,
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Thông tin giờ hoạt động + giá vé.
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            if (route.operatingTime.isNotEmpty)
              _Chip(
                icon: Icons.schedule,
                text: route.operatingTime,
              ),
            if (route.fare != null)
              _Chip(
                icon: Icons.payments_outlined,
                text:
                    '${context.tr('fare')}: ${route.fare!.toStringAsFixed(0)} đ',
              ),
            _Chip(
              icon: Icons.directions_bus,
              text: context.tr('active_buses_count', params: {
                'count': '${_buses.length}',
              }),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Chuyển chiều đi / chiều về.
        SegmentedButton<int>(
          segments: [
            ButtonSegment(
              value: 0,
              label: Text(context.tr('direction_outbound')),
              icon: const Icon(Icons.arrow_forward, size: 16),
            ),
            ButtonSegment(
              value: 1,
              label: Text(context.tr('direction_inbound')),
              icon: const Icon(Icons.arrow_back, size: 16),
            ),
          ],
          selected: {_direction},
          onSelectionChanged: (values) => _setDirection(values.first),
          showSelectedIcon: false,
        ),
        const SizedBox(height: 10),

        // Danh sách trạm của tuyến.
        Row(
          children: [
            Text(
              context.tr('route_stops'),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const Spacer(),
            if (_routeLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                context.tr('stops_count', params: {
                  'count': '${_routeStops.length}',
                }),
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Flexible(child: _buildRouteStopsList()),
      ],
    );
  }

  // Danh sách trạm của tuyến (cuộn được).
  Widget _buildRouteStopsList() {
    final colors = context.colors;

    if (_routeLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_routePath.isEmpty && _routeStops.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          context.tr('map_no_path'),
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _routeStops.length,
      itemBuilder: (context, index) {
        final rs = _routeStops[index];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 12,
            backgroundColor: colors.primary,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Text(
            rs.stop.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5),
          ),
          subtitle: rs.stop.address.isEmpty
              ? null
              : Text(
                  rs.stop.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5),
                ),
          onTap: () => _showStopInfo(rs.stop),
        );
      },
    );
  }

  // Đổi mã màu "#RRGGBB" từ backend thành Color.
  Color? _parseColor(String? value) {
    if (value == null) return null;
    final hex = value.replaceFirst('#', '');
    if (hex.length != 6) return null;
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? null : Color(0xFF000000 | parsed);
  }
}

// Nút tròn nhỏ trên bản đồ (zoom, vị trí, gần đây).
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: busy ? null : onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(11),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, size: 20, color: colors.primary),
        ),
      ),
    );
  }
}

// Nhãn số tuyến.
class _RouteBadge extends StatelessWidget {
  const _RouteBadge({required this.number, this.color});

  final String number;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ?? colors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        number,
        style: TextStyle(
          color: colors.onPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// Chip nhỏ hiển thị icon + text (giờ hoạt động, giá vé...).
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

// Bottom sheet thông tin trạm: địa chỉ, khoảng cách, các tuyến và
// danh sách XE ĐANG ĐẾN (kèm thời gian dự kiến, gọi API khi mở).
class _StopInfoSheet extends StatefulWidget {
  const _StopInfoSheet({required this.stop, this.distanceMeters});

  final BusStop stop;
  final int? distanceMeters;

  @override
  State<_StopInfoSheet> createState() => _StopInfoSheetState();
}

class _StopInfoSheetState extends State<_StopInfoSheet> {
  late final Future<List<StopArrival>> _arrivalsFuture;

  @override
  void initState() {
    super.initState();
    _arrivalsFuture =
        TransitService.instance.fetchStopArrivals(widget.stop.id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final stop = widget.stop;

    return SafeArea(
      child: Padding(
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
                  child: Icon(Icons.place, color: colors.error, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    stop.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (stop.address.isNotEmpty)
              Text(
                stop.address,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 13.5,
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.directions_bus, size: 15, color: colors.primary),
                const SizedBox(width: 5),
                Text(
                  context.tr('routes_passing', params: {
                    'count': '${stop.routeCount}',
                  }),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
                if (widget.distanceMeters != null) ...[
                  const SizedBox(width: 14),
                  Icon(
                    Icons.near_me,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.tr('distance_from_you', params: {
                      'distance': '${widget.distanceMeters} m',
                    }),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: colors.outlineVariant),
            const SizedBox(height: 10),
            Text(
              context.tr('arrivals_title'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            FutureBuilder<List<StopArrival>>(
              future: _arrivalsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(10),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                final arrivals = snapshot.data ?? const <StopArrival>[];
                if (arrivals.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      context.tr('arrival_none'),
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final arrival in arrivals.take(3))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.directions_bus,
                              size: 16,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${arrival.busCode} · ${arrival.routeName ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              context.tr('arrival_eta', params: {
                                'minutes': '${arrival.estimatedMinutes}',
                              }),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (arrivals.any((item) => item.isSimulated))
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            context.tr('data_simulated'),
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
