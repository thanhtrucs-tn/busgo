-- ============================================================
-- Script tạo cơ sở dữ liệu và bảng cho tính năng đăng nhập BusGo
-- ============================================================
-- Hướng dẫn chạy:
--   1. Mở MySQL (Command Line / MySQL Workbench / phpMyAdmin).
--   2. Chạy toàn bộ nội dung file này.
--   3. Kiểm tra lại bằng lệnh:  USE TEST_123; DESCRIBE users;
-- ============================================================

-- Tạo cơ sở dữ liệu TEST_123 (nếu chưa tồn tại).
-- utf8mb4 hỗ trợ đầy đủ tiếng Việt có dấu.
CREATE DATABASE IF NOT EXISTS TEST_123
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- Chuyển sang dùng cơ sở dữ liệu vừa tạo.
USE TEST_123;

-- ------------------------------------------------------------
-- Bảng users: lưu trữ tài khoản người dùng.
--  - username: tên đăng nhập, tối đa 32 ký tự (theo yêu cầu).
--  - password: mật khẩu đã mã hóa bằng bcrypt (60 ký tự),
--              tối đa 64 ký tự (theo yêu cầu).
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id         INT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Khóa chính, tự tăng',
  username   VARCHAR(32)   NOT NULL                COMMENT 'Tên đăng nhập (tối đa 32 ký tự)',
  password   VARCHAR(64)   NOT NULL                COMMENT 'Mật khẩu đã mã hóa (tối đa 64 ký tự)',
  created_at TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm tạo tài khoản',
  PRIMARY KEY (id),
  UNIQUE KEY uk_username (username)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Ghi chú thiết kế:
--  - Khóa duy nhất uk_username đảm bảo mỗi tên đăng nhập chỉ tồn tại một lần.
--  - Mật khẩu KHÔNG lưu dạng văn bản thô, mà lưu chuỗi bcrypt
--    do backend tạo ra (an toàn hơn, chuẩn kỹ thuật phần mềm).