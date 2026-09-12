-- ============================================================
-- profiles_schema.sql - Bảng hồ sơ mở rộng, tách dữ liệu theo tài khoản.
--
-- MỤC ĐÍCH: sửa lỗi rò rỉ dữ liệu hồ sơ giữa các tài khoản. Mỗi hồ sơ
-- gắn với DUY NHẤT một tài khoản qua user_id (UNIQUE + khóa ngoại).
--
-- LƯU Ý: backend dùng Sequelize và gọi sequelize.sync() lúc khởi động nên
-- bảng này có thể được tạo tự động. File DDL này dùng để chạy thủ công hoặc
-- tham chiếu; dùng IF NOT EXISTS để không lỗi nếu đã được sync tạo trước.
--
-- Cách chạy:
--   mysql -u root BusGo < profiles_schema.sql
-- ============================================================

USE BusGo;

CREATE TABLE IF NOT EXISTS profiles (
  id                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id               INT UNSIGNED NOT NULL COMMENT 'Tài khoản sở hữu hồ sơ',
  phone                 VARCHAR(20)  NULL     COMMENT 'Số điện thoại (10 chữ số)',
  birthday              DATE         NULL     COMMENT 'Ngày sinh',
  avatar                MEDIUMTEXT   NULL     COMMENT 'Ảnh đại diện dạng base64',
  addresses             TEXT         NULL     COMMENT 'Danh sách địa chỉ dạng JSON',
  default_address_index INT          NOT NULL DEFAULT 0 COMMENT 'Vị trí địa chỉ mặc định',
  location_lat          DOUBLE       NULL     COMMENT 'Vĩ độ địa chỉ chính',
  location_lng          DOUBLE       NULL     COMMENT 'Kinh độ địa chỉ chính',
  created_at            TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at            TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_profiles_user_id (user_id),
  CONSTRAINT fk_profiles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
