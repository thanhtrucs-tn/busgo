// route_stop.dart
// Model một TRẠM nằm trên TUYẾN theo một chiều đi/về.
// Dữ liệu lấy từ API GET /api/routes/:routeId/stops?direction=0|1.
// Bao gồm thông tin trạm + thứ tự trạm + thời gian ước tính từ điểm đầu.

import 'bus_stop.dart';

class RouteStop {
  final BusStop stop;
  final int direction; // 0 = chiều đi, 1 = chiều về
  final int stopOrder;
  final int? estimatedMinutesFromStart;

  const RouteStop({
    required this.stop,
    required this.direction,
    required this.stopOrder,
    this.estimatedMinutesFromStart,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    final stopJson = (json['stop'] as Map<String, dynamic>?) ?? const {};
    return RouteStop(
      stop: BusStop.fromJson(stopJson),
      direction: (json['direction'] as num?)?.toInt() ?? 0,
      stopOrder: (json['stopOrder'] as num?)?.toInt() ?? 0,
      estimatedMinutesFromStart:
          (json['estimatedMinutesFromStart'] as num?)?.toInt(),
    );
  }
}
