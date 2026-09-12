// ------------------------------------------------------------
// routes/bus.routes.js - API cập nhật vị trí XE BUÝT.
//
//   POST /api/buses/:busId/location -> cập nhật vị trí (cần admin)
// ------------------------------------------------------------

import { Router } from 'express';
import { updateBusLocation } from '../controllers/bus.controller.js';
import { authenticateToken, requireAdmin } from '../middlewares/auth.middleware.js';

const router = Router();

// Cập nhật vị trí là thao tác nghiệp vụ -> yêu cầu đăng nhập và quyền admin.
router.post('/:busId/location', authenticateToken, requireAdmin, updateBusLocation);

export default router;
