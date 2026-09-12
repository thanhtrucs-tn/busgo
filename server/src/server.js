// ------------------------------------------------------------
// server.js - Điểm khởi động của API BusGo (đăng nhập / đăng ký / JWT).
//
// Cách chạy:
//   1. Tạo database BusGo: chạy file  server/sql/BusGo.sql.
//   2. Sao chép .env.production thành .env và điền mật khẩu MySQL
//      + JWT_SECRET (khóa bí mật ký JWT).
//   3. cài thư viện:  npm install
//   4. chạy API:      npm start   (mặc định cổng 3000)
// ------------------------------------------------------------

import cors from 'cors';
import dotenv from 'dotenv';
import express from 'express';
import http from 'http';
import { sequelize } from './config/db.js';
import './models/associations.js'; // Khai báo quan hệ tuyến/trạm/xe trước khi sync
import authRoutes from './routes/auth.routes.js';
import userRoutes from './routes/user.routes.js';
import routeRoutes from './routes/route.routes.js';
import stopRoutes from './routes/stop.routes.js';
import busRoutes from './routes/bus.routes.js';
import profileRoutes from './routes/profile.routes.js';
import { initSocket } from './realtime/socket.js';
import { errorHandler, failure, success } from './utils/response.util.js';
import { requireJwtSecret } from './utils/jwt.util.js';

// Nạp biến môi trường: local dùng .env, production dùng .env.production.
const envFile = process.env.NODE_ENV === 'production' ? '.env.production' : '.env';
dotenv.config({ path: envFile });

// QUAN TRỌNG: khóa ký JWT bắt buộc có trong .env (không hard-code).
requireJwtSecret();

// Kết nối MySQL + đồng bộ bảng (tạo bảng còn thiếu: users, routes, stops, buses...).
// Lưu ý: sequelize.sync() KHÔNG xóa hay sửa dữ liệu hiện có.
async function initDatabase() {
  try {
    await sequelize.authenticate(); // Kiểm tra kết nối
    await sequelize.sync(); // Tạo bảng nếu chưa tồn tại
    await ensureUsersGoogleColumn(); // Bổ sung cột google_id cho bảng cũ
    console.log('[OK] Kết nối MySQL thành công, database: BusGo');
  } catch (err) {
    // Không dừng server: người dùng vẫn thấy thông báo lỗi thân thiện ở API.
    console.error('[LỖI] Không kết nối được MySQL:', err.message);
    console.error('      -> Kiểm tra .env và đảm bảo MySQL đang chạy.');
  }
}

// Bổ sung cột google_id cho bảng users đã tồn tại TRƯỚC khi có tính năng
// đăng nhập bằng Google. sequelize.sync() chỉ TẠO bảng mới, không thêm cột
// vào bảng cũ, nên cần chạy lệnh ALTER TABLE an toàn:
//   - kiểm tra cột đã tồn tại chưa (information_schema)
//   - chưa có mới thêm, KHÔNG xóa / sửa cột nào khác
async function ensureUsersGoogleColumn() {
  const [rows] = await sequelize.query(
    "SELECT COUNT(*) AS c FROM information_schema.COLUMNS " +
      "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' " +
      "AND COLUMN_NAME = 'google_id'",
  );
  const count = Number(rows?.[0]?.c || 0);
  if (count > 0) return;

  await sequelize.query(
    'ALTER TABLE users ' +
      'ADD COLUMN google_id VARCHAR(255) NULL, ' +
      'ADD UNIQUE KEY users_google_id_unique (google_id)',
  );
  console.log('[OK] Đã thêm cột google_id vào bảng users (đăng nhập bằng Google)');
}

// Tạo ứng dụng Express.
const app = express();

// Cho phép ứng dụng Flutter (web/desktop) gọi API từ nguồn khác.
app.use(cors());

// Tự động chuyển dữ liệu JSON trong request body thành object JS.
// Tăng giới hạn lên 6MB vì hồ sơ có thể gửi kèm ảnh đại diện dạng base64.
app.use(express.json({ limit: '6mb' }));

// Đường dẫn kiểm tra máy chủ còn hoạt động hay không.
app.get('/health', (req, res) =>
  success(res, { status: 'ok' }, 'Máy chủ hoạt động bình thường'),
);

// Gắn nhóm đường dẫn xác thực vào tiền tố /api/auth.
app.use('/api/auth', authRoutes);

// Gắn nhóm đường dẫn tài khoản (protected + admin) vào tiền tố /api.
app.use('/api', userRoutes);

// Gắn nhóm đường dẫn tuyến & trạm xe buýt vào tiền tố /api.
app.use('/api/routes', routeRoutes);
app.use('/api/stops', stopRoutes);

// Gắn nhóm đường dẫn cập nhật vị trí xe buýt vào tiền tố /api/buses.
app.use('/api/buses', busRoutes);

// Gắn nhóm đường dẫn hồ sơ cá nhân (protected, theo JWT) vào /api/profile.
app.use('/api/profile', profileRoutes);

// Bắt các đường dẫn không tồn tại.
app.use((req, res) => failure(res, 'Không tìm thấy đường dẫn yêu cầu', 404));

// Bắt mọi lỗi phát sinh trong quá trình xử lý.
app.use(errorHandler);

// Khởi động máy chủ trên cổng đã cấu hình.
// Dùng http server để Socket.IO có thể bám vào cùng cổng với REST API.
const PORT = Number(process.env.PORT) || 3000;
const httpServer = http.createServer(app);
initSocket(httpServer);

httpServer.listen(PORT, async () => {
  console.log(`API BusGo đang chạy tại: http://localhost:${PORT}`);
  console.log(`- Đăng ký:      POST /api/auth/register`);
  console.log(`- Đăng nhập:    POST /api/auth/login   (trả về JWT)`);
  console.log(`- Google:       POST /api/auth/google   (đăng nhập nhanh bằng Google)`);
  console.log(`- Thông tin tôi: GET /api/auth/me      (cần JWT)`);
  console.log(`- Hồ sơ:        GET /api/user/profile  (cần JWT)`);
  console.log(`- Hồ sơ mới:    GET|PUT /api/profile/me (theo JWT, tách dữ liệu)`);
  console.log(`- Admin:        GET /api/admin/users   (cần role=admin)`);
  console.log(`- Tuyến:        GET /api/routes, /api/routes/:id/path|stops|buses`);
  console.log(`- Trạm:         GET /api/stops, /api/stops/nearby, /api/stops/:id/arrivals`);
  console.log(`- Vị trí xe:    POST /api/buses/:id/location (cần role=admin, có Socket.IO)`);
  await initDatabase();
});