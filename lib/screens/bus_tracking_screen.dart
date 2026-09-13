// bus_tracking_screen.dart
// Màn hình THEO DÕI XE BUÝT theo thời gian thực.
// - Vị trí ban đầu: lấy từ API GET /api/routes/:routeId/buses.
// - Cập nhật tiếp theo: nhận qua Socket.IO (sự kiện bus:location-updated).
// - Dữ liệu hiện do bộ mô phỏng GPS (tools/gps-simulator) tạo ra, không phải
//   GPS thật của xe.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config/tile_config.dart';
import '../l10n/app_localizations.dart';
import '../models/bus.dart';
import '../models/bus_location.dart';
import '../services/socket_service.dart';
import '../services/transit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/error_state.dart';

class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({super.key});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  final MapController _mapController = MapController();

  bool _loading = true;
  String? _error;

  // Vị trí mới nhất của mỗi xe: { busId: Bus }.
  final Map<String, Bus> _buses = {};

  // Các tuyến đã tham gia phòng Socket.IO (để rời đúng khi thoát).
  final Set<int> _joinedRoutes = {};

  StreamSubscription<BusLocation>? _locationSub;
  StreamSubscription<BusStatusUpdate>? _statusSub;
  StreamSubscription<bool>? _connectionSub;

  bool _connected = true;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    // Hủy listener + rời mọi phòng Socket.IO để không rò rỉ.
    _locationSub?.cancel();
    _statusSub?.cancel();
    _connectionSub?.cancel();
    for (final id in _joinedRoutes) {
      SocketService.instance.leaveRoute(id);
    }
    _joinedRoutes.clear();
    super.dispose();
  }

  // Tải tuyến + xe ban đầu rồi bắt đầu theo dõi realtime.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final routes = await TransitService.instance.fetchRoutes();
      final buses = <String, Bus>{};
      for (final route in routes) {
        final routeBuses = await TransitService.instance.fetchRouteBuses(
          route.id,
        );
        for (final bus in routeBuses) {
          buses[bus.id] = bus;
        }
      }
      if (!mounted) return;

      setState(() {
        _buses
          ..clear()
          ..addAll(buses);
        _loading = false;
      });

      _subscribe();
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err is TransitException
            ? err.message
            : context.tr('load_error');
        _loading = false;
      });
    }
  }

  // Đăng ký nghe sự kiện realtime và tham gia phòng của mọi tuyến.
  void _subscribe() {
    _locationSub = SocketService.instance.locationUpdates.listen(
      _onBusLocation,
    );
    _statusSub = SocketService.instance.statusUpdates.listen(_onBusStatus);
    _connectionSub ??= SocketService.instance.connectionUpdates.listen((
      connected,
    ) {
      if (mounted) setState(() => _connected = connected);
    });

    for (final route in _routesOfBuses()) {
      final id = int.tryParse(route);
      if (id != null && _joinedRoutes.add(id)) {
        SocketService.instance.joinRoute(id);
      }
    }
  }

  // Danh sách routeId hiện có xe (để tham gia phòng).
  Set<String> _routesOfBuses() {
    return _buses.values.map((bus) => bus.routeId).toSet();
  }

  void _onBusLocation(BusLocation location) {
    if (location.isStale()) return;

    final existing = _buses[location.busId];
    if (!mounted) return;
    setState(() {
      _buses[location.busId] = (existing ?? _busFromLocation(location))
          .copyWith(
            busNumber: location.busCode.isNotEmpty ? location.busCode : null,
            latitude: location.latitude,
            longitude: location.longitude,
            speed: location.speed,
            heading: location.heading,
            updatedAt: location.updatedAt,
          );
    });
  }

  void _onBusStatus(BusStatusUpdate update) {
    final existing = _buses[update.busId];
    if (existing == null || !mounted) return;
    setState(() {
      _buses[update.busId] = existing.copyWith(status: update.status);
    });
  }

  Bus _busFromLocation(BusLocation location) {
    return Bus(
      id: location.busId,
      busNumber: location.busCode.isNotEmpty
          ? location.busCode
          : location.busId,
      routeId: location.routeId,
      latitude: location.latitude,
      longitude: location.longitude,
      status: 'RUNNING',
      speed: location.speed,
      heading: location.heading,
      updatedAt: location.updatedAt,
    );
  }

  // Căn camera bao trọn các xe (chỉ gọi khi cần, không gọi mỗi lần xe chạy).
  void _fitToBuses() {
    if (!_mapReady) return;

    final buses = _buses.values.where((b) => b.hasLocation).toList();
    if (buses.isEmpty) return;

    if (buses.length == 1) {
      _mapController.move(
        LatLng(buses.first.latitude, buses.first.longitude),
        14,
      );
      return;
    }

    double minLat = buses.first.latitude;
    double maxLat = buses.first.latitude;
    double minLng = buses.first.longitude;
    double maxLng = buses.first.longitude;
    for (final bus in buses) {
      if (bus.latitude < minLat) minLat = bus.latitude;
      if (bus.latitude > maxLat) maxLat = bus.latitude;
      if (bus.longitude < minLng) minLng = bus.longitude;
      if (bus.longitude > maxLng) maxLng = bus.longitude;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
        padding: const EdgeInsets.all(70),
      ),
    );
  }

  List<Marker> _buildBusMarkers() {
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.error, width: 2),
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
                      color: colors.error,
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
                        context.tr(
                          'bus_label',
                          params: {'number': bus.busNumber},
                        ),
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
                    Icon(Icons.check_circle, size: 16, color: colors.primary),
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
                      '${bus.latitude.toStringAsFixed(5)}, '
                      '${bus.longitude.toStringAsFixed(5)}',
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('tracking_title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(10.7756, 106.6985),
                    initialZoom: 12,
                    onMapReady: () {
                      _mapReady = true;
                      _fitToBuses();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: TileConfig.current.urlTemplate,
                      userAgentPackageName:
                          TileConfig.current.userAgentPackageName,
                    ),
                    MarkerLayer(markers: _buildBusMarkers()),
                    SimpleAttributionWidget(
                      source: Text(TileConfig.current.attribution),
                    ),
                  ],
                ),

                // Banner mô tả nguồn dữ liệu / trạng thái kết nối.
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (_connected
                                  ? context.colors.primary
                                  : context.colors.error)
                              .withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _connected ? Icons.info_outline : Icons.wifi_off,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _connected
                                ? context.tr('tracking_banner')
                                : context.tr('socket_disconnected'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
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
