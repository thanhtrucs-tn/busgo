// location_service.dart
// Dịch vụ GPS TRUNG TÂM của ứng dụng - tách toàn bộ logic vị trí
// ra khỏi Widget (đúng chuẩn kiến trúc, dễ tái sử dụng, dễ test).
//
// Service chịu trách nhiệm:
//   1. Kiểm tra GPS đã bật chưa (Location Service).
//   2. Kiểm tra / xin quyền vị trí (Permission).
//   3. Lấy vị trí hiện tại (latitude, longitude).
//   4. Xử lý mọi lỗi có thể xảy ra -> trả thông điệp TIẾNG VIỆT rõ ràng,
//      TUYỆT ĐỐI KHÔNG để app crash.
//
// Các lỗi được xử lý:
//   - GPS tắt                 -> "Vui lòng bật định vị (GPS)..."
//   - Từ chối quyền            -> "Vui lòng cấp quyền vị trí..."
//   - Từ chối vĩnh viễn        -> hướng dẫn mở Settings
//   - Lấy vị trí thất bại/timeout -> thông báo thử lại
//   - Thiết bị không hỗ trợ    -> thông báo rõ ràng
//
// LƯU Ý: package geolocator chỉ hỗ trợ Android/iOS/macOS chính thức;
// trên Windows/Web nó sẽ ném UnsupportedError -> service bắt lại
// và trả thông báo "thiết bị không hỗ trợ" thay vì crash.

import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../models/user_location.dart';

// Kết quả lấy vị trí: thành công thì có location, thất bại thì có error.
class LocationResult {
  const LocationResult({this.location, this.error});

  // Vị trí lấy được (null nếu thất bại).
  final UserLocation? location;

  // Thông báo lỗi thân thiện bằng tiếng Việt (rỗng nếu thành công).
  final String? error;

  bool get success => location != null;
}

class LocationService {
  // Singleton: chỉ có một đối tượng duy nhất trong cả ứng dụng.
  LocationService._();
  static final LocationService instance = LocationService._();

  // ------------------------------------------------------------
  // LẤY VỊ TRÍ HIỆN TẠI (hàm chính).
  // Quy trình: bật GPS? -> có quyền? -> lấy tọa độ -> trả về.
  // ------------------------------------------------------------
  Future<LocationResult> getCurrentLocation() async {
    try {
      // Bước 1: kiểm tra thiết bị có hỗ trợ GPS không.
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(
          error: 'Vui lòng bật định vị (GPS) để sử dụng chức năng này',
        );
      }

      // Bước 2: kiểm tra / xin quyền vị trí.
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Lần đầu: xin quyền lại.
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied) {
          return const LocationResult(
            error: 'Vui lòng cấp quyền vị trí để sử dụng chức năng này',
          );
        }
        if (requested == LocationPermission.deniedForever) {
          return const LocationResult(
            error:
                'Quyền vị trí bị từ chối vĩnh viễn, hãy mở Cài đặt để cấp lại',
          );
        }
      } else if (permission == LocationPermission.deniedForever) {
        // Bị từ chối vĩnh viễn -> app KHÔNG tự xin lại được,
        // phải nhờ người dùng mở Settings. App sẽ hiện nút "Mở Cài đặt".
        return const LocationResult(
          error: 'Quyền vị trí bị từ chối vĩnh viễn, hãy mở Cài đặt để cấp lại',
        );
      }

      // Bước 3: lấy vị trí hiện tại (độ chính xác trung bình, tối đa 15s).
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // Bước 4: trả về latitude + longitude.
      return LocationResult(
        location: UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } on UnsupportedError {
      // Thiết bị không hỗ trợ GPS (ví dụ Windows/Web khi dùng geolocator mới).
      return const LocationResult(
        error: 'Thiết bị này không hỗ trợ định vị GPS',
      );
    } on TimeoutException {
      return const LocationResult(
        error: 'Không lấy được vị trí, vui lòng thử lại',
      );
    } catch (_) {
      // Mọi lỗi khác (mất kết nối, khoá thời gian...) - không crash.
      return const LocationResult(
        error: 'Không lấy được vị trí, vui lòng thử lại',
      );
    }
  }

  // Mở trang Cài đặt hệ thống để người dùng tự cấp quyền vị trí.
  // Dùng khi quyền bị từ chối vĩnh viễn.
  static Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }

  // ------------------------------------------------------------
  // TÍNH KHOẢNG CÁCH giữa 2 điểm tọa độ (đơn vị: km).
  // Dùng công thức Haversine - đủ chính xác cho khoảng cách
  // giữa các trạm xe buýt trong thành phố.
  // ------------------------------------------------------------
  static double distanceKm(UserLocation a, UserLocation b) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _toRadians(b.latitude - a.latitude);
    final double dLng = _toRadians(b.longitude - a.longitude);
    final double lat1 = _toRadians(a.latitude);
    final double lat2 = _toRadians(b.latitude);

    // Công thức Haversine:
    //   a = sin²(Δlat/2) + cos(lat1)·cos(lat2)·sin²(Δlng/2)
    //   c = 2·atan2(√a, √(1−a)) ; distance = R·c
    final double h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLng / 2), 2);
    final double c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadiusKm * c;
  }

  // Chuyển độ (degree) sang radian cho công thức Haversine.
  static double _toRadians(double degrees) => degrees * math.pi / 180.0;
}
