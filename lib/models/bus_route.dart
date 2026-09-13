// bus_route.dart
// Model đại diện cho một TUYẾN xe buýt (BusRoute).
//
// Model dùng chung cho cả hai nguồn dữ liệu:
//  - Dữ liệu mẫu dùng cho test (test/fixtures/sample_data.dart).
//  - API backend (GET /api/routes) thông qua factory BusRoute.fromJson.
//
// Các trường mới (color, startTime, endTime, frequencyMinutes, fare, status,
// stopCount) đều có giá trị mặc định nên dữ liệu mẫu cũ vẫn tạo được.

import 'bus_stop.dart';

class BusRoute {
  final String id;
  final String routeNumber;
  final String name;
  final String startPoint;
  final String endPoint;
  final String operatingTime;

  // Danh sách trạm (chỉ có khi được nạp từ API stops/detail).
  final List<BusStop> stops;

  // Thông tin thêm từ backend.
  final String? color;
  final String? startTime;
  final String? endTime;
  final int? frequencyMinutes;
  final double? fare;
  final String status;
  final int stopCount;

  const BusRoute({
    required this.id,
    required this.routeNumber,
    required this.name,
    required this.startPoint,
    required this.endPoint,
    required this.operatingTime,
    this.stops = const [],
    this.color,
    this.startTime,
    this.endTime,
    this.frequencyMinutes,
    this.fare,
    this.status = 'active',
    this.stopCount = 0,
  });

  // Số trạm hiển thị: ưu tiên danh sách trạm đã nạp, nếu chưa có thì dùng
  // stopCount do backend trả kèm trong danh sách tuyến.
  int get displayStopCount => stops.isNotEmpty ? stops.length : stopCount;

  bool get isActive => status.toLowerCase() == 'active';

  // Tạo BusRoute từ JSON của API GET /api/routes.
  factory BusRoute.fromJson(Map<String, dynamic> json) {
    final startTime = json['startTime'] as String?;
    final endTime = json['endTime'] as String?;
    final operatingTime = (startTime != null && endTime != null)
        ? '$startTime - $endTime'
        : '';

    return BusRoute(
      id: '${json['id']}',
      routeNumber: (json['routeCode'] ?? '') as String,
      name: (json['routeName'] ?? '') as String,
      startPoint: (json['startPoint'] ?? '') as String,
      endPoint: (json['endPoint'] ?? '') as String,
      operatingTime: operatingTime,
      color: json['color'] as String?,
      startTime: startTime,
      endTime: endTime,
      frequencyMinutes: (json['frequencyMinutes'] as num?)?.toInt(),
      fare: (json['fare'] as num?)?.toDouble(),
      status: (json['status'] ?? 'active') as String,
      stopCount: (json['stopCount'] as num?)?.toInt() ?? 0,
    );
  }

  // Tạo bản sao có kèm danh sách trạm (dùng khi ghép route + stops).
  BusRoute copyWithStops(List<BusStop> newStops) {
    return BusRoute(
      id: id,
      routeNumber: routeNumber,
      name: name,
      startPoint: startPoint,
      endPoint: endPoint,
      operatingTime: operatingTime,
      stops: newStops,
      color: color,
      startTime: startTime,
      endTime: endTime,
      frequencyMinutes: frequencyMinutes,
      fare: fare,
      status: status,
      stopCount: newStops.isNotEmpty ? newStops.length : stopCount,
    );
  }
}
