
import '../models/bus.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../models/nearby_stop.dart';
import '../models/route_point.dart';
import '../models/route_stop.dart';
import '../models/stop_arrival.dart';
import 'api_service.dart';

// Lỗi nghiệp vụ khi gọi API tuyến/trạm.
class TransitException implements Exception {
  const TransitException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TransitService {
  // Cho phép thay thế instance khi kiểm thử (test có thể gán bản giả).
  static TransitService instance = TransitService();

  // Danh sách tuyến xe buýt.
  Future<List<BusRoute>> fetchRoutes() async {
    final result = await ApiService.instance.get('/routes');
    return _asList(result, (json) => BusRoute.fromJson(json));
  }

  // Chi tiết một tuyến (chưa kèm danh sách trạm).
  Future<BusRoute> fetchRoute(String routeId) async {
    final result = await ApiService.instance.get('/routes/$routeId');
    final payload = result.payload;
    if (!result.success || payload is! Map<String, dynamic>) {
      throw TransitException(result.message);
    }
    return BusRoute.fromJson(payload);
  }

  // Danh sách tuyến kèm danh sách trạm (dùng cho màn hình chi tiết tuyến).
  Future<BusRoute> fetchRouteWithStops(
    String routeId, {
    int direction = 0,
  }) async {
    final route = await fetchRoute(routeId);
    final routeStops = await fetchRouteStops(routeId, direction: direction);
    return route.copyWithStops(routeStops.map((rs) => rs.stop).toList());
  }

  // Danh sách trạm của một tuyến theo chiều (0 = đi, 1 = về).
  Future<List<RouteStop>> fetchRouteStops(
    String routeId, {
    int direction = 0,
  }) async {
    final result = await ApiService.instance.get(
      '/routes/$routeId/stops',
      query: {'direction': '$direction'},
    );
    return _asList(result, (json) => RouteStop.fromJson(json));
  }

  // Tọa độ polyline của tuyến theo chiều.
  Future<List<RoutePoint>> fetchRoutePath(
    String routeId, {
    int direction = 0,
  }) async {
    final result = await ApiService.instance.get(
      '/routes/$routeId/path',
      query: {'direction': '$direction'},
    );
    return _asList(result, (json) => RoutePoint.fromJson(json));
  }

  // Danh sách xe của tuyến kèm vị trí mới nhất.
  Future<List<Bus>> fetchRouteBuses(String routeId) async {
    final result = await ApiService.instance.get('/routes/$routeId/buses');
    return _asList(result, (json) => Bus.fromJson(json));
  }

  // Danh sách trạm toàn hệ thống (lọc theo từ khóa q nếu có).
  Future<List<BusStop>> fetchStops({String? q}) async {
    final result = await ApiService.instance.get(
      '/stops',
      query: (q != null && q.trim().isNotEmpty) ? {'q': q.trim()} : null,
    );
    return _asList(result, (json) => BusStop.fromJson(json));
  }

  // Danh sách xe đang đến một trạm (kèm thời gian dự kiến).
  Future<List<StopArrival>> fetchStopArrivals(String stopId) async {
    final result = await ApiService.instance.get('/stops/$stopId/arrivals');
    return _asList(result, (json) => StopArrival.fromJson(json));
  }

  // Danh sách trạm gần vị trí người dùng (bán kính tính bằng mét).
  Future<List<NearbyStop>> fetchNearbyStops(
    double latitude,
    double longitude, {
    int radius = 2000,
  }) async {
    final result = await ApiService.instance.get(
      '/stops/nearby',
      query: {
        'latitude': '$latitude',
        'longitude': '$longitude',
        'radius': '$radius',
      },
    );
    return _asList(result, (json) => NearbyStop.fromJson(json));
  }

  // Các tuyến đi qua một trạm (đã loại trùng theo id tuyến).
  Future<List<BusRoute>> fetchStopRoutes(String stopId) async {
    final result = await ApiService.instance.get('/stops/$stopId/routes');
    final list = _asList(result, (json) {
      final routeJson = json['route'];
      if (routeJson is! Map<String, dynamic>) return null;
      return BusRoute.fromJson(routeJson);
    });

    final seen = <String>{};
    final unique = <BusRoute>[];
    for (final route in list) {
      if (seen.add(route.id)) unique.add(route);
    }
    return unique;
  }

  // Chuyển payload (List) thành danh sách model. Bỏ qua phần tử không hợp lệ.
  List<T> _asList<T>(
    ApiResult result,
    T? Function(Map<String, dynamic> json) parse,
  ) {
    final payload = result.payload;
    if (!result.success || payload is! List) {
      throw TransitException(result.message);
    }
    final items = <T>[];
    for (final element in payload) {
      if (element is Map<String, dynamic>) {
        final parsed = parse(element);
        if (parsed != null) items.add(parsed);
      }
    }
    return items;
  }
}
