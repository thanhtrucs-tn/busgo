
// controllers/user.controller.js - Các API liên quan đến tài khoản
// (đều là PROTECTED - phải có JWT hợp lệ):
//
//   GET /api/user/profile    : thông tin cá nhân của user hiện tại.
//   GET /api/admin/users     : danh sách tài khoản (chỉ dành cho ADMIN).
//
// Đây là ví dụ minh họa phân loại API:
//   - PUBLIC API   : đăng ký, đăng nhập, dữ liệu tuyến/trạm công khai.
//   - PROTECTED API: thông tin cá nhân, quản lý hồ sơ, yêu thích...
//   - ADMIN API    : chỉ role 'admin' được truy cập.


import User from '../models/User.js';
import { failure, success } from '../utils/response.util.js';

// Lấy hồ sơ cá nhân của user đang đăng nhập (từ req.user).
// Ví dụ request:
//   GET /api/user/profile
//   Authorization: Bearer <JWT_TOKEN>
export async function getProfile(req, res) {
  return success(
    res,
    {
      id: req.user.id,
      username: req.user.username,
      name: req.user.name,
      email: req.user.email,
      role: req.user.role,
      createdAt: req.user.createdAt,
    },
    'Lấy hồ sơ thành công',
  );
}

// Danh sách tất cả tài khoản - CHỈ DÀNH CHO ADMIN.
// Ví dụ request:
//   GET /api/admin/users
//   Authorization: Bearer <JWT_TOKEN của tài khoản role=admin>
export async function listUsers(req, res) {
  try {
    const users = await User.findAll({
      attributes: ['id', 'username', 'name', 'email', 'role', 'createdAt'],
      order: [['createdAt', 'DESC']], // Mới nhất trước
    });
    return success(res, users, `Tìm thấy ${users.length} tài khoản`);
  } catch (err) {
    console.error('[Lỗi danh sách user]', err);
    return failure(res, 'Lỗi cơ sở dữ liệu, vui lòng thử lại sau', 500);
  }
}