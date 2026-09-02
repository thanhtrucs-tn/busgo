// ------------------------------------------------------------
// controllers/auth.controller.js - Xử lý nghiệp vụ xác thực:
//   - POST /api/auth/register  : đăng ký tài khoản mới
//   - POST /api/auth/login     : đăng nhập, trả về JWT + user
//   - GET  /api/auth/me        : lấy thông tin user hiện tại (cần JWT)
//
// Dữ liệu được lưu qua Sequelize (models/User.js) vào bảng users
// của database TEST_123. Mật khẩu LUÔN được băm bằng bcrypt,
// không bao giờ lưu dạng văn bản thô.
// ------------------------------------------------------------

import { Op } from 'sequelize';
import User from '../models/User.js';
import { comparePassword, hashPassword } from '../utils/password.util.js';
import { failure, success } from '../utils/response.util.js';
import { signToken } from '../utils/jwt.util.js';

// ------------------------------------------------------------
// ĐĂNG KÝ tài khoản mới.
// Nhận:  { username, password, email?, name? }
//  - username: bắt buộc, 3-32 ký tự (giữ nguyên từ giai đoạn trước).
//  - password: bắt buộc, 6-64 ký tự.
//  - email   : tùy chọn, nếu nhập phải đúng định dạng và chưa tồn tại.
//  - name    : tùy chọn, mặc định bằng username.
// Trả về: { success, message, token, user }
// ------------------------------------------------------------
export async function register(req, res) {
  const { username, password } = req.body;
  const email = (req.body.email || '').trim() || null;
  const name = (req.body.name || '').trim() || username;

  // Bước 0: kiểm tra dữ liệu đầu vào (độ dài + định dạng) trước khi
  // làm việc với database - tránh lưu dữ liệu sai logic vào bảng users.
  const validationError = validateRegister({ username, password, email, name });
  if (validationError) {
    return failure(res, validationError, 400);
  }

  try {
    // Bước 1: kiểm tra tên đăng nhập đã tồn tại chưa.
    const existingUsername = await User.findOne({ where: { username } });
    if (existingUsername) {
      return failure(res, 'Tên đăng nhập đã tồn tại, vui lòng chọn tên khác', 409);
    }

    // Bước 2: nếu nhập email -> kiểm tra email đã được dùng chưa.
    if (email) {
      const existingEmail = await User.findOne({ where: { email } });
      if (existingEmail) {
        return failure(res, 'Email đã được sử dụng, vui lòng dùng email khác', 409);
      }
    }

    // Bước 3: băm mật khẩu bằng bcrypt (không lưu văn bản thô).
    const hashedPassword = await hashPassword(password);

    // Bước 4: lưu tài khoản mới vào database (Sequelize tự INSERT).
    const user = await User.create({
      username,
      email,
      password: hashedPassword,
      name,
      role: 'user', // Tài khoản mới luôn là user thường
    });

    // Bước 5: tạo JWT và trả về thông tin cần thiết (KHÔNG kèm mật khẩu).
    const token = signToken(user);
    // Trả token kèm theo để người dùng có thể đăng nhập luôn sau khi đăng ký.
    return success(res, { token, user: publicUser(user) }, 'Đăng ký tài khoản thành công', 201);
  } catch (err) {
    // Lỗi trùng khóa duy nhất trong database (xảy ra khi gửi đồng thời).
    if (err.name === 'SequelizeUniqueConstraintError') {
      return failure(res, 'Tên đăng nhập hoặc email đã tồn tại', 409);
    }
    return failure(res, dbError(err), 500);
  }
}

// ------------------------------------------------------------
// ĐĂNG NHẬP.
// Nhận:  { username | email, password }
//  - username: tên đăng nhập (tương thích giai đoạn trước).
//  - email   : HOẶC địa chỉ email.
// Kiểm tra mật khẩu bằng bcrypt, tạo JWT và trả về.
// Trả về: { success, message, token, user }
// ------------------------------------------------------------
export async function login(req, res) {
  const { password } = req.body;
  // Chấp nhận: identifier (tên HOẶC email), hoặc username, hoặc email.
  const identifier = req.body.identifier || req.body.username || req.body.email;

  // Bước 0: kiểm tra dữ liệu cơ bản trước khi truy vấn database.
  if (!identifier) {
    return failure(res, 'Vui lòng nhập tên đăng nhập hoặc email', 400);
  }
  if (!password) {
    return failure(res, 'Vui lòng nhập mật khẩu', 400);
  }
  if (password.length > 64) {
    return failure(res, 'Mật khẩu tối đa 64 ký tự', 400);
  }

  try {
    // Bước 1: tìm tài khoản theo tên đăng nhập HOẶC email.
    const user = await User.findOne({
      where: {
        [Op.or]: [{ username: identifier }, { email: identifier }],
      },
    });

    // Bước 2: không tìm thấy -> trả lỗi chung (không tiết lộ tài khoản tồn tại).
    if (!user) {
      return failure(res, 'Tên đăng nhập hoặc mật khẩu không đúng', 401);
    }

    // Bước 3: so sánh mật khẩu với chuỗi bcrypt trong database.
    const isMatch = await comparePassword(password, user.password);
    if (!isMatch) {
      return failure(res, 'Tên đăng nhập hoặc mật khẩu không đúng', 401);
    }

    // Bước 4: tạo JWT (hết hạn theo JWT_EXPIRES_IN, mặc định 7 ngày).
    const token = signToken(user);

    // Bước 5: trả token + thông tin user cần thiết.
    return success(res, { token, user: publicUser(user) }, 'Đăng nhập thành công');
  } catch (err) {
    return failure(res, dbError(err), 500);
  }
}

// ------------------------------------------------------------
// THÔNG TIN USER HIỆN TẠI (API protected - cần JWT).
// Đọc user từ req.user (đã được middleware authenticateToken xử lý),
// trả về thông tin an toàn (không kèm mật khẩu).
// ------------------------------------------------------------
export function me(req, res) {
  return success(res, publicUser(req.user), 'Lấy thông tin tài khoản thành công');
}

// Chuyển user thành dạng an toàn để gửi ra ngoài (bỏ password).
// Ví dụ: { id: 1, name: "Nguyễn Văn A", email: "a@vd.vn", username: "nguyenvana", role: "user" }
function publicUser(user) {
  return {
    id: user.id,
    username: user.username,
    name: user.name,
    email: user.email,
    role: user.role,
  };
}

// Kiểm tra dữ liệu đăng ký hợp lệ trước khi lưu vào database.
// Trả về null nếu hợp lệ, ngược lại trả thông báo lỗi tiếng Việt.
function validateRegister({ username, password, email, name }) {
  if (!username || username.length < 3 || username.length > 32) {
    return 'Tên đăng nhập phải có từ 3 đến 32 ký tự';
  }
  // Tên đăng nhập chỉ gồm chữ cái, số, gạch dưới (không dấu cách/ký tự đặc biệt).
  if (!/^[a-zA-Z0-9_]+$/.test(username)) {
    return 'Tên đăng nhập chỉ gồm chữ cái, số và dấu gạch dưới';
  }
  if (!password || password.length < 6 || password.length > 64) {
    return 'Mật khẩu phải có từ 6 đến 64 ký tự';
  }
  if (email) {
    if (email.length > 48) return 'Email tối đa 48 ký tự';
    if (!/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(email)) {
      return 'Email không đúng định dạng';
    }
  }
  if (name && name.length > 50) {
    return 'Tên hiển thị tối đa 50 ký tự';
  }
  return null;
}

// Chuyển lỗi Sequelize thành thông điệp thân thiện.
function dbError(err) {
  console.error('[Lỗi cơ sở dữ liệu]', err);
  return 'Lỗi cơ sở dữ liệu, vui lòng thử lại sau';
}