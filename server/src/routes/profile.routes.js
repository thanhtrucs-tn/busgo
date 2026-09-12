// ------------------------------------------------------------
// routes/profile.routes.js - API hồ sơ cá nhân (cần đăng nhập).
//
//   GET /api/profile/me -> lấy hồ sơ của chính mình
//   PUT /api/profile/me -> cập nhật hồ sơ của chính mình
//
// Hồ sơ được xác định theo JWT (req.user.id), không theo id trên URL/body.
// ------------------------------------------------------------

import { Router } from 'express';
import {
  getMyProfile,
  updateMyProfile,
} from '../controllers/profile.controller.js';
import { authenticateToken } from '../middlewares/auth.middleware.js';

const router = Router();

router.get('/me', authenticateToken, getMyProfile);
router.put('/me', authenticateToken, updateMyProfile);

export default router;
