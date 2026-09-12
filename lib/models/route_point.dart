// route_point.dart
// Model một điểm tọa độ trên polyline lộ trình của tuyến.
// Dữ liệu lấy từ API GET /api/routes/:routeId/path (bảng route_points),
// dùng để vẽ đường đi bám theo đường thật thay vì nối thẳng các trạm.

class RoutePoint {
  final double latitude;
  final double longitude;
  final int pointOrder;

  const RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.pointOrder,
  });

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      pointOrder: (json['pointOrder'] as num?)?.toInt() ?? 0,
    );
  }
}
