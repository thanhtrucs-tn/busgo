-- ============================================================
-- transit_upgrade.sql - NÂNG CẤP cấu trúc bảng tuyến/trạm/xe
-- cho database BusGo ĐÃ TỒN TẠI từ phiên bản trước.
--
-- Mục đích: khi database đã được tạo bởi sequelize.sync() (hoặc bản DDL cũ),
-- chạy file này để bổ sung phần còn thiếu mà KHÔNG xóa dữ liệu:
--   1. UNIQUE KEY cho route_points(route_id, direction, point_order).
--   2. Xóa index bị trùng trên bus_locations (nếu có).
--   3. Ràng buộc CHECK khoảng giá trị latitude/longitude.
--
-- An toàn khi chạy lại nhiều lần: mỗi thay đổi đều kiểm tra tồn tại trước.
--
-- Cách chạy:
--   mysql -u root BusGo < server/sql/transit_upgrade.sql
-- hoặc trong MySQL Workbench / phpMyAdmin: mở file và Execute.
-- ============================================================

USE BusGo;

-- ------------------------------------------------------------
-- 1) UNIQUE KEY cho route_points: mỗi tuyến/chiều chỉ có một điểm
--    tại mỗi thứ tự (route_id, direction, point_order).
-- ------------------------------------------------------------
SET @has_uk := (
  SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'route_points'
    AND INDEX_NAME = 'uk_route_points_order'
);
SET @sql := IF(
  @has_uk = 0,
  'ALTER TABLE route_points ADD UNIQUE KEY uk_route_points_order (route_id, direction, point_order)',
  'SELECT ''uk_route_points_order da ton tai'' AS note'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- 2) Xóa index trùng trên bus_locations.
--    Yêu cầu chỉ cần một index (bus_id, recorded_at).
-- ------------------------------------------------------------
SET @has_dup := (
  SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'bus_locations'
    AND INDEX_NAME = 'bus_locations_bus_id_recorded_at'
);
SET @sql := IF(
  @has_dup > 0,
  'ALTER TABLE bus_locations DROP INDEX bus_locations_bus_id_recorded_at',
  'SELECT ''Khong co index trung tren bus_locations'' AS note'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- 3) Ràng buộc CHECK cho tọa độ (latitude/longitude).
--    Lặp lại cùng mẫu cho từng cột cần kiểm tra.
-- ------------------------------------------------------------

-- stops.latitude [-90, 90]
SET @c := (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'stops'
    AND CONSTRAINT_NAME = 'chk_stops_lat' AND CONSTRAINT_TYPE = 'CHECK');
SET @sql := IF(@c = 0,
  'ALTER TABLE stops ADD CONSTRAINT chk_stops_lat CHECK (latitude BETWEEN -90 AND 90)',
  'SELECT ''chk_stops_lat da ton tai'' AS note');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- stops.longitude [-180, 180]
SET @c := (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'stops'
    AND CONSTRAINT_NAME = 'chk_stops_lng' AND CONSTRAINT_TYPE = 'CHECK');
SET @sql := IF(@c = 0,
  'ALTER TABLE stops ADD CONSTRAINT chk_stops_lng CHECK (longitude BETWEEN -180 AND 180)',
  'SELECT ''chk_stops_lng da ton tai'' AS note');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- route_points.latitude [-90, 90]
SET @c := (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'route_points'
    AND CONSTRAINT_NAME = 'chk_route_points_lat' AND CONSTRAINT_TYPE = 'CHECK');
SET @sql := IF(@c = 0,
  'ALTER TABLE route_points ADD CONSTRAINT chk_route_points_lat CHECK (latitude BETWEEN -90 AND 90)',
  'SELECT ''chk_route_points_lat da ton tai'' AS note');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- route_points.longitude [-180, 180]
SET @c := (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'route_points'
    AND CONSTRAINT_NAME = 'chk_route_points_lng' AND CONSTRAINT_TYPE = 'CHECK');
SET @sql := IF(@c = 0,
  'ALTER TABLE route_points ADD CONSTRAINT chk_route_points_lng CHECK (longitude BETWEEN -180 AND 180)',
  'SELECT ''chk_route_points_lng da ton tai'' AS note');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- bus_locations.latitude [-90, 90]
SET @c := (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'bus_locations'
    AND CONSTRAINT_NAME = 'chk_bus_locations_lat' AND CONSTRAINT_TYPE = 'CHECK');
SET @sql := IF(@c = 0,
  'ALTER TABLE bus_locations ADD CONSTRAINT chk_bus_locations_lat CHECK (latitude BETWEEN -90 AND 90)',
  'SELECT ''chk_bus_locations_lat da ton tai'' AS note');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- bus_locations.longitude [-180, 180]
SET @c := (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'bus_locations'
    AND CONSTRAINT_NAME = 'chk_bus_locations_lng' AND CONSTRAINT_TYPE = 'CHECK');
SET @sql := IF(@c = 0,
  'ALTER TABLE bus_locations ADD CONSTRAINT chk_bus_locations_lng CHECK (longitude BETWEEN -180 AND 180)',
  'SELECT ''chk_bus_locations_lng da ton tai'' AS note');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- 4) Giá trị mặc định cho created_at / updated_at.
--    Bảng do sequelize.sync() tạo có thể thiếu DEFAULT nên khi chạy
--    seed bằng SQL thô sẽ bị '0000-00-00 00:00:00'. Bổ sung mặc định
--    để giống với transit_schema.sql.
-- ------------------------------------------------------------

-- routes
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'routes'
    AND COLUMN_NAME = 'created_at' AND COLUMN_DEFAULT IS NULL);
SET @sql := IF(@c > 0,
  'ALTER TABLE routes MODIFY created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, MODIFY updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP',
  'SELECT ''routes.created_at da co mac dinh'' AS note');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- stops
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'stops'
    AND COLUMN_NAME = 'created_at' AND COLUMN_DEFAULT IS NULL);
SET @sql := IF(@c > 0,
  'ALTER TABLE stops MODIFY created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, MODIFY updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP',
  'SELECT ''stops.created_at da co mac dinh'' AS note');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- route_stops
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'route_stops'
    AND COLUMN_NAME = 'created_at' AND COLUMN_DEFAULT IS NULL);
SET @sql := IF(@c > 0,
  'ALTER TABLE route_stops MODIFY created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, MODIFY updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP',
  'SELECT ''route_stops.created_at da co mac dinh'' AS note');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- route_points
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'route_points'
    AND COLUMN_NAME = 'created_at' AND COLUMN_DEFAULT IS NULL);
SET @sql := IF(@c > 0,
  'ALTER TABLE route_points MODIFY created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, MODIFY updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP',
  'SELECT ''route_points.created_at da co mac dinh'' AS note');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
