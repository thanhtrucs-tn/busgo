// ------------------------------------------------------------
// Tiện ích mã hóa mật khẩu bằng bcrypt.
// Mật khẩu KHÔNG bao giờ được lưu dưới dạng văn bản thô trong
// cơ sở dữ liệu mà luôn được băm (hash) để bảo mật.
//
// Chuỗi bcrypt có độ dài 60 ký tự, vừa khớp với trường
// password VARCHAR(64) trong bảng users của database BusGo.
// ------------------------------------------------------------

import bcrypt from 'bcryptjs';
import crypto from 'node:crypto';

// Số vòng băm: càng cao càng khó bẻ khóa nhưng chậm hơn.
const SALT_ROUNDS = 10;

// Băm mật khẩu trước khi lưu vào database.
// Ví dụ: const hash = await hashPassword('matKhau123');
export async function hashPassword(plainPassword) {
  return bcrypt.hash(plainPassword, SALT_ROUNDS);
}

// So sánh mật khẩu người dùng nhập với chuỗi hash trong database.
// Trả về true nếu khớp, false nếu không khớp.
export async function comparePassword(plainPassword, hashedPassword) {
  return bcrypt.compare(plainPassword, hashedPassword);
}

// Sinh mật khẩu ngẫu nhiên KHÔNG THỂ ĐOÁN cho tài khoản đăng ký bằng Google.
// Người dùng đăng nhập bằng Google sẽ không cần biết mật khẩu này,
// nó chỉ tồn tại để bảng users (password NOT NULL) luôn hợp lệ.
export function generateRandomPassword() {
  return crypto.randomBytes(24).toString('hex'); // 48 ký tự hex
}