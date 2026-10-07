
class Bus {
  final String id;
  final String busNumber;
  final String routeId;
  final double latitude;
  final double longitude;
  final String status;

  // Thông tin thêm từ backend.
  final String? licensePlate;
  final double? speed;
  final double? heading;
  final DateTime? updatedAt;

  const Bus({
    required this.id,
    required this.busNumber,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.licensePlate,
    this.speed,
    this.heading,
    this.updatedAt,
  });

  // Xe coi như đang hoạt động nếu không ở trạng thái INACTIVE.
  bool get isActive => status.toUpperCase() != 'INACTIVE';

  // Có tọa độ hợp lệ để hiển thị trên bản đồ hay không.
  bool get hasLocation =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      (latitude != 0 || longitude != 0);

  // Tạo Bus từ JSON của API GET /api/routes/:routeId/buses.
  factory Bus.fromJson(Map<String, dynamic> json) {
    final updated = json['updatedAt'] as String?;
    return Bus(
      id: '${json['id']}',
      busNumber: (json['busCode'] ?? '') as String,
      routeId: '${json['routeId']}',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      status: (json['status'] ?? 'ACTIVE') as String,
      licensePlate: json['licensePlate'] as String?,
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      updatedAt: updated != null ? DateTime.tryParse(updated) : null,
    );
  }

  // Tạo bản sao với một vài trường được cập nhật (dùng khi nhận vị trí mới).
  Bus copyWith({
    String? busNumber,
    double? latitude,
    double? longitude,
    String? status,
    double? speed,
    double? heading,
    DateTime? updatedAt,
  }) {
    return Bus(
      id: id,
      busNumber: busNumber ?? this.busNumber,
      routeId: routeId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      licensePlate: licensePlate,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
