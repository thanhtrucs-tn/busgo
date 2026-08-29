// ------------------------------------------------------------
// Cấu hình kết nối tới cơ sở dữ liệu MySQL (dùng connection pool).
// Connection pool giúp tái sử dụng kết nối, tránh mở/đóng liên tục,
// giúp API chạy ổn định và nhanh hơn khi có nhiều yêu cầu.
// ------------------------------------------------------------

import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

// Nạp các biến môi trường từ file .env (nếu có).
dotenv.config();

// Tạo pool kết nối MySQL.
// Các giá trị mặc định khớp với server/.env.example.
export const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'TEST_123',
  waitForConnections: true, // Chờ khi pool đã đủ kết nối
  connectionLimit: 10, // Số kết nối tối đa trong pool
  charset: 'utf8mb4', // Hỗ trợ tiếng Việt có dấu
});