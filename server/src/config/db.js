// ------------------------------------------------------------
// Cấu hình kết nối tới cơ sở dữ liệu MySQL thông qua Sequelize (ORM).
//
// Vì sao dùng Sequelize?
//  - Viết truy vấn bằng JavaScript thay vì câu lệnh SQL thô.
//  - Model khai báo một nơi (models/User.js) -> tự động khớp bảng.
//  - Quản lý connection pool tự động.
//
// LƯU Ý: toàn bộ thông tin kết nối đọc từ biến môi trường .env,
// KHÔNG hard-code giá trị mật khẩu trong source code.
// ------------------------------------------------------------

import dotenv from 'dotenv';
import { Sequelize } from 'sequelize';

// Nạp biến môi trường:
//   - Chạy local:      đọc file .env
//   - NODE_ENV=production: đọc file .env.production
// Lưu ý: .env.production trong repo chỉ là file mẫu. Khi triển khai thật
// nên đặt biến môi trường trực tiếp trên máy chủ (dotenv không ghi đè biến
// đã tồn tại trong môi trường).
const envFile = process.env.NODE_ENV === 'production' ? '.env.production' : '.env';
dotenv.config({ path: envFile });

// Tạo đối tượng Sequelize kết nối MySQL.
// Các giá trị mặc định khớp với server/.env và server/.env.production.
export const sequelize = new Sequelize(
  process.env.DB_NAME || 'BUS_GO_db', // Tên database
  process.env.DB_USER || 'root', // Tài khoản MySQL
  process.env.DB_PASSWORD || '', // Mật khẩu MySQL
  {
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT) || 3306,
    dialect: 'mysql', // Loại cơ sở dữ liệu
    logging: false, // Tắt log câu lệnh SQL để console sạch hơn
    define: {
      underscored: true, // Tự động dùng created_at/updated_at (snake_case)
      freezeTableName: true, // Giữ nguyên tên bảng 'users', không thêm 's'
    },
  },
);