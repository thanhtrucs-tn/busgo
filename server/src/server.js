// ------------------------------------------------------------
// server.js - Điểm khởi động của API BusGo (đăng nhập / đăng ký).
//
// Cách chạy:
//   1. Tạo database TEST_123: chạy file  server/sql/TEST_123.sql.
//   2. Sao chép .env.example thành .env và điền mật khẩu MySQL.
//   3. cài thư viện:  npm install
//   4. chạy API:      npm start        (mặc định cổng 3000)
// ------------------------------------------------------------

import cors from 'cors';
import dotenv from 'dotenv';
import express from 'express';
import authRoutes from './routes/auth.routes.js';
import { errorHandler, failure, success } from './utils/response.util.js';

// Nạp biến môi trường từ file .env.
dotenv.config();

// Tạo ứng dụng Express.
const app = express();

// Cho phép ứng dụng Flutter (web/desktop) gọi API từ nguồn khác.
app.use(cors());

// Tự động chuyển dữ liệu JSON trong request body thành object JS.
app.use(express.json());

// Đường dẫn kiểm tra máy chủ còn hoạt động hay không.
app.get('/health', (req, res) => success(res, { status: 'ok' }, 'Máy chủ hoạt động bình thường'));

// Gắn nhóm đường dẫn xác thực vào tiền tố /api/auth.
app.use('/api/auth', authRoutes);

// Bắt các đường dẫn không tồn tại.
app.use((req, res) => failure(res, 'Không tìm thấy đường dẫn yêu cầu', 404));

// Bắt mọi lỗi phát sinh trong quá trình xử lý.
app.use(errorHandler);

// Khởi động máy chủ trên cổng đã cấu hình.
const PORT = Number(process.env.PORT) || 3000;
app.listen(PORT, () => {
  console.log(`API BusGo đang chạy tại: http://localhost:${PORT}`);
  console.log(`- Đăng ký:   POST /api/auth/register`);
  console.log(`- Đăng nhập: POST /api/auth/login`);
});