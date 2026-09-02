// ------------------------------------------------------------
// middlewares/auth.middleware.js - Xác thực JWT cho API.
//
// Quy trình authenticateToken (7 bước theo yêu cầu):
//   1. Kiểm tra header Authorization có tồn tại hay không.
//   2. Kiểm tra token có được gửi kèm hay không.
//   3. Verify JWT (đúng chữ ký, chưa hết hạn).
//   4. Lấy userId từ payload của token.
//   5. Tìm user trong database (đảm bảo tài khoản còn tồn tại).
//   6. Gắn user vào req.user.
//   7. Cho phép request tiếp tục (next()).
//
// Ví dụ header hợp lệ:
//   Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
// ------------------------------------------------------------

import User from '../models/User.js';
import { failure } from '../utils/response.util.js';
import { verifyToken } from '../utils/jwt.util.js';

// Middleware chặn request chưa đăng nhập.
// Dùng cho các API yêu cầu tài khoản (protected).
export async function authenticateToken(req, res, next) {
  try {
    // Bước 1 + 2: đọc header "Authorization: Bearer <token>".
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      // Không gửi token -> 401 với thông báo "Vui lòng đăng nhập".
      return failure(res, 'Vui lòng đăng nhập', 401);
    }

    const token = authHeader.split(' ')[1];

    // Bước 3: verify JWT (sai chữ ký / hết hạn đều ném lỗi).
    const payload = verifyToken(token);

    // Bước 4 + 5: tìm user theo id trong payload.
    const user = await User.findByPk(payload.id);
    if (!user) {
      // Token hợp lệ nhưng tài khoản đã bị xóa -> coi như không hợp lệ.
      return failure(res, 'Token không hợp lệ hoặc đã hết hạn', 401);
    }

    // Bước 6: gắn user vào req.user cho controller phía sau dùng.
    req.user = user;

    // Bước 7: hợp lệ -> cho phép xử lý tiếp.
    return next();
  } catch (err) {
    // Token sai, bị chỉnh sửa hoặc đã hết hạn.
    return failure(res, 'Token không hợp lệ hoặc đã hết hạn', 401);
  }
}

// Middleware kiểm tra QUYỀN QUẢN TRỊ (admin).
// PHẢI đặt SAU authenticateToken (vì cần req.user).
// Ví dụ: router.get('/admin/users', authenticateToken, requireAdmin, listUsers);
export function requireAdmin(req, res, next) {
  if (req.user && req.user.role === 'admin') {
    return next();
  }
  // User thường không được vào API quản trị.
  return failure(res, 'Bạn không có quyền truy cập tính năng này', 403);
}