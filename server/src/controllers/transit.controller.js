// ------------------------------------------------------------
// controllers/transit.controller.js - Xử lý nghiệp vụ tuyến & trạm.
//
// API cung cấp (đi qua routers route.routes.js / stop.routes.js):
//   GET /api/routes
//   GET /api/routes/:routeId
//   GET /api/routes/:routeId/stops   (?direction=0|1)
//   GET /api/routes/:routeId/path    (?direction=0|1)
//   GET /api/stops
//   GET /api/stops/:stopId
//
// Mọi phản hồi theo format chuẩn: { success, message, data }.
// Validate tham số đầu vào, trả status phù hợp, KHÔNG trả stack trace.
// ------------------------------------------------------------

import Route from '../models/Route.js';
import Stop from '../models/Stop.js';
import RouteStop from '../models/RouteStop.js';
import RoutePoint from '../models/RoutePoint.js';
import Bus from '../models/Bus.js';
import BusLocation from '../models/BusLocation.js';
import { failure, success } from '../utils/response.util.js';
import {
  haversineMeters,
  nearestPointIndex,
  pathDistanceMeters,
} from '../utils/geo.util.js';

// Hàm cấp phát: đọc routeId/direction từ tham số và kiểm tra hợp lệ.
// Nếu lỗi -> trả failure và ngừng; nếu ok -> gọi callback với routeId, direction.
function withRouteParams(req, res, callback) {
  const routeId = Number(req.params.routeId);
  if (!Number.isInteger(routeId) || routeId <= 0) {
    return failure(res, 'Mã tuyến không hợp lệ', 400);
  }

  // Direction mặc định = 0 (chiều đi). Chỉ chấp nhận 0 hoặc 1.
  let direction = 0;
  if (req.query.direction !== undefined) {
    direction = Number(req.query.direction);
    if (!Number.isInteger(direction) || (direction !== 0 && direction !== 1)) {
      return failure(res, 'Chiều đi/về không hợp lệ (chỉ nhận 0 hoặc 1)', 400);
    }
  }

  return callback(routeId, direction);
}

// ------------------------------------------------------------
// Danh sách tuyến xe buýt.
// GET /api/routes
// ------------------------------------------------------------
export async function listRoutes(req, res) {
  try {
    const routes = await Route.findAll({
      order: [['routeCode', 'ASC']],
    });

    // Đếm số trạm của mỗi tuyến ở chiều đi (direction = 0) bằng MỘT truy vấn.
    const routeStops = await RouteStop.findAll({
      where: { direction: 0 },
      attributes: ['routeId', 'stopId'],
    });
    const stopCountByRoute = {};
    for (const rs of routeStops) {
      stopCountByRoute[rs.routeId] = (stopCountByRoute[rs.routeId] || 0) + 1;
    }

    const data = routes.map((r) => ({
      ...publicRoute(r),
      stopCount: stopCountByRoute[r.id] || 0,
    }));
    return success(res, data, 'Lấy danh sách tuyến thành công');
  } catch (err) {
    console.error('[Lỗi danh sách tuyến]', err.message);
    return failure(res, 'Lỗi lấy danh sách tuyến, vui lòng thử lại sau', 500);
  }
}

// ------------------------------------------------------------
// Chi tiết một tuyến.
// GET /api/routes/:routeId
// ------------------------------------------------------------
export async function getRoute(req, res) {
  return withRouteParams(req, res, async (routeId) => {
    try {
      const route = await Route.findByPk(routeId);
      if (!route) {
        return failure(res, 'Không tìm thấy tuyến xe buýt', 404);
      }
      const stopCount = await RouteStop.count({
        where: { routeId, direction: 0 },
      });
      return success(
        res,
        { ...publicRoute(route), stopCount },
        'Lấy thông tin tuyến thành công',
      );
    } catch (err) {
      console.error('[Lỗi chi tiết tuyến]', err.message);
      return failure(res, 'Lỗi lấy thông tin tuyến, vui lòng thử lại sau', 500);
    }
  });
}

// ------------------------------------------------------------
// Danh sách trạm của một tuyến (theo chiều, sắp theo stop_order).
// GET /api/routes/:routeId/stops?direction=0
// ------------------------------------------------------------
export async function getRouteStops(req, res) {
  return withRouteParams(req, res, async (routeId, direction) => {
    try {
      const route = await Route.findByPk(routeId);
      if (!route) {
        return failure(res, 'Không tìm thấy tuyến xe buýt', 404);
      }

      // Lấy các dòng route_stops của chiều đó, kèm thông tin trạm.
      const routeStops = await RouteStop.findAll({
        where: { routeId, direction },
        include: [{ model: Stop, attributes: ['id', 'stopCode', 'stopName', 'address', 'latitude', 'longitude'] }],
        order: [['stopOrder', 'ASC']],
      });

      // Chuẩn hóa mỗi trạm: gộp thông tin trạm + thứ tự + thời gian ~.
      const data = routeStops.map((rs) => ({
        stop: rs.Stop ? publicStop(rs.Stop) : null,
        direction: rs.direction,
        stopOrder: rs.stopOrder,
        estimatedMinutesFromStart: rs.estimatedMinutesFromStart,
      }));

      return success(res, data, 'Lấy danh sách trạm của tuyến thành công');
    } catch (err) {
      console.error('[Lỗi danh sách trạm tuyến]', err.message);
      return failure(res, 'Lỗi lấy danh sách trạm, vui lòng thử lại sau', 500);
    }
  });
}

// ------------------------------------------------------------
// Đường đi (polyline) của tuyến - tọa độ chi tiết bám đường thật.
// GET /api/routes/:routeId/path?direction=0
// ------------------------------------------------------------
export async function getRoutePath(req, res) {
  return withRouteParams(req, res, async (routeId, direction) => {
    try {
      const route = await Route.findByPk(routeId);
      if (!route) {
        return failure(res, 'Không tìm thấy tuyến xe buýt', 404);
      }

      const points = await RoutePoint.findAll({
        where: { routeId, direction },
        attributes: ['id', 'latitude', 'longitude', 'pointOrder'],
        order: [['pointOrder', 'ASC']],
      });

      if (points.length < 2) {
        // Tuyến chưa có dữ liệu polyline -> trả danh sách rỗng (không lỗi).
        return success(res, [], 'Tuyến này chưa có dữ liệu đường đi');
      }

      const data = points.map((p) => ({
        latitude: p.latitude,
        longitude: p.longitude,
        pointOrder: p.pointOrder,
      }));

      return success(res, data, 'Lấy đường đi của tuyến thành công');
    } catch (err) {
      console.error('[Lỗi đường đi tuyến]', err.message);
      return failure(res, 'Lỗi lấy đường đi tuyến, vui lòng thử lại sau', 500);
    }
  });
}

// ------------------------------------------------------------
// Danh sách trạm (toàn hệ thống), có thể lọc theo từ khóa q.
// GET /api/stops?q=Tên
// ------------------------------------------------------------
export async function listStops(req, res) {
  try {
    const q = (req.query.q || '').trim();
    const where = { status: 'active' };

    // Nếu có từ khóa, lọc theo tên hoặc địa chỉ (không phân biệt hoa/thường).
    if (q) {
      const { Op } = await import('sequelize');
      where[Op.or] = [
        { stopName: { [Op.like]: `%${q}%` } },
        { address: { [Op.like]: `%${q}%` } },
      ];
    }

    const stops = await Stop.findAll({ where, order: [['stopName', 'ASC']] });

    // Đếm số tuyến khác nhau đi qua mỗi trạm bằng MỘT truy vấn.
    const routeStops = await RouteStop.findAll({
      attributes: ['stopId', 'routeId'],
    });
    const routesByStop = {};
    for (const rs of routeStops) {
      if (!routesByStop[rs.stopId]) routesByStop[rs.stopId] = new Set();
      routesByStop[rs.stopId].add(rs.routeId);
    }

    const data = stops.map((s) => ({
      ...publicStop(s),
      routeCount: routesByStop[s.id] ? routesByStop[s.id].size : 0,
    }));
    return success(res, data, 'Lấy danh sách trạm thành công');
  } catch (err) {
    console.error('[Lỗi danh sách trạm]', err.message);
    return failure(res, 'Lỗi lấy danh sách trạm, vui lòng thử lại sau', 500);
  }
}

// ------------------------------------------------------------
// Chi tiết một trạm + các tuyến đi qua trạm.
// GET /api/stops/:stopId
// ------------------------------------------------------------
export async function getStopDetail(req, res) {
  const stopId = Number(req.params.stopId);
  if (!Number.isInteger(stopId) || stopId <= 0) {
    return failure(res, 'Mã trạm không hợp lệ', 400);
  }

  try {
    const stop = await Stop.findByPk(stopId);
    if (!stop) {
      return failure(res, 'Không tìm thấy trạm xe buýt', 404);
    }

    // Các routes đi qua trạm này (qua route_stops), kèm chiều + thứ tự.
    const routeStops = await RouteStop.findAll({
      where: { stopId },
      include: [{ model: Route }],
      order: [['direction', 'ASC'], ['stopOrder', 'ASC']],
    });

    const routes = routeStops.map((rs) => ({
      route: rs.Route ? publicRoute(rs.Route) : null,
      direction: rs.direction,
      stopOrder: rs.stopOrder,
    }));

    return success(
      res,
      { stop: publicStop(stop), routes },
      'Lấy thông tin trạm thành công',
    );
  } catch (err) {
    console.error('[Lỗi chi tiết trạm]', err.message);
    return failure(res, 'Lỗi lấy thông tin trạm, vui lòng thử lại sau', 500);
  }
}

// ------------------------------------------------------------
// Các tuyến đi qua một trạm (gồm cả chiều đi và chiều về).
// GET /api/stops/:stopId/routes
// ------------------------------------------------------------
export async function getStopRoutes(req, res) {
  const stopId = Number(req.params.stopId);
  if (!Number.isInteger(stopId) || stopId <= 0) {
    return failure(res, 'Mã trạm không hợp lệ', 400);
  }

  try {
    const stop = await Stop.findByPk(stopId);
    if (!stop) {
      return failure(res, 'Không tìm thấy trạm xe buýt', 404);
    }

    const routeStops = await RouteStop.findAll({
      where: { stopId },
      include: [{ model: Route }],
      order: [['direction', 'ASC'], ['stopOrder', 'ASC']],
    });

    const routes = routeStops.map((rs) => ({
      route: rs.Route ? publicRoute(rs.Route) : null,
      direction: rs.direction,
      stopOrder: rs.stopOrder,
      estimatedMinutesFromStart: rs.estimatedMinutesFromStart,
    }));

    return success(res, routes, 'Lấy danh sách tuyến của trạm thành công');
  } catch (err) {
    console.error('[Lỗi tuyến của trạm]', err.message);
    return failure(res, 'Lỗi lấy danh sách tuyến của trạm, vui lòng thử lại sau', 500);
  }
}

// ------------------------------------------------------------
// Dự kiến xe sắp tới trạm.
// GET /api/stops/:stopId/arrivals
//
// Ước lượng CƠ BẢN (không phải dữ liệu giao thông thực tế):
//   1. Lấy chuỗi route_points của tuyến theo chiều đi qua trạm.
//   2. Tìm điểm gần nhất trên chuỗi với vị trí xe và với trạm.
//   3. Cộng khoảng cách các đoạn còn lại từ xe đến trạm.
//   4. Chia cho vận tốc hiện tại (nếu hợp lệ) hoặc vận tốc trung bình.
//   5. Cộng thêm thời gian dừng trung bình ở các trạm phía trước.
//   6. Bỏ qua xe đã đi qua trạm trong chiều đó hoặc vị trí quá cũ.
// ------------------------------------------------------------
export async function getStopArrivals(req, res) {
  const stopId = Number(req.params.stopId);
  if (!Number.isInteger(stopId) || stopId <= 0) {
    return failure(res, 'Mã trạm không hợp lệ', 400);
  }

  // Tham số ước lượng đọc từ .env (có giá trị mặc định an toàn).
  const avgSpeedKmh = Number(process.env.AVG_BUS_SPEED_KMH) || 20;
  const avgDwellMinutes = Number.isFinite(Number(process.env.AVG_DWELL_MINUTES))
    ? Number(process.env.AVG_DWELL_MINUTES)
    : 0.5;
  const staleSeconds = Number(process.env.BUS_STALE_SECONDS) || 300;

  try {
    const stop = await Stop.findByPk(stopId);
    if (!stop) {
      return failure(res, 'Không tìm thấy trạm xe buýt', 404);
    }

    const routeStops = await RouteStop.findAll({
      where: { stopId },
      include: [{ model: Route }],
      order: [['direction', 'ASC'], ['stopOrder', 'ASC']],
    });

    const now = Date.now();
    const arrivals = [];

    for (const rs of routeStops) {
      if (!rs.Route) continue;

      // Chuỗi tọa độ chi tiết của tuyến theo chiều này.
      const points = await RoutePoint.findAll({
        where: { routeId: rs.routeId, direction: rs.direction },
        attributes: ['latitude', 'longitude'],
        order: [['pointOrder', 'ASC']],
      });
      if (points.length < 2) continue;

      // Vị trí của trạm đích trên chuỗi điểm.
      const targetIndex = nearestPointIndex(
        points,
        stop.latitude,
        stop.longitude,
      );

      // Vị trí (theo chuỗi điểm) của mọi trạm trên cùng chiều, để đếm số trạm
      // nằm giữa xe và trạm đích (phục vụ cộng thời gian dừng).
      const sameDirectionStops = await RouteStop.findAll({
        where: { routeId: rs.routeId, direction: rs.direction },
        include: [{ model: Stop, attributes: ['latitude', 'longitude'] }],
      });
      const stopIndexes = sameDirectionStops
        .filter((item) => item.Stop)
        .map((item) =>
          nearestPointIndex(
            points,
            item.Stop.latitude,
            item.Stop.longitude,
          ),
        );

      const buses = await Bus.findAll({ where: { routeId: rs.routeId } });

      for (const bus of buses) {
        if (bus.status === 'INACTIVE') continue;

        const lastLocation = await BusLocation.findOne({
          where: { busId: bus.id },
          order: [['recordedAt', 'DESC']],
        });
        if (!lastLocation) continue;

        // Bỏ qua vị trí quá cũ.
        const ageSeconds =
          (now - new Date(lastLocation.recordedAt).getTime()) / 1000;
        if (ageSeconds > staleSeconds) continue;

        const busIndex = nearestPointIndex(
          points,
          lastLocation.latitude,
          lastLocation.longitude,
        );

        // Xe đã đi qua trạm trong chiều này -> không tính là "đang đến".
        if (busIndex >= targetIndex) continue;

        const distanceMeters = pathDistanceMeters(points, busIndex, targetIndex);

        // Xe đứng yên (speed <= 1) dùng vận tốc trung bình của tuyến.
        const speedKmh =
          Number(lastLocation.speed) > 1
            ? Number(lastLocation.speed)
            : avgSpeedKmh;

        const intermediateStops = stopIndexes.filter(
          (index) => index > busIndex && index < targetIndex,
        ).length;

        const travelMinutes = (distanceMeters / 1000 / speedKmh) * 60;
        const estimatedMinutes = Math.max(
          1,
          Math.round(travelMinutes + intermediateStops * avgDwellMinutes),
        );

        arrivals.push({
          route: publicRoute(rs.Route),
          direction: rs.direction,
          busId: bus.id,
          busCode: bus.busCode,
          status: bus.status,
          latitude: lastLocation.latitude,
          longitude: lastLocation.longitude,
          distanceMeters: Math.round(distanceMeters),
          estimatedMinutes,
          isSimulated: true,
          lastUpdatedAt: lastLocation.recordedAt,
        });
      }
    }

    // Một xe chỉ hiển thị một lần (giữ dự kiến gần nhất), tránh lặp giữa
    // hai chiều khi chưa có dữ liệu chiều đang chạy của xe.
    const byBus = new Map();
    for (const item of arrivals) {
      const existing = byBus.get(item.busId);
      if (!existing || item.estimatedMinutes < existing.estimatedMinutes) {
        byBus.set(item.busId, item);
      }
    }

    const data = [...byBus.values()].sort(
      (a, b) => a.estimatedMinutes - b.estimatedMinutes,
    );

    return success(res, data, 'Lấy dự kiến xe tới trạm thành công');
  } catch (err) {
    console.error('[Lỗi dự kiến xe tới trạm]', err.message);
    return failure(res, 'Lỗi lấy dự kiến xe tới trạm, vui lòng thử lại sau', 500);
  }
}

// ------------------------------------------------------------
// Tìm trạm gần vị trí người dùng (công thức Haversine).
// GET /api/stops/nearby?latitude=..&longitude=..&radius=2000
// ------------------------------------------------------------
export async function getNearbyStops(req, res) {
  const latitude = Number(req.query.latitude);
  const longitude = Number(req.query.longitude);
  const radius = req.query.radius === undefined ? 2000 : Number(req.query.radius);

  if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90) {
    return failure(res, 'Vĩ độ không hợp lệ (phải trong khoảng -90 đến 90)', 400);
  }
  if (!Number.isFinite(longitude) || longitude < -180 || longitude > 180) {
    return failure(res, 'Kinh độ không hợp lệ (phải trong khoảng -180 đến 180)', 400);
  }
  if (!Number.isFinite(radius) || radius <= 0 || radius > 50000) {
    return failure(res, 'Bán kính không hợp lệ (phải từ 0 đến 50000 mét)', 400);
  }

  try {
    const stops = await Stop.findAll({ where: { status: 'active' } });

    const nearby = stops
      .map((stop) => ({
        ...publicStop(stop),
        distanceMeters: Math.round(
          haversineMeters(latitude, longitude, stop.latitude, stop.longitude),
        ),
      }))
      .filter((stop) => stop.distanceMeters <= radius)
      .sort((a, b) => a.distanceMeters - b.distanceMeters)
      .slice(0, 20); // Giới hạn kết quả trả về cho gọn

    return success(res, nearby, 'Lấy danh sách trạm gần đây thành công');
  } catch (err) {
    console.error('[Lỗi trạm gần đây]', err.message);
    return failure(res, 'Lỗi lấy danh sách trạm gần đây, vui lòng thử lại sau', 500);
  }
}

// ------------------------------------------------------------
// Các hàm chuyển đổi model -> dữ liệu an toàn (bỏ trường nội bộ).
// ------------------------------------------------------------

function publicRoute(route) {
  return {
    id: route.id,
    routeCode: route.routeCode,
    routeName: route.routeName,
    startPoint: route.startPoint,
    endPoint: route.endPoint,
    color: route.color,
    startTime: route.startTime,
    endTime: route.endTime,
    frequencyMinutes: route.frequencyMinutes,
    fare: route.fare != null ? Number(route.fare) : null,
    status: route.status,
  };
}

function publicStop(stop) {
  return {
    id: stop.id,
    stopCode: stop.stopCode,
    stopName: stop.stopName,
    address: stop.address,
    latitude: stop.latitude,
    longitude: stop.longitude,
    status: stop.status,
  };
}

// Xuất thêm publicStop/publicRoute nếu cần dùng nơi khác.
export { publicRoute, publicStop };