// ------------------------------------------------------------
// Định nghĩa các đường dẫn (routes) của nhóm xác thực tài khoản.
// Cấu trúc:
//   POST /api/auth/register  -> đăng ký tài khoản mới
//   POST /api/auth/login     -> đăng nhập
// ------------------------------------------------------------

import { Router } from 'express';
import { login, register } from '../controllers/auth.controller.js';
import { validateLogin, validateRegister } from '../middlewares/validate.middleware.js';

// Tạo router riêng cho nhóm xác thực.
const router = Router();

// Đăng ký tài khoản: dữ liệu được kiểm tra trước khi vào controller.
router.post('/register', validateRegister, register);

// Đăng nhập: dữ liệu được kiểm tra trước khi vào controller.
router.post('/login', validateLogin, login);

export default router;