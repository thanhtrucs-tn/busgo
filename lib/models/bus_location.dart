// bus_location.dart
// Model cho các sự kiện REALTIME từ Socket.IO.
//
//  - BusLocation: payload của sự kiện 'bus:location-updated'.
//  - BusStatusUpdate: payload của sự kiện 'bus:status-updated'.
//
// Dữ liệu này do tài xế hoặc bộ mô phỏng GPS gửi lên backend, sau đó backend
// phát lại cho mọi client đang ở trong phòng route:<routeId>.

class BusLocation {
  final String busId;
  final String busCode;
  final String routeId;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final DateTime? updatedAt;

  const BusLocation({
    required this.busId,
    required this.busCode,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    this.updatedAt,
  });

  // Vị trí quá cũ (mặc định > 5 phút) thì nên bỏ qua, không hiển thị.
  bool isStale({Duration maxAge = const Duration(minutes: 5)}) {
    final updated = updatedAt;
    if (updated == null) return false;
    return DateTime.now().difference(updated) > maxAge;
  }

  factory BusLocation.fromJson(Map<String, dynamic> json) {
    final updated = json['updatedAt'] as String?;
    return BusLocation(
      busId: '${json['busId']}',
      busCode: (json['busCode'] ?? '') as String,
      routeId: '${json['routeId']}',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      updatedAt: updated != null ? DateTime.tryParse(updated) : null,
    );
  }
}

// Cập nhật trạng thái xe (ACTIVE / RUNNING / INACTIVE).
class BusStatusUpdate {
  final String busId;
  final String busCode;
  final String routeId;
  final String status;
  final DateTime? updatedAt;

  const BusStatusUpdate({
    required this.busId,
    required this.busCode,
    required this.routeId,
    required this.status,
    this.updatedAt,
  });

  factory BusStatusUpdate.fromJson(Map<String, dynamic> json) {
    final updated = json['updatedAt'] as String?;
    return BusStatusUpdate(
      busId: '${json['busId']}',
      busCode: (json['busCode'] ?? '') as String,
      routeId: '${json['routeId']}',
      status: (json['status'] ?? 'ACTIVE') as String,
      updatedAt: updated != null ? DateTime.tryParse(updated) : null,
    );
  }
}
