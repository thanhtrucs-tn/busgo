// sample_data.dart
// Du lieu mau (du lieu gia) dung chung cho cac man hinh.
// Du lieu duoc tao tu cac model: BusRoute, BusStop, Bus.
// Khong can backend, chi dung de hien thi giao dien.

import '../models/bus.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';

// Danh sach cac tram xe buyt mau.
const List<BusStop> sampleStops = [
  BusStop(
    id: '1',
    name: 'Bến Thành',
    address: 'Trần Hưng Đạo, Quận 1',
    latitude: 10.7756,
    longitude: 106.6985,
  ),
  BusStop(
    id: '2',
    name: 'Nhà thờ Đức Bà',
    address: 'Công Xã Paris, Quận 1',
    latitude: 10.7798,
    longitude: 106.6992,
  ),
  BusStop(
    id: '3',
    name: 'Bưu điện TP.HCM',
    address: 'Công Xã Paris, Quận 1',
    latitude: 10.7796,
    longitude: 106.7001,
  ),
  BusStop(
    id: '4',
    name: 'Công viên Lê Văn Tám',
    address: 'Hai Bà Trưng, Quận 1',
    latitude: 10.7829,
    longitude: 106.6983,
  ),
  BusStop(
    id: '5',
    name: 'Chợ Lớn',
    address: 'Nguyễn Trãi, Quận 5',
    latitude: 10.7489,
    longitude: 106.6500,
  ),
  BusStop(
    id: '6',
    name: 'Sân bay Tân Sơn Nhất',
    address: 'Trường Sơn, Tân Bình',
    latitude: 10.8188,
    longitude: 106.6523,
  ),
];

// Danh sach cac tuyen xe buyt mau. Moi tuyen co danh sach tram rieng.
final List<BusRoute> sampleRoutes = [
  BusRoute(
    id: '1',
    routeNumber: '01',
    name: 'Bến Thành - Chợ Lớn',
    startPoint: 'Bến Thành',
    endPoint: 'Chợ Lớn',
    operatingTime: '05:00 - 21:00',
    stops: [
      sampleStops[0],
      sampleStops[1],
      sampleStops[2],
      sampleStops[3],
      sampleStops[4],
    ],
  ),
  BusRoute(
    id: '2',
    routeNumber: '04',
    name: 'Bến Xe Chợ Lớn - Cộng Hòa',
    startPoint: 'Bến Xe Chợ Lớn',
    endPoint: 'Cộng Hòa',
    operatingTime: '05:30 - 20:30',
    stops: [
      sampleStops[4],
      sampleStops[0],
      sampleStops[3],
    ],
  ),
  BusRoute(
    id: '3',
    routeNumber: '06',
    name: 'Bến Thành - Biên Hòa',
    startPoint: 'Bến Thành',
    endPoint: 'Biên Hòa',
    operatingTime: '04:30 - 19:30',
    stops: [
      sampleStops[0],
      sampleStops[3],
      sampleStops[2],
    ],
  ),
  BusRoute(
    id: '4',
    routeNumber: '19',
    name: 'Bến Thành - Sân bay Tân Sơn Nhất',
    startPoint: 'Bến Thành',
    endPoint: 'Sân bay Tân Sơn Nhất',
    operatingTime: '05:00 - 22:00',
    stops: [
      sampleStops[0],
      sampleStops[1],
      sampleStops[5],
    ],
  ),
];

// Danh sach xe buyt mau (vi tri mo phong, khong phai GPS thuc).
const List<Bus> sampleBuses = [
  Bus(
    id: '1',
    busNumber: 'BUS-001',
    routeId: '1',
    latitude: 10.7765,
    longitude: 106.7009,
    status: 'active',
  ),
  Bus(
    id: '2',
    busNumber: 'BUS-002',
    routeId: '4',
    latitude: 10.8180,
    longitude: 106.6510,
    status: 'active',
  ),
  Bus(
    id: '3',
    busNumber: 'BUS-003',
    routeId: '2',
    latitude: 10.7490,
    longitude: 106.6510,
    status: 'active',
  ),
];

// Tim cac tuyen xe buyt di qua mot tram (theo id cua tram).
List<BusRoute> routesThroughStop(String stopId) {
  return sampleRoutes
      .where((route) => route.stops.any((stop) => stop.id == stopId))
      .toList();
}