// ------------------------------------------------------------
// Controller xử lý nghiệp vụ đăng ký và đăng nhập.
// Mỗi controller nhận request, gọi cơ sở dữ liệu MySQL,
// rồi trả về phản hồi JSON theo định dạng chuẩn.
// ------------------------------------------------------------

import { pool } from '../config/db.js';
import { comparePassword, hashPassword } from '../utils/password.util.js';
import { dbErrorMessage, failure, success } from '../utils/response.util.js';

// ------------------------------------------------------------
// Chức năng ĐĂNG KÝ tài khoản mới.
// Nhận:  { username, password }
// Trả về: { success: true, message, data: { username } }
// ------------------------------------------------------------
export async function register(req, res) {
  const { username, password } = req.body;

  try {
    // Bước 1: kiểm tra tên đăng nhập đã tồn tại chưa.
    // Khóa duy nhất (uk_username) trong MySQL cũng chặn trường hợp trùng.
    const [rows] = await pool.query(
      'SELECT id FROM users WHERE username = ? LIMIT 1',
      [username],
    );
    if (rows.length > 0) {
      return failure(res, 'Tên đăng nhập đã tồn tại, vui lòng chọn tên khác', 409);
    }

    // Bước 2: mã hóa mật khẩu bằng bcrypt (không lưu văn bản thô).
    const hashedPassword = await hashPassword(password);

    // Bước 3: lưu tài khoản mới vào database TEST_123.
    await pool.query(
      'INSERT INTO users (username, password) VALUES (?, ?)',
      [username, hashedPassword],
    );

    // Bước 4: trả về kết quả thành công (không trả mật khẩu).
    return success(res, { username }, 'Đăng ký tài khoản thành công', 201);
  } catch (err) {
    // Xử lý lỗi trùng khóa duy nhất và các lỗi cơ sở dữ liệu khác.
    return failure(res, dbErrorMessage(err), 500);
  }
}

// ------------------------------------------------------------
// Chức năng ĐĂNG NHẬP.
// Nhận:  { username, password }
// Trả về: { success: true, message, data: { id, username } }
// ------------------------------------------------------------
export async function login(req, res) {
  const { username, password } = req.body;

  try {
    // Bước 1: tìm tài khoản theo tên đăng nhập.
    const [rows] = await pool.query(
      'SELECT id, username, password FROM users WHERE username = ? LIMIT 1',
      [username],
    );

    // Không tìm thấy tài khoản -> trả lỗi chung (không tiết lộ tài khoản tồn tại).
    if (rows.length === 0) {
      return failure(res, 'Tên đăng nhập hoặc mật khẩu không đúng', 401);
    }

    const user = rows[0];

    // Bước 2: so sánh mật khẩu đã nhập với chuỗi bcrypt trong database.
    const isMatch = await comparePassword(password, user.password);
    if (!isMatch) {
      return failure(res, 'Tên đăng nhập hoặc mật khẩu không đúng', 401);
    }

    // Bước 3: đăng nhập thành công, trả thông tin tài khoản (không kèm mật khẩu).
    return success(
      res,
      { id: user.id, username: user.username },
      'Đăng nhập thành công',
    );
  } catch (err) {
    return failure(res, dbErrorMessage(err), 500);
  }
}