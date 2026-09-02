// user_location.dart
// Model đơn giản biểu diễn VỊ TRÍ HIỆN TẠI của người dùng.
//
// Ví dụ:
//   UserLocation(latitude: 10.7756, longitude: 106.6985)

class UserLocation {
  // Vĩ độ (latitude), ví dụ 10.7756.
  final double latitude;

  // Kinh độ (longitude), ví dụ 106.6985.
  final double longitude;

  const UserLocation({required this.latitude, required this.longitude});

  @override
  String toString() => 'UserLocation($latitude, $longitude)';
}