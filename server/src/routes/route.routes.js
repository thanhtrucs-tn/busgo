// ------------------------------------------------------------
// routes/route.routes.js - Các API về TUYẾN xe buýt.
//
//   GET /api/routes                 -> danh sách tuyến
//   GET /api/routes/:routeId        -> chi tiết tuyến
//   GET /api/routes/:routeId/stops  -> trạm của tuyến (?direction=0|1)
//   GET /api/routes/:routeId/path   -> polyline của tuyến (?direction=0|1)
//   GET /api/routes/:routeId/buses  -> xe của tuyến + vị trí mới nhất
// ------------------------------------------------------------

import { Router } from 'express';
import {
  getRoute,
  getRoutePath,
  getRouteStops,
  listRoutes,
} from '../controllers/transit.controller.js';
import { getRouteBuses } from '../controllers/bus.controller.js';

const router = Router();

router.get('/', listRoutes);
router.get('/:routeId', getRoute);
router.get('/:routeId/stops', getRouteStops);
router.get('/:routeId/path', getRoutePath);
router.get('/:routeId/buses', getRouteBuses);

export default router;