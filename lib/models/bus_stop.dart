// bus_stop.dart
// Model dai dien cho mot tram xe buyt (BusStop).
// Model la lop chi chua du lieu, dung de tach du lieu khoi giao dien.

class BusStop {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const BusStop({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}