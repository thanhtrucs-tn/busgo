// feature_flow_test.dart
// Bo test kiem thu cac chuc nang chinh cua BusGo (Phase 11):
// mo app -> xem tuyen -> tim kiem -> chi tiet -> tram -> ban do
// -> theo doi xe -> yeu thich -> dieu huong giua cac man hinh.
//
// LUU Y: tu khi them tinh nang dang nhap, app mo dau bang man hinh
// "Dang nhap". Vi the cac test chuc nang duoi day BOM TRUC TIEP HomeScreen
// (bo qua buoc dang nhap) de kiem thu tung tinh nang cua trang chu.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:busgo/data/sample_data.dart';
import 'package:busgo/l10n/app_localizations.dart';
import 'package:busgo/models/bus.dart';
import 'package:busgo/models/bus_route.dart';
import 'package:busgo/models/bus_stop.dart';
import 'package:busgo/models/nearby_stop.dart';
import 'package:busgo/models/route_point.dart';
import 'package:busgo/models/route_stop.dart';
import 'package:busgo/models/stop_arrival.dart';
import 'package:busgo/screens/bus_tracking_screen.dart';
import 'package:busgo/screens/home_screen.dart';
import 'package:busgo/screens/map_screen.dart';
import 'package:busgo/services/favorite_service.dart';
import 'package:busgo/services/socket_service.dart';
import 'package:busgo/services/transit_service.dart';
import 'package:busgo/theme/app_theme.dart';

// Bản giả của TransitService: trả về dữ liệu mẫu thay vì gọi API,
// để test các màn hình mà không cần backend.
class _FakeTransitService extends TransitService {
  @override
  Future<List<BusRoute>> fetchRoutes() async => sampleRoutes;

  @override
  Future<BusRoute> fetchRoute(String routeId) async =>
      sampleRoutes.firstWhere((r) => r.id == routeId);

  @override
  Future<List<BusStop>> fetchStops({String? q}) async => sampleStops;

  @override
  Future<List<RouteStop>> fetchRouteStops(
    String routeId, {
    int direction = 0,
  }) async {
    final route = sampleRoutes.firstWhere((r) => r.id == routeId);
    return [
      for (int i = 0; i < route.stops.length; i++)
        RouteStop(
          stop: route.stops[i],
          direction: direction,
          stopOrder: i + 1,
        ),
    ];
  }

  @override
  Future<List<RoutePoint>> fetchRoutePath(
    String routeId, {
    int direction = 0,
  }) async =>
      const [];

  @override
  Future<List<Bus>> fetchRouteBuses(String routeId) async =>
      sampleBuses.where((b) => b.routeId == routeId).toList();

  @override
  Future<List<BusRoute>> fetchStopRoutes(String stopId) async =>
      routesThroughStop(stopId);

  @override
  Future<List<StopArrival>> fetchStopArrivals(String stopId) async =>
      const [];

  @override
  Future<List<NearbyStop>> fetchNearbyStops(
    double latitude,
    double longitude, {
    int radius = 2000,
  }) async =>
      const [];
}

// Bản giả trả về dữ liệu rỗng (kiểm thử trạng thái "không có dữ liệu").
class _EmptyTransitService extends _FakeTransitService {
  @override
  Future<List<BusRoute>> fetchRoutes() async => const [];

  @override
  Future<List<BusStop>> fetchStops({String? q}) async => const [];
}

void main() {
  setUp(() {
    // Dung bo nho gia cho shared_preferences trong moi test.
    SharedPreferences.setMockInitialValues({});
    // Dung du lieu mau thay cho API backend.
    TransitService.instance = _FakeTransitService();
    // Khong mo ket noi Socket.IO trong moi truong test.
    SocketService.instance.enabled = false;
  });

  // Phong to cua so test de Home hien thi du ca 5 the chuc nang.
  void setTestWindow(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  // Bom trang chu truc tiep (khong can dang nhap) voi day du theme
  // va he thong da ngon ngu giong nhu app that.
  Future<void> pumpHome(WidgetTester tester) async {
    // Xoa danh sach yeu thich trong bo nho de moi test bat dau trang.
    await FavoriteService.instance.clear();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildAppTheme(),
        darkTheme: buildDarkTheme(),
        home: const HomeScreen(),
      ),
    );
    // Cho MaterialApp nap xong du lieu da ngon ngu (Localizations bat dong bo).
    await tester.pumpAndSettle();
  }

  testWidgets('1. Mo app: Home hien thi du 5 chuc nang', (tester) async {
    setTestWindow(tester);
    await pumpHome(tester);

    expect(find.text('BusGo'), findsWidgets);
    expect(find.text('Danh sách tuyến'), findsOneWidget);
    expect(find.text('Tìm trạm'), findsOneWidget);
    // "Bản đồ" xuat hien 2 lan: the chuc nang + muc trong thanh menu duoi.
    expect(find.text('Bản đồ'), findsNWidgets(2));
    expect(find.text('Theo dõi xe'), findsOneWidget);
    expect(find.text('Yêu thích'), findsOneWidget);
    expect(find.text('Thống kê'), findsOneWidget);
  });

  testWidgets('2. Xem tuyen: danh sach -> tim kiem -> chi tiet', (
    tester,
  ) async {
    setTestWindow(tester);
    await pumpHome(tester);

    // Dieu huong: Home -> Danh sach tuyen.
    await tester.tap(find.text('Danh sách tuyến'));
    await tester.pumpAndSettle();
    expect(find.text('Bến Thành - Chợ Lớn'), findsOneWidget);
    expect(find.text('Bến Thành - Sân bay Tân Sơn Nhất'), findsOneWidget);

    // Tim kiem theo ten tuyen.
    await tester.enterText(find.byType(TextField), 'sân bay');
    await tester.pump();
    expect(find.text('Bến Thành - Sân bay Tân Sơn Nhất'), findsOneWidget);
    expect(find.text('Bến Thành - Chợ Lớn'), findsNothing);

    // Empty state khi khong co ket qua.
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('Không tìm thấy tuyến nào'), findsOneWidget);

    // Xoa tim kiem va vao chi tiet tuyen 01.
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.tap(find.text('Bến Thành - Chợ Lớn'));
    await tester.pumpAndSettle();

    expect(find.text('Tuyến 01'), findsOneWidget);
    expect(find.text('Hành trình'), findsOneWidget);
    expect(find.text('5 trạm'), findsWidgets);
    expect(find.text('Xe buýt trên tuyến'), findsOneWidget);
    expect(find.text('BUS-001'), findsOneWidget);
  });

  testWidgets('3. Tim tram: danh sach -> tim kiem -> chi tiet tram', (
    tester,
  ) async {
    setTestWindow(tester);
    await pumpHome(tester);

    // Dieu huong: Home -> Tim tram.
    await tester.tap(find.text('Tìm trạm'));
    await tester.pumpAndSettle();
    expect(find.text('Bến Thành'), findsOneWidget);

    // Tim tram theo dia chi.
    await tester.enterText(find.byType(TextField), 'Quận 5');
    await tester.pump();
    expect(find.text('Chợ Lớn'), findsOneWidget);
    expect(find.text('Bến Thành'), findsNothing);

    // Empty state.
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('Không tìm thấy trạm nào'), findsOneWidget);

    // Xoa tim kiem va vao chi tiet tram Bến Thành.
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.tap(find.text('Bến Thành'));
    await tester.pumpAndSettle();

    // Bến Thành co 4 tuyen di qua: 01, 04, 06, 19.
    expect(find.text('Các tuyến đi qua trạm'), findsOneWidget);
    expect(find.text('4 tuyến'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.text('19'), findsOneWidget);
  });

  testWidgets('4. Yeu thich: them -> xem danh sach -> bo', (tester) async {
    setTestWindow(tester);
    await pumpHome(tester);

    await tester.tap(find.text('Danh sách tuyến'));
    await tester.pumpAndSettle();

    // Luc dau chua co tuyen nao yeu thich (4 tim rong).
    expect(find.byIcon(Icons.favorite_border), findsNWidgets(4));

    // Them tuyen dau tien vao yeu thich.
    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    // Quay lai Home roi mo man hinh Yeu thich.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yêu thích'));
    await tester.pumpAndSettle();
    expect(find.text('Bến Thành - Chợ Lớn'), findsOneWidget);

    // Bo yeu thich -> hien empty state.
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa có tuyến yêu thích nào'), findsOneWidget);
  });

  testWidgets('5. Ban do: chua co tuyen thi hien thong bao', (tester) async {
    setTestWindow(tester);
    TransitService.instance = _EmptyTransitService();
    await tester.pumpWidget(const MaterialApp(home: MapScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Chưa có tuyến xe buýt'), findsOneWidget);

    // Huy man hinh de ket thuc sach se.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('6. Ban do: hien thi marker cua cac tram', (tester) async {
    setTestWindow(tester);
    await tester.pumpWidget(const MaterialApp(home: MapScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(
      find.byIcon(Icons.location_pin),
      findsNWidgets(sampleStops.length),
    );

    // Huy man hinh de ket thuc sach se (khong con ticker).
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('7. Theo doi xe: hien thi xe va banner mo phong', (tester) async {
    setTestWindow(tester);
    await tester.pumpWidget(const MaterialApp(home: BusTrackingScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Dữ liệu mô phỏng'), findsOneWidget);
    expect(find.byIcon(Icons.directions_bus), findsNWidgets(3));

    // Huy man hinh de dung listener.
    await tester.pumpWidget(const SizedBox());
  });
}
