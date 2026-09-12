// ------------------------------------------------------------
// controllers/bus.controller.js - Xử lý nghiệp vụ XE BUÝT.
//
//   GET  /api/routes/:routeId/buses -> xe của tuyến + vị trí mới nhất
//   POST /api/buses/:busId/location -> cập nhật vị trí xe (admin)
//
// Sau khi lưu vị trí thành công, phát sự kiện Socket.IO tới phòng
// route:<routeId> để Flutter vẽ lại marker trên bản đồ.
// ------------------------------------------------------------

import Bus from '../models/Bus.js';
import BusLocation from '../models/BusLocation.js';
import Route from '../models/Route.js';
import { emitBusLocation, emitBusStatus } from '../realtime/socket.js';
import { failure, success } from '../utils/response.util.js';

// Gộp thông tin xe với vị trí mới nhất (nếu có) để trả cho Flutter.
function publicBus(bus, location) {
  return {
    id: bus.id,
    busCode: bus.busCode,
    licensePlate: bus.licensePlate,
    routeId: bus.routeId,
    status: bus.status,
    latitude: location ? location.latitude : null,
    longitude: location ? location.longitude : null,
    speed: location ? location.speed : null,
    heading: location ? location.heading : null,
    updatedAt: location ? location.recordedAt : null,
  };
}

// ------------------------------------------------------------
// Danh sách xe của một tuyến kèm vị trí mới nhất.
// GET /api/routes/:routeId/buses
// ------------------------------------------------------------
export async function getRouteBuses(req, res) {
  const routeId = Number(req.params.routeId);
  if (!Number.isInteger(routeId) || routeId <= 0) {
    return failure(res, 'Mã tuyến không hợp lệ', 400);
  }

  try {
    const route = await Route.findByPk(routeId);
    if (!route) {
      return failure(res, 'Không tìm thấy tuyến xe buýt', 404);
    }

    const buses = await Bus.findAll({ where: { routeId }, order: [['busCode', 'ASC']] });

    const data = [];
    for (const bus of buses) {
      const lastLocation = await BusLocation.findOne({
        where: { busId: bus.id },
        order: [['recordedAt', 'DESC']],
      });
      data.push(publicBus(bus, lastLocation));
    }

    return success(res, data, 'Lấy danh sách xe của tuyến thành công');
  } catch (err) {
    console.error('[Lỗi danh sách xe của tuyến]', err.message);
    return failure(res, 'Lỗi lấy danh sách xe, vui lòng thử lại sau', 500);
  }
}

// ------------------------------------------------------------
// Cập nhật vị trí mới nhất của một xe.
// POST /api/buses/:busId/location
// Body: { routeId, latitude, longitude, speed?, heading? }
// ------------------------------------------------------------
export async function updateBusLocation(req, res) {
  const busId = Number(req.params.busId);
  if (!Number.isInteger(busId) || busId <= 0) {
    return failure(res, 'Mã xe không hợp lệ', 400);
  }

  const routeId = Number(req.body?.routeId);
  const latitude = Number(req.body?.latitude);
  const longitude = Number(req.body?.longitude);
  const speed = req.body?.speed === undefined ? null : Number(req.body.speed);
  const heading = req.body?.heading === undefined ? null : Number(req.body.heading);

  if (!Number.isInteger(routeId) || routeId <= 0) {
    return failure(res, 'Mã tuyến không hợp lệ', 400);
  }
  if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90) {
    return failure(res, 'Vĩ độ không hợp lệ (phải trong khoảng -90 đến 90)', 400);
  }
  if (!Number.isFinite(longitude) || longitude < -180 || longitude > 180) {
    return failure(res, 'Kinh độ không hợp lệ (phải trong khoảng -180 đến 180)', 400);
  }
  if (speed !== null && (!Number.isFinite(speed) || speed < 0 || speed > 200)) {
    return failure(res, 'Tốc độ không hợp lệ (phải từ 0 đến 200 km/h)', 400);
  }
  if (heading !== null && (!Number.isFinite(heading) || heading < 0 || heading > 360)) {
    return failure(res, 'Hướng di chuyển không hợp lệ (phải từ 0 đến 360 độ)', 400);
  }

  try {
    const bus = await Bus.findByPk(busId);
    if (!bus) {
      return failure(res, 'Không tìm thấy xe buýt', 404);
    }

    const route = await Route.findByPk(routeId);
    if (!route) {
      return failure(res, 'Không tìm thấy tuyến xe buýt', 404);
    }

    const location = await BusLocation.create({
      busId,
      latitude,
      longitude,
      speed,
      heading,
      recordedAt: new Date(),
    });

    // Xe đang chạy thì đánh dấu RUNNING; nếu đổi tuyến thì cập nhật theo.
    const previousStatus = bus.status;
    bus.status = 'RUNNING';
    if (bus.routeId !== routeId) {
      bus.routeId = routeId;
    }
    await bus.save();

    const updatedAt = location.recordedAt.toISOString();

    const payload = {
      busId: bus.id,
      busCode: bus.busCode,
      routeId,
      latitude: location.latitude,
      longitude: location.longitude,
      speed: location.speed,
      heading: location.heading,
      updatedAt,
    };

    // Chỉ phát sau khi đã lưu thành công ở trên.
    emitBusLocation(payload);

    // Nếu trạng thái xe vừa thay đổi (ví dụ ACTIVE -> RUNNING) thì phát thêm
    // sự kiện bus:status-updated để client cập nhật nhãn trạng thái.
    if (previousStatus !== bus.status) {
      emitBusStatus({
        busId: bus.id,
        busCode: bus.busCode,
        routeId,
        status: bus.status,
        updatedAt,
      });
    }

    return success(res, publicBus(bus, location), 'Cập nhật vị trí xe thành công');
  } catch (err) {
    console.error('[Lỗi cập nhật vị trí xe]', err.message);
    return failure(res, 'Lỗi cập nhật vị trí xe, vui lòng thử lại sau', 500);
  }
}
