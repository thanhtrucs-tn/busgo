// api_config.dart
// Cấu hình địa chỉ máy chủ API/Socket.IO cho toàn bộ ứng dụng.
//
// KHÔNG hardcode URL trong Widget. Toàn bộ địa chỉ tập trung tại đây và
// có thể ghi đè khi chạy mà không sửa code bằng --dart-define:
//
//   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
//
// Giá trị mặc định phù hợp khi chạy trên máy tính (Windows/Web/iOS simulator):
//   http://localhost:3000/api
//
// Gợi ý theo môi trường:
//   - Windows / Web / iOS simulator : http://localhost:3000/api
//   - Android Emulator              : http://10.0.2.2:3000/api
//     (10.0.2.2 trỏ về localhost của máy tính chạy emulator)
//   - Điện thoại thật               : http://<IP LAN>:3000/api
//     ví dụ http://192.168.1.10:3000/api

class ApiConfig {
  // Lớp tĩnh: không cho phép khởi tạo đối tượng.
  ApiConfig._();

  // Địa chỉ gốc của REST API (backend Node.js + MySQL).
  // Đọc từ biến môi trường lúc build, mặc định trỏ về localhost.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  // Địa chỉ gốc của Socket.IO = địa chỉ API bỏ hậu tố '/api'.
  // Socket.IO kết nối cùng cổng với REST API nhưng KHÔNG có tiền tố /api.
  static String get socketBaseUrl {
    if (baseUrl.endsWith('/api')) {
      return baseUrl.substring(0, baseUrl.length - '/api'.length);
    }
    return baseUrl;
  }
}
