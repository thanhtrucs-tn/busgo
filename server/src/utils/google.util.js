// ------------------------------------------------------------
// utils/google.util.js - Xác thực token của "Đăng nhập bằng Google".
//
// App Flutter dùng google_sign_in lấy một ID Token của Google gửi lên
// server (POST /api/auth/google). Server KHÔNG tin tưởng app mù quáng,
// mà xác minh token với chính Google qua google-auth-library:
//   1. Kiểm tra chữ ký token bằng khóa công khai của Google.
//   2. Kiểm tra "aud" (khách hàng) có thuộc danh sách client ID
//      cấu hình trong .env (GOOGLE_CLIENT_ID).
//   3. Đọc payload: sub (mã Google), email, name, ...
// ------------------------------------------------------------

import { OAuth2Client } from 'google-auth-library';

// Client dùng chung để xác minh ID token (dùng bộ nhớ cache chứng chỉ Google).
const authClient = new OAuth2Client();

// Danh sách client ID (web app) được phép ký token.
// Đọc từ .env: GOOGLE_CLIENT_ID (một hoặc nhiều, phân cách bằng dấu phẩy).
function allowedClientIds() {
  const raw = (process.env.GOOGLE_CLIENT_ID || '').trim();
  if (!raw) return [];
  return raw
    .split(',')
    .map((id) => id.trim())
    .filter(Boolean);
}

// Xác minh ID token của Google.
// Thành công -> trả về payload đã được xác thực.
// Thất bại   -> ném lỗi (người gọi tự bắt và trả lỗi 401 thân thiện).
export async function verifyGoogleIdToken(idToken) {
  const audiences = allowedClientIds();
  if (audiences.length === 0) {
    throw new Error('GOOGLE_CLIENT_ID chưa được cấu hình trong .env');
  }

  const ticket = await authClient.verifyIdToken({
    idToken,
    audience: audiences, // aud của token phải khớp 1 trong danh sách này
  });

  const payload = ticket.getPayload();
  if (!payload) {
    throw new Error('ID token không có dữ liệu hợp lệ');
  }

  // Email phải được Google xác nhận mới dùng để tạo tài khoản.
  if (payload.email_verified !== true) {
    throw new Error('Email của tài khoản Google chưa được xác minh');
  }

  return payload;
}

// Kiểm tra server đã sẵn sàng cho đăng nhập Google chưa.
export function isGoogleAuthConfigured() {
  return allowedClientIds().length > 0;
}