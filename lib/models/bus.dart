// bus.dart
// Model dai dien cho mot chiec xe buyt (Bus).
// Phase 8 se dung model nay de hien thi vi tri xe (du lieu mo phong).

class Bus {
  final String id;
  final String busNumber;
  final String routeId;
  final double latitude;
  final double longitude;
  final String status;

  const Bus({
    required this.id,
    required this.busNumber,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    required this.status,
  });
}