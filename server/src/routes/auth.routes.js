// ------------------------------------------------------------
// routes/auth.routes.js - Các đường dẫn xác thực tài khoản.
//
//   POST /api/auth/register  -> PUBLIC  : đăng ký tài khoản
//   POST /api/auth/login     -> PUBLIC  : đăng nhập (trả JWT)
//   POST /api/auth/google    -> PUBLIC  : đăng ký/đăng nhập nhanh bằng Google
//   GET  /api/auth/me        -> PROTECTED: thông tin user hiện tại
// ------------------------------------------------------------

import { Router } from 'express';
import {
  googleLogin,
  login,
  me,
  register,
} from '../controllers/auth.controller.js';
import { authenticateToken } from '../middlewares/auth.middleware.js';
import { validateLogin, validateRegister } from '../middlewares/validate.middleware.js';

// Tạo router riêng cho nhóm xác thực.
const router = Router();

// PUBLIC: đăng ký tài khoản (validate trước khi vào controller).
router.post('/register', validateRegister, register);

// PUBLIC: đăng nhập (validate trước khi vào controller).
router.post('/login', validateLogin, login);

// PUBLIC: đăng nhập/đăng ký nhanh bằng Google (idToken tự xác minh ở controller).
router.post('/google', googleLogin);

// PROTECTED: cần JWT qua middleware authenticateToken.
router.get('/me', authenticateToken, me);

export default router;