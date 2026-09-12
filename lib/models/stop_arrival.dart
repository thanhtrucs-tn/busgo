// stop_arrival.dart
// Model XE SẮP ĐẾN TRẠM, lấy từ API GET /api/stops/:stopId/arrivals.
//
// Thời gian dự kiến là ƯỚC LƯỢNG CƠ BẢN (khoảng cách dọc lộ trình / vận tốc),
// không phải dữ liệu giao thông thực tế.

class StopArrival {
  final String busId;
  final String busCode;
  final String? routeCode;
  final String? routeName;
  final int direction;
  final int distanceMeters;
  final int estimatedMinutes;
  final bool isSimulated;
  final DateTime? lastUpdatedAt;

  const StopArrival({
    required this.busId,
    required this.busCode,
    required this.routeCode,
    required this.routeName,
    required this.direction,
    required this.distanceMeters,
    required this.estimatedMinutes,
    required this.isSimulated,
    this.lastUpdatedAt,
  });

  factory StopArrival.fromJson(Map<String, dynamic> json) {
    final route = json['route'];
    final routeMap =
        route is Map<String, dynamic> ? route : const <String, dynamic>{};
    final updated = json['lastUpdatedAt'] as String?;

    return StopArrival(
      busId: '${json['busId']}',
      busCode: (json['busCode'] ?? '') as String,
      routeCode: routeMap['routeCode'] as String?,
      routeName: routeMap['routeName'] as String?,
      direction: (json['direction'] as num?)?.toInt() ?? 0,
      distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 0,
      isSimulated: json['isSimulated'] as bool? ?? true,
      lastUpdatedAt: updated != null ? DateTime.tryParse(updated) : null,
    );
  }
}
