// google_config.dart
// Cấu hình Google OAuth cho tính năng "Đăng ký / Đăng nhập nhanh bằng Google".
//
// CÁCH TẠO CLIENT ID (Google Cloud Console):
//   1. Vào https://console.cloud.google.com -> tạo/Chọn project.
//   2. Menu: APIs & Services -> Credentials -> "Create Credentials"
//      -> "OAuth client ID".
//   3. Tạo 2 loại:
//      a) "Web application"  -> lấy WEB_CLIENT_ID
//         (server backend dùng client ID này để xác minh token).
//      b) "Android" (package com.example.busgo + SHA-1 chứng chỉ ký)
//         -> lấy ANDROID_CLIENT_ID.
//      -> Cả 2 phải cùng thuộc một Google Cloud project.
//   4. Điền WEB_CLIENT_ID xuống dưới, đồng thời điền GIỐNG HỆT vào
//      GOOGLE_CLIENT_ID trong server/.env (bắt buộc, server mới xác
//      minh được token).
//   5. Với web/index.html: thay client ID trong thẻ meta
//      google-signin-client_id bằng WEB_CLIENT_ID.
class GoogleConfig {
  // Lớp tĩnh: không cho phép khởi tạo đối tượng.
  GoogleConfig._();

  // Client ID loại "Web application" (bắt buộc, dùng cho mọi nền tảng
  // và để server xác minh token qua GOOGLE_CLIENT_ID trong .env).
  static const String webClientId = '';

  // Client ID loại "Android" (tùy chọn trên Android, để trống nếu không có).
  static const String androidClientId = '';
}