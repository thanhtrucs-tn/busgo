// ------------------------------------------------------------
// realtime/socket.js - Kết nối thời gian thực cho vị trí xe buýt.
//
// Dùng Socket.IO để đẩy vị trí xe mới nhất tới ứng dụng Flutter ngay khi
// tài xế cập nhật qua POST /api/buses/:busId/location, thay vì phải hỏi lại.
//
// Phòng (room) theo tuyến: route:<routeId>
//   - Flutter gửi 'route:join' để theo dõi một tuyến, 'route:leave' để rời.
//   - Server phát 'bus:location-updated' cho mọi client trong phòng đó.
// ------------------------------------------------------------

import { Server } from 'socket.io';

// Lưu lại instance io sau khi khởi tạo để controller gọi được.
let io = null;

// Gọi một lần trong server.js sau khi tạo http server.
export function initSocket(httpServer) {
  io = new Server(httpServer, {
    cors: {
      origin: process.env.CLIENT_URL || '*',
    },
  });

  io.on('connection', (socket) => {
    console.log(`[Socket.IO] Client kết nối: ${socket.id}`);

    socket.on('route:join', (routeId) => {
      const id = Number(routeId);
      if (!Number.isInteger(id) || id <= 0) return;
      socket.join(`route:${id}`);
    });

    socket.on('route:leave', (routeId) => {
      const id = Number(routeId);
      if (!Number.isInteger(id) || id <= 0) return;
      socket.leave(`route:${id}`);
    });
  });

  return io;
}

// Phát vị trí xe mới tới các client đang theo dõi tuyến tương ứng.
// Chỉ gọi sau khi vị trí đã lưu thành công vào MySQL.
export function emitBusLocation(payload) {
  if (!io) return;
  io.to(`route:${payload.routeId}`).emit('bus:location-updated', payload);
}

// Phát trạng thái xe mới (RUNNING / INACTIVE...) tới các client theo dõi tuyến.
export function emitBusStatus(payload) {
  if (!io) return;
  io.to(`route:${payload.routeId}`).emit('bus:status-updated', payload);
}
