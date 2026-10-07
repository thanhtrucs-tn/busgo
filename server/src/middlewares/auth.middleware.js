

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

    // Bước 4 + 5: lấy định danh tài khoản từ payload token (KHÔNG lấy userId
    // do client gửi lên) rồi tìm user trong database.
    const userId = payload.userId ?? payload.id;
    const user = await User.findByPk(userId);
    if (!user) {
      // Token hợp lệ nhưng tài khoản đã bị xóa -> coi như không hợp lệ.
      return failure(res, 'Token không hợp lệ hoặc đã hết hạn', 401);
    }

    // Bước 6: gắn user đã xác thực vào req.user cho controller phía sau dùng.
    // Mọi API hồ sơ chỉ được dùng req.user.id, không tin userId trong body/query.
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