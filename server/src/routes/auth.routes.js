// ------------------------------------------------------------
// routes/auth.routes.js - Các đường dẫn xác thực tài khoản.
//
//   POST /api/auth/register  -> PUBLIC  : đăng ký tài khoản
//   POST /api/auth/login     -> PUBLIC  : đăng nhập (trả JWT)
//   GET  /api/auth/me        -> PROTECTED: thông tin user hiện tại
// ------------------------------------------------------------

import { Router } from 'express';
import { login, me, register } from '../controllers/auth.controller.js';
import { authenticateToken } from '../middlewares/auth.middleware.js';
import { validateLogin, validateRegister } from '../middlewares/validate.middleware.js';

// Tạo router riêng cho nhóm xác thực.
const router = Router();

// PUBLIC: đăng ký tài khoản (validate trước khi vào controller).
router.post('/register', validateRegister, register);

// PUBLIC: đăng nhập (validate trước khi vào controller).
router.post('/login', validateLogin, login);

// PROTECTED: cần JWT qua middleware authenticateToken.
router.get('/me', authenticateToken, me);

export default router;