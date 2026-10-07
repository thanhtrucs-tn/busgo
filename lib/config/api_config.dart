
class ApiConfig {
  // Lớp tĩnh: không cho phép khởi tạo đối tượng.
  ApiConfig._();

  // Địa chỉ gốc của REST API (backend Node.js + MySQL).
  // Đọc từ biến môi trường lúc build, mặc định trỏ về localhost.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );


  static String get socketBaseUrl {
    if (baseUrl.endsWith('/api')) {
      return baseUrl.substring(0, baseUrl.length - '/api'.length);
    }
    return baseUrl;
  }
}
