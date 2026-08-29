// ------------------------------------------------------------
// Tiện ích mã hóa mật khẩu bằng bcrypt.
// Mật khẩu KHÔNG bao giờ được lưu dưới dạng văn bản thô trong
// cơ sở dữ liệu mà luôn được băm (hash) để bảo mật.
//
// Chuỗi bcrypt có độ dài 60 ký tự, vừa khớp với trường
// password VARCHAR(64) trong bảng users của database TEST_123.
// ------------------------------------------------------------

import bcrypt from 'bcryptjs';

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