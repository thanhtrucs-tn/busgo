

class UserLocation {
  // Vĩ độ (latitude), ví dụ 10.7756.
  final double latitude;

  // Kinh độ (longitude), ví dụ 106.6985.
  final double longitude;

  const UserLocation({required this.latitude, required this.longitude});

  @override
  String toString() => 'UserLocation($latitude, $longitude)';
}
