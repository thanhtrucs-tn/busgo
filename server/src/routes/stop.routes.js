// ------------------------------------------------------------
// routes/stop.routes.js - Các API về TRẠM xe buýt.
//
//   GET /api/stops                    -> danh sách trạm (?q=từ khóa)
//   GET /api/stops/nearby             -> trạm gần vị trí (?latitude&longitude&radius)
//   GET /api/stops/:stopId            -> chi tiết trạm + các tuyến đi qua
//   GET /api/stops/:stopId/routes     -> các tuyến đi qua trạm
//   GET /api/stops/:stopId/arrivals   -> dự kiến xe sắp tới trạm
//
// LƯU Ý: '/nearby' phải khai báo TRƯỚC '/:stopId' để không bị hiểu nhầm
// 'nearby' là mã trạm.
// ------------------------------------------------------------

import { Router } from 'express';
import {
  getNearbyStops,
  getStopArrivals,
  getStopDetail,
  getStopRoutes,
  listStops,
} from '../controllers/transit.controller.js';

const router = Router();

router.get('/', listStops);
router.get('/nearby', getNearbyStops);
router.get('/:stopId', getStopDetail);
router.get('/:stopId/routes', getStopRoutes);
router.get('/:stopId/arrivals', getStopArrivals);

export default router;
