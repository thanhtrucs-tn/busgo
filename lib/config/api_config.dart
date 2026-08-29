// api_config.dart
// Cấu hình địa chỉ máy chủ API cho toàn bộ ứng dụng.
//
// LƯU Ý quan trọng khi chạy thử:
//  - Máy thật / Windows / Web:  http://localhost:3000/api
//  - Android Emulator: phải đổi thành http://10.0.2.2:3000/api
//    (vì 10.0.2.2 trỏ về localhost của máy tính chạy emulator)
//  - Điện thoại thật: đổi thành IP LAN của máy chạy API, ví dụ http://192.168.1.10:3000/api

class ApiConfig {
  // Lớp tĩnh: không cho phép khởi tạo đối tượng.
  ApiConfig._();

  // Địa chỉ gốc của API (backend Node.js + MySQL).
  static const String baseUrl = 'http://localhost:3000/api';
}
