// ------------------------------------------------------------
// routes/user.routes.js - Các API yêu cầu ĐĂNG NHẬP (protected),
// minh họa phân quyền PUBLIC / PROTECTED / ADMIN.
//
//   GET /api/user/profile  -> mọi user đã đăng nhập đều dùng được
//   GET /api/admin/users   -> CHỈ tài khoản role=admin
// ------------------------------------------------------------

import { Router } from 'express';
import { getProfile, listUsers } from '../controllers/user.controller.js';
import { authenticateToken, requireAdmin } from '../middlewares/auth.middleware.js';

const router = Router();

// PROTECTED: bất kỳ user nào đăng nhập đều xem được hồ sơ của mình.
router.get('/profile', authenticateToken, getProfile);

// ADMIN ONLY: chặn user thường bằng requireAdmin.
// Nếu user thường gọi -> HTTP 403 { success: false, message: 'Bạn không có quyền...' }
router.get('/admin/users', authenticateToken, requireAdmin, listUsers);

export default router;