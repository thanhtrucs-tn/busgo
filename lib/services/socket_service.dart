

import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../config/api_config.dart';
import '../models/bus_location.dart';

class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  // Cho phép tắt kết nối khi chạy test (không gọi mạng trong môi trường test).
  bool enabled = true;

  socket_io.Socket? _socket;

  // Số nơi (widget) đang theo dõi mỗi tuyến: { routeId: số lượng }.
  final Map<int, int> _routeRefs = {};

  final StreamController<BusLocation> _locationController =
      StreamController<BusLocation>.broadcast();
  final StreamController<BusStatusUpdate> _statusController =
      StreamController<BusStatusUpdate>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  // Luồng vị trí xe mới.
  Stream<BusLocation> get locationUpdates => _locationController.stream;

  // Luồng trạng thái xe mới.
  Stream<BusStatusUpdate> get statusUpdates => _statusController.stream;

  // Luồng trạng thái kết nối (true = đã kết nối, false = mất kết nối).
  Stream<bool> get connectionUpdates => _connectionController.stream;

  bool get isConnected => _socket?.connected ?? false;

  // Mở kết nối tới backend (chỉ mở một lần).
  void connect() {
    if (!enabled || _socket != null) return;

    final socket = socket_io.io(
      ApiConfig.socketBaseUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(50)
          .setReconnectionDelay(2000)
          .build(),
    );

    socket.onConnect((_) {
      _connectionController.add(true);
      // Sau khi (kết nối lại) thành công, tham gia lại mọi phòng đã đăng ký.
      for (final routeId in _routeRefs.keys) {
        socket.emit('route:join', routeId);
      }
    });

    socket.onDisconnect((_) => _connectionController.add(false));
    socket.onConnectError((_) => _connectionController.add(false));
    socket.onError((_) => _connectionController.add(false));

    socket.on('bus:location-updated', (data) {
      final map = _asMap(data);
      if (map != null) _locationController.add(BusLocation.fromJson(map));
    });

    socket.on('bus:status-updated', (data) {
      final map = _asMap(data);
      if (map != null) _statusController.add(BusStatusUpdate.fromJson(map));
    });

    _socket = socket;
    socket.connect();
  }

  // Tham gia phòng của một tuyến (tăng bộ đếm tham chiếu).
  void joinRoute(int routeId) {
    if (!enabled) return;
    connect();

    _routeRefs[routeId] = (_routeRefs[routeId] ?? 0) + 1;
    if (_socket?.connected == true) {
      _socket!.emit('route:join', routeId);
    }
    // Nếu chưa kết nối, onConnect sẽ tham gia lại toàn bộ phòng.
  }

  // Rời phòng của một tuyến (giảm bộ đếm; chỉ rời khi không còn ai theo dõi).
  void leaveRoute(int routeId) {
    if (!enabled) return;

    final count = _routeRefs[routeId] ?? 0;
    if (count <= 1) {
      _routeRefs.remove(routeId);
      if (_socket?.connected == true) {
        _socket!.emit('route:leave', routeId);
      }
    } else {
      _routeRefs[routeId] = count - 1;
    }
  }

  // Đóng kết nối hoàn toàn (dùng khi đăng xuất / thoát app).
  void disconnect() {
    _routeRefs.clear();
    _socket?.dispose();
    _socket = null;
    _connectionController.add(false);
  }

  // Chuyển dữ liệu socket (có thể là Map<dynamic, dynamic>) về Map<String, dynamic>.
  Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry('$key', value));
    }
    return null;
  }
}
