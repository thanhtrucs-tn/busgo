// ------------------------------------------------------------
// server.js - Điểm khởi động của API BusGo (đăng nhập / đăng ký / JWT).
//
// Cách chạy:
//   1. Tạo database TEST_123: chạy file  server/sql/TEST_123.sql.
//   2. Sao chép .env.example thành .env và điền mật khẩu MySQL
//      + JWT_SECRET (khóa bí mật ký JWT).
//   3. cài thư viện:  npm install
//   4. chạy API:      npm start   (mặc định cổng 3000)
// ------------------------------------------------------------

import cors from 'cors';
import dotenv from 'dotenv';
import express from 'express';
import { sequelize } from './config/db.js';
import authRoutes from './routes/auth.routes.js';
import userRoutes from './routes/user.routes.js';
import { errorHandler, failure, success } from './utils/response.util.js';
import { requireJwtSecret } from './utils/jwt.util.js';

// Nạp biến môi trường từ file .env.
dotenv.config();

// QUAN TRỌNG: khóa ký JWT bắt buộc có trong .env (không hard-code).
requireJwtSecret();

// Kết nối MySQL + đồng bộ bảng (tạo bảng users nếu chưa có).
// Lưu ý: sequelize.sync() KHÔNG xóa hay sửa dữ liệu hiện có.
async function initDatabase() {
  try {
    await sequelize.authenticate(); // Kiểm tra kết nối
    await sequelize.sync(); // Tạo bảng nếu chưa tồn tại
    console.log('[OK] Kết nối MySQL thành công, database: BusGo');
  } catch (err) {
    // Không dừng server: người dùng vẫn thấy thông báo lỗi thân thiện ở API.
    console.error('[LỖI] Không kết nối được MySQL:', err.message);
    console.error('      -> Kiểm tra .env và đảm bảo MySQL đang chạy.');
  }
}

// Tạo ứng dụng Express.
const app = express();

// Cho phép ứng dụng Flutter (web/desktop) gọi API từ nguồn khác.
app.use(cors());

// Tự động chuyển dữ liệu JSON trong request body thành object JS.
app.use(express.json());

// Đường dẫn kiểm tra máy chủ còn hoạt động hay không.
app.get('/health', (req, res) =>
  success(res, { status: 'ok' }, 'Máy chủ hoạt động bình thường'),
);

// Gắn nhóm đường dẫn xác thực vào tiền tố /api/auth.
app.use('/api/auth', authRoutes);

// Gắn nhóm đường dẫn tài khoản (protected + admin) vào tiền tố /api.
app.use('/api', userRoutes);

// Bắt các đường dẫn không tồn tại.
app.use((req, res) => failure(res, 'Không tìm thấy đường dẫn yêu cầu', 404));

// Bắt mọi lỗi phát sinh trong quá trình xử lý.
app.use(errorHandler);

// Khởi động máy chủ trên cổng đã cấu hình.
const PORT = Number(process.env.PORT) || 3000;
app.listen(PORT, async () => {
  console.log(`API BusGo đang chạy tại: http://localhost:${PORT}`);
  console.log(`- Đăng ký:      POST /api/auth/register`);
  console.log(`- Đăng nhập:    POST /api/auth/login   (trả về JWT)`);
  console.log(`- Thông tin tôi: GET /api/auth/me      (cần JWT)`);
  console.log(`- Hồ sơ:        GET /api/user/profile  (cần JWT)`);
  console.log(`- Admin:        GET /api/admin/users   (cần role=admin)`);
  await initDatabase();
});