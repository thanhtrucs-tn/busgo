// nearby_stop.dart
// Model một TRẠM GẦN VỊ TRÍ NGƯỜI DÙNG, lấy từ API GET /api/stops/nearby.
// Gồm thông tin trạm + khoảng cách (mét) từ người dùng đến trạm.

import 'bus_stop.dart';

class NearbyStop {
  final BusStop stop;
  final int distanceMeters;

  const NearbyStop({required this.stop, required this.distanceMeters});

  factory NearbyStop.fromJson(Map<String, dynamic> json) {
    return NearbyStop(
      stop: BusStop.fromJson(json),
      distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
    );
  }

  // Chuỗi khoảng cách thân thiện: dưới 1 km hiển thị mét, trên 1 km hiển thị km.
  String get distanceText {
    if (distanceMeters < 1000) return '$distanceMeters m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }
}
