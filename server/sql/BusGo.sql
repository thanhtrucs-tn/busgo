-- ============================================================
-- Script tạo cơ sở dữ liệu và bảng cho BusGo (bản mới - JWT)
-- ============================================================
-- Hướng dẫn chạy:
--   1. Mở MySQL (Command Line / MySQL Workbench / phpMyAdmin).
--   2. Chạy toàn bộ nội dung file này (CHO LẦN CÀI MỚI).
--   3. Kiểm tra lại bằng lệnh:  USE TEST_123; DESCRIBE users;
--
-- NẾU ĐÃ CÓ DATABASE CŨ (bảng users cũ chưa có email/name/role):
--   KHÔNG chạy lại CREATE TABLE (bảng đã tồn tại).
--   Chỉ chạy phần ALTER TABLE bên dưới (mục "NÂNG CẤP DB CŨ").
--   Dữ liệu cũ KHÔNG bị xóa.
-- ============================================================

-- Tạo cơ sở dữ liệu TEST_123 (nếu chưa tồn tại).
-- utf8mb4 hỗ trợ đầy đủ tiếng Việt có dấu.
CREATE DATABASE IF NOT EXISTS BusGo
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- Chuyển sang dùng cơ sở dữ liệu vừa tạo.
USE BusGo;

-- ------------------------------------------------------------
-- Bảng users: lưu trữ tài khoản người dùng.
--
-- Các trường:
--  - id         : khóa chính, tự tăng.
--  - username   : tên đăng nhập, tối đa 32 ký tự (giữ từ giai đoạn trước).
--  - password   : mật khẩu ĐÃ MÃ HÓA bcrypt (60 ký tự), tối đa 64 ký tự.
--  - email      : email (tùy chọn, đăng nhập được bằng email), duy nhất.
--  - name       : tên hiển thị (tùy chọn, mặc định bằng username).
--  - role       : phân quyền, 'user' (mặc định) hoặc 'admin'.
--  - created_at : thời điểm tạo tài khoản.
--  - updated_at : thời điểm cập nhật (Sequelize tự quản lý).
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id         INT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Khóa chính, tự tăng',
  username   VARCHAR(32)   NOT NULL                COMMENT 'Tên đăng nhập (tối đa 32 ký tự)',
  password   VARCHAR(64)   NOT NULL                COMMENT 'Mật khẩu đã mã hóa bcrypt (tối đa 64 ký tự)',
  email      VARCHAR(255)  NULL                    COMMENT 'Email (tùy chọn, dùng để đăng nhập)',
  name       VARCHAR(50)   NULL                    COMMENT 'Tên hiển thị (tùy chọn)',
  role       VARCHAR(20)   NOT NULL DEFAULT 'user' COMMENT 'Phân quyền: user hoặc admin',
  created_at TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm tạo tài khoản',
  updated_at TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Thời điểm cập nhật',
  PRIMARY KEY (id),
  UNIQUE KEY uk_username (username),
  UNIQUE KEY uk_email (email)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


-- ======================================================================================

-- Ghi chú thiết kế:
--  - Khóa duy nhất uk_username / uk_email đảm bảo mỗi tên/email chỉ tồn tại một lần.
--  - Mật khẩu KHÔNG lưu dạng văn bản thô, mà là chuỗi bcrypt do backend tạo ra.
--  - JWT_SECRET nằm trong file .env của backend (không bao giờ đưa lên GitHub).
--  - Để tạo tài khoản quản trị (admin), chạy thêm:
--      UPDATE users SET role = 'admin' WHERE username = 'tên_admin_của_bạn';