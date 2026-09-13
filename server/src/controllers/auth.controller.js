// ------------------------------------------------------------
// controllers/auth.controller.js - Xử lý nghiệp vụ xác thực:
//   - POST /api/auth/register  : đăng ký tài khoản mới
//   - POST /api/auth/login     : đăng nhập, trả về JWT + user
//   - POST /api/auth/google    : đăng ký / đăng nhập nhanh bằng Google
//   - GET  /api/auth/me        : lấy thông tin user hiện tại (cần JWT)
//
// Dữ liệu được lưu qua Sequelize (models/User.js) vào bảng users
// của database BusGo. Mật khẩu LUÔN được băm bằng bcrypt,
// không bao giờ lưu dạng văn bản thô.
// ------------------------------------------------------------

import { Op } from 'sequelize';
import User from '../models/User.js';
import {
  comparePassword,
  generateRandomPassword,
  hashPassword,
} from '../utils/password.util.js';
import { failure, success } from '../utils/response.util.js';
import { isGoogleAuthConfigured, verifyGoogleIdToken } from '../utils/google.util.js';
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
  // Dữ liệu đã được validate.middleware kiểm tra và chuẩn hóa trước đó.
  const { username, password } = req.body;
  const email = req.body.email || null;
  const name = req.body.name || username;

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
  // Dữ liệu đã được validate.middleware kiểm tra và chuẩn hóa trước đó.
  const { identifier, password } = req.body;

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
// ĐĂNG KÝ / ĐĂNG NHẬP NHANH BẰNG GOOGLE.
// Nhận:  { idToken }  (ID token từ app Flutter sau khi chọn tài khoản Google)
// Xử lý:
//   - Xác minh token với Google (chữ ký + aud + email_verified).
//   - Đã có tài khoản theo google_id   -> đăng nhập luôn (trả JWT).
//   - Có tài khoản trùng email         -> liên kết google_id -> đăng nhập.
//   - Chưa có tài khoản nào            -> tự tạo mới (username sinh tự động,
//     mật khẩu ngẫu nhiên bí mật, không cần người dùng nhập).
// Trả về: { success, message, token, user }
// ------------------------------------------------------------
export async function googleLogin(req, res) {
  const { idToken } = req.body || {};

  // Bước 0: kiểm tra dữ liệu cơ bản + server đã cấu hình Google chưa.
  if (!idToken || typeof idToken !== 'string' || idToken.length < 20) {
    return failure(res, 'Thiếu idToken hợp lệ từ Google', 400);
  }
  if (!isGoogleAuthConfigured()) {
    return failure(res, 'Máy chủ chưa cấu hình GOOGLE_CLIENT_ID để đăng nhập bằng Google', 500);
  }

  // Bước 1: xác minh token với Google (token giả/đã hết hạn -> bị từ chối).
  let payload;
  try {
    payload = await verifyGoogleIdToken(idToken);
  } catch (err) {
    console.error('[Lỗi xác thực Google]', err.message);
    return failure(res, 'Xác thực Google không thành công, vui lòng thử lại', 401);
  }

  const googleId = String(payload.sub || '');
  const email = (payload.email || '').trim();
  if (!googleId || !email) {
    return failure(res, 'Tài khoản Google của bạn không có email hợp lệ', 400);
  }
  const googleName = (payload.name || '').trim();

  try {
    // Bước 2: tìm tài khoản đã liên kết Google (theo google_id), nếu không
    // tìm theo email (tài khoản đăng ký thủ công trước đó).
    let user = await User.findOne({ where: { googleId } });
    if (!user) {
      user = await User.findOne({ where: { email } });
    }

    let created = false;

    if (!user) {
      // Bước 3a: chưa có tài khoản -> TỰ ĐĂNG KÝ bằng thông tin Google.
      const username = await generateUniqueUsername(email);
      // Mật khẩu ngẫu nhiên: người dùng Google không đặt mật khẩu,
      // nhưng bảng users yêu cầu password NOT NULL nên cần giá trị hợp lệ.
      const hashedPassword = await hashPassword(generateRandomPassword());

      user = await User.create({
        username,
        email,
        name: truncateName(googleName) || username,
        password: hashedPassword,
        googleId,
        role: 'user',
      });
      created = true;
    } else if (!user.googleId) {
      // Bước 3b: tài khoản trùng email -> liên kết Google ID vào lần đầu.
      user.googleId = googleId;
      await user.save();
    }

    // Bước 4: tạo JWT giống đăng nhập thường, đi thẳng vào tài khoản.
    const token = signToken(user);
    const message = created
      ? 'Đăng ký tài khoản bằng Google thành công'
      : 'Đăng nhập bằng Google thành công';
    return success(res, { token, user: publicUser(user) }, message, created ? 201 : 200);
  } catch (err) {
    // Trùng google_id/email khi gửi đồng thời (hiếm gặp).
    if (err.name === 'SequelizeUniqueConstraintError') {
      return failure(res, 'Tài khoản Google này đã được liên kết với tài khoản khác', 409);
    }
    return failure(res, dbError(err), 500);
  }
}

// Tạo tên đăng nhập (username) duy nhất từ email Google.
// Ví dụ: "nguyenvana@gmail.com" -> thử "nguyenvana", đã có -> "nguyenvana1"...
async function generateUniqueUsername(email) {
  // Lấy phần trước @, bỏ ký tự đặc biệt/dấu tiếng Việt.
  let base = (email.split('@')[0] || '')
    .toLowerCase()
    .replace(/[^a-z0-9_]/g, '');
  if (base.length < 3) {
    base = 'user';
  }
  base = base.slice(0, 32);

  let candidate = base;
  let suffix = 0;
  // Tăng hậu tố 1, 2, 3... cho đến khi tên chưa bị ai dùng.
  while (suffix < 100000) {
    const exists = await User.findOne({ where: { username: candidate } });
    if (!exists) return candidate;
    suffix++;
    candidate = (base.slice(0, 32 - String(suffix).length) + suffix);
  }
  // Hiếm khi rơi vào đây: dùng thêm timestamp để chắc chắn duy nhất.
  return base.slice(0, 24) + Date.now().toString().slice(-8);
}

// Giới hạn tên hiển thị theo cột name VARCHAR(50) của bảng users.
function truncateName(name) {
  if (!name) return '';
  return name.slice(0, 50);
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

// Chuyển lỗi Sequelize thành thông điệp thân thiện.
function dbError(err) {
  console.error('[Lỗi cơ sở dữ liệu]', err);
  return 'Lỗi cơ sở dữ liệu, vui lòng thử lại sau';
}