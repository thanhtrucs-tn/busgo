
class BusStop {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  // Trạng thái: 'active' | 'inactive' (mặc định 'active' cho dữ liệu mẫu).
  final String status;

  // Số tuyến đi qua trạm (backend trả về; dữ liệu mẫu để 0).
  final int routeCount;

  const BusStop({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.status = 'active',
    this.routeCount = 0,
  });

  bool get isActive => status.toLowerCase() == 'active';

  // Tạo BusStop từ JSON của API GET /api/stops hoặc GET /api/stops/:id.
  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      id: '${json['id']}',
      name: (json['stopName'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      status: (json['status'] ?? 'active') as String,
      routeCount: (json['routeCount'] as num?)?.toInt() ?? 0,
    );
  }
}
