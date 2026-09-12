// ------------------------------------------------------------
// utils/jwt.util.js - Tạo và kiểm tra JWT (JSON Web Token).
//
// JWT là "vé" xác thực: sau khi đăng nhập, server ký một token
// chứa id + role của user; Flutter gửi token này kèm mỗi request
// để chứng minh "tôi là ai" mà không cần gửi lại mật khẩu.
//
// BẢO MẬT: khóa bí mật JWT_SECRET bắt buộc lấy từ .env,
// KHÔNG được hard-code trong source code.
// ------------------------------------------------------------

import jwt from 'jsonwebtoken';

// Kiểm tra JWT_SECRET có tồn tại hay không.
// Nếu thiếu -> dừng server ngay với thông báo rõ ràng (tránh chạy thiếu an toàn).
export function requireJwtSecret() {
  const secret = process.env.JWT_SECRET;
  if (!secret || secret.trim() === '') {
    console.error(
      '[LỖI] Thiếu biến môi trường JWT_SECRET trong file .env.\n' +
        'Ví dụ: JWT_SECRET=mot_chuoi_khoa_bi_mat_rat_dai',
    );
    process.exit(1);
  }
  return secret;
}

// Ký (tạo) một JWT mới cho user.
// payload gồm: userId, username, role -> sau này middleware đọc lại được.
// Giữ thêm 'id' để tương thích với token cũ đã phát hành trước đây.
// Trả về chuỗi token, ví dụ: eyJhbGciOiJIUzI1NiIs...
export function signToken(user) {
  const secret = requireJwtSecret();
  const expiresIn = process.env.JWT_EXPIRES_IN || '7d'; // Mặc định hết hạn sau 7 ngày

  return jwt.sign(
    { userId: user.id, id: user.id, username: user.username, role: user.role },
    secret,
    { expiresIn },
  );
}

// Kiểm tra (verify) một token.
// - Hợp lệ   -> trả về payload (id, username, role, ...)
// - Sai/hết hạn -> ném lỗi, middleware sẽ bắt và trả 401.
export function verifyToken(token) {
  const secret = requireJwtSecret();
  return jwt.verify(token, secret);
}