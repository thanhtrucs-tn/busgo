// geocoding_service.dart
// Chuyển tọa độ GPS thành địa chỉ chữ (reverse geocoding).
//
// Dùng 2 dịch vụ miễn phí, không cần API key:
//   1. OpenStreetMap Nominatim (ưu tiên, địa chỉ theo cấp hành chính VN).
//   2. BigDataCloud (dự phòng khi Nominatim lỗi hoặc mất mạng).
// Trả null nếu cả hai đều thất bại - màn hình sẽ hiện tọa độ thay thế.

import 'dart:convert';

import 'package:http/http.dart' as http;

class GeocodingService {
  GeocodingService._();
  static final GeocodingService instance = GeocodingService._();

  Future<String?> reverse(double latitude, double longitude) async {
    final nominatim = await _nominatimReverse(latitude, longitude);
    if (nominatim != null && nominatim.isNotEmpty) return nominatim;
    return _bigDataCloudReverse(latitude, longitude);
  }

  // Nominatim trả về địa chỉ dạng:
  // "Tên đường, Phường/Xã, Quận/Huyện, Tỉnh/Thành phố".
  Future<String?> _nominatimReverse(double lat, double lng) async {
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse')
          .replace(
            queryParameters: {
              'lat': lat.toStringAsFixed(6),
              'lon': lng.toStringAsFixed(6),
              'format': 'jsonv2',
              'accept-language': 'vi',
            },
          );
      final response = await http
          .get(uri, headers: {'User-Agent': 'BusGo/1.0'})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) return null;
      return _formatNominatim(data);
    } catch (_) {
      // Lỗi mạng: chuyển sang dịch vụ dự phòng.
      return null;
    }
  }

  // Ráp địa chỉ từ phần "address" của Nominatim theo thứ tự
  // đường -> phường/xã -> quận/huyện -> tỉnh/thành -> quốc gia.
  String? _formatNominatim(Map<String, dynamic> data) {
    final fallback = (data['display_name'] as String?)?.trim();
    final address = data['address'];
    if (address is! Map || address.isEmpty) return fallback;

    String? pick(List<String> keys) {
      for (final key in keys) {
        final value = address[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return null;
    }

    final streetNumber = pick(['house_number']);
    final street = pick(['road', 'pedestrian', 'footway', 'residential']);
    final streetPart = street == null
        ? null
        : (streetNumber == null ? street : '$street $streetNumber');
    final ward = pick([
      'quarter',
      'neighbourhood',
      'suburb',
      'city_district',
      'borough',
      'hamlet',
      'isolated_dwelling',
      'village',
    ]);
    final district = pick(['county', 'district', 'municipality']);
    final province = pick(['state', 'state_district', 'region']);
    final country = pick(['country']);

    final parts = <String?>[
      streetPart,
      ward,
      district,
      province,
      country,
    ].whereType<String>().where((part) => part.isNotEmpty).toList();
    final joined = parts.join(', ');
    // Dự phòng: không ráp được thì dùng chuỗi đầy đủ của Nominatim.
    return joined.isNotEmpty ? joined : fallback;
  }

  Future<String?> _bigDataCloudReverse(double lat, double lng) async {
    try {
      final uri =
          Uri.parse(
            'https://api.bigdatacloud.net/data/reverse-geocode-client',
          ).replace(
            queryParameters: {
              'latitude': lat.toStringAsFixed(6),
              'longitude': lng.toStringAsFixed(6),
              'localityLanguage': 'vi',
            },
          );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) return null;

      final parts =
          <String?>[
                data['locality'],
                data['city'],
                data['principalSubdivision'],
                data['countryName'],
              ]
              .whereType<String>()
              .map((part) => part.trim())
              .where((part) => part.isNotEmpty)
              .toList();
      final joined = parts.join(', ');
      return joined.isNotEmpty ? joined : null;
    } catch (_) {
      return null;
    }
  }
}
