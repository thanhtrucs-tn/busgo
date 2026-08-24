// bus_route.dart
// Model dai dien cho mot tuyen xe buyt (BusRoute).
// Moi tuyen co danh sach cac tram (stops) cua no.

import 'bus_stop.dart';

class BusRoute {
  final String id;
  final String routeNumber;
  final String name;
  final String startPoint;
  final String endPoint;
  final String operatingTime;
  final List<BusStop> stops;

  const BusRoute({
    required this.id,
    required this.routeNumber,
    required this.name,
    required this.startPoint,
    required this.endPoint,
    required this.operatingTime,
    required this.stops,
  });
}