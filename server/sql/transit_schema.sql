-- ============================================================
-- transit_schema.sql - Định nghĩa cấu trúc các bảng tuyến/trạm
--                       cho BusGo (tham chiếu / migration thủ công).
--
-- LƯU Ý: Dự án dùng Sequelize và gọi sequelize.sync() lúc khởi động,
-- nên các bảng này CÓ THỂ được tạo tự động bởi sync (đọc model trong
-- server/src/models/). File này là tài liệu DDL đầy đủ (khóa, ràng buộc,
-- index, CHECK) để chạy thủ công HOẶC tham chiếu. Dùng IF NOT EXISTS
-- để không lỗi nếu chạy sau khi sync đã tạo.
--
-- Mối quan hệ:
--   routes      (tuyến)
--   stops       (trạm)
--   route_stops (trạm thuộc tuyến theo từng chiều, nhiều-nhiều)
--   route_points(điểm polyline chi tiết của tuyến theo chiều)
--   buses       (xe buýt thuộc một tuyến)
--   bus_locations(vị trí xe theo thời gian)
-- ============================================================

USE BusGo;

-- ------------------------------------------------------------
-- Bảng routes: tuyến xe buýt.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS routes (
  id                 INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  route_code         VARCHAR(20)    NOT NULL COMMENT 'Mã tuyến, vd: 01',
  route_name         VARCHAR(255)   NOT NULL COMMENT 'Tên tuyến',
  start_point        VARCHAR(255)   NOT NULL COMMENT 'Điểm đầu',
  end_point          VARCHAR(255)   NOT NULL COMMENT 'Điểm cuối',
  color              VARCHAR(20)    NULL COMMENT 'Màu vẽ polyline',
  start_time         VARCHAR(10)    NULL COMMENT 'Giờ mở bán, vd: 05:00',
  end_time           VARCHAR(10)    NULL COMMENT 'Giờ kết thúc, vd: 21:00',
  frequency_minutes  INT            NULL COMMENT 'Tần suất chuyến (phút)',
  fare               DECIMAL(10,2)  NULL COMMENT 'Giá vé (VNĐ)',
  status             VARCHAR(20)    NOT NULL DEFAULT 'active',
  created_at         TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at         TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_routes_route_code (route_code)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- Bảng stops: trạm xe buýt.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS stops (
  id          INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  stop_code   VARCHAR(20)   NOT NULL COMMENT 'Mã trạm, vd: ST-001',
  stop_name   VARCHAR(255)  NOT NULL COMMENT 'Tên trạm',
  address     VARCHAR(255)  NULL COMMENT 'Địa chỉ',
  latitude    DOUBLE        NOT NULL COMMENT 'Vĩ độ [-90, 90]',
  longitude   DOUBLE        NOT NULL COMMENT 'Kinh độ [-180, 180]',
  status      VARCHAR(20)   NOT NULL DEFAULT 'active',
  created_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_stops_stop_code (stop_code),
  CONSTRAINT chk_stops_lat CHECK (latitude  BETWEEN -90  AND 90),
  CONSTRAINT chk_stops_lng CHECK (longitude BETWEEN -180 AND 180)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- Bảng route_stops: trạm thuộc tuyến theo từng chiều.
--   - Khóa chính tổ hợp (route_id, stop_id, direction).
--   - direction: 0 = chiều đi, 1 = chiều về.
--   - Một trạm có thể thuộc nhiều tuyến; một tuyến có nhiều trạm.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS route_stops (
  route_id                  INT UNSIGNED NOT NULL,
  stop_id                   INT UNSIGNED NOT NULL,
  direction                 TINYINT      NOT NULL DEFAULT 0 COMMENT '0=đi, 1=về',
  stop_order                INT          NOT NULL COMMENT 'Thứ tự trạm trong chiều',
  estimated_minutes_from_start INT       NULL COMMENT 'Thời gian ~ từ đầu tuyến (phút)',
  created_at                TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at                TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (route_id, stop_id, direction),
  INDEX idx_route_stops_route (route_id),
  INDEX idx_route_stops_stop  (stop_id),
  CONSTRAINT fk_route_stops_route FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE CASCADE,
  CONSTRAINT fk_route_stops_stop  FOREIGN KEY (stop_id)  REFERENCES stops(id)  ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- Bảng route_points: điểm polyline chi tiết của tuyến theo chiều.
--   - Tọa độ bám theo đường thật (không nối thẳng giữa trạm).
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS route_points (
  id           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  route_id     INT UNSIGNED  NOT NULL,
  direction    TINYINT       NOT NULL DEFAULT 0 COMMENT '0=đi, 1=về',
  point_order  INT           NOT NULL COMMENT 'Thứ tự điểm trong polyline',
  latitude     DOUBLE        NOT NULL,
  longitude    DOUBLE        NOT NULL,
  created_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  -- Mỗi tuyến/chiều chỉ có một điểm tại mỗi thứ tự.
  UNIQUE KEY uk_route_points_order (route_id, direction, point_order),
  INDEX idx_route_points_route_dir (route_id, direction),
  CONSTRAINT fk_route_points_route FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE CASCADE,
  CONSTRAINT chk_route_points_lat CHECK (latitude  BETWEEN -90  AND 90),
  CONSTRAINT chk_route_points_lng CHECK (longitude BETWEEN -180 AND 180)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- Bảng buses: xe buýt thuộc một tuyến.
--   status: ACTIVE (đang hoạt động) | RUNNING (đang chạy) | INACTIVE (nghỉ).
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS buses (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  bus_code      VARCHAR(30)  NOT NULL COMMENT 'Mã xe, vd: BUS-001',
  license_plate VARCHAR(20)  NOT NULL COMMENT 'Biển số xe',
  route_id      INT UNSIGNED NOT NULL,
  status        VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_buses_bus_code (bus_code),
  UNIQUE KEY uk_buses_license_plate (license_plate),
  INDEX idx_buses_route (route_id),
  CONSTRAINT fk_buses_route FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- Bảng bus_locations: lịch sử vị trí xe (mỗi lần cập nhật là 1 dòng).
--   speed   : tốc độ tức thời (km/h)
--   heading : hướng di chuyển (độ, 0-360)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS bus_locations (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  bus_id      INT UNSIGNED NOT NULL,
  latitude    DOUBLE       NOT NULL COMMENT 'Vĩ độ [-90, 90]',
  longitude   DOUBLE       NOT NULL COMMENT 'Kinh độ [-180, 180]',
  speed       FLOAT        NULL COMMENT 'Tốc độ tức thời (km/h)',
  heading     FLOAT        NULL COMMENT 'Hướng di chuyển (độ)',
  recorded_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_bus_locations_bus_time (bus_id, recorded_at),
  CONSTRAINT fk_bus_locations_bus FOREIGN KEY (bus_id) REFERENCES buses(id) ON DELETE CASCADE,
  CONSTRAINT chk_bus_locations_lat CHECK (latitude  BETWEEN -90  AND 90),
  CONSTRAINT chk_bus_locations_lng CHECK (longitude BETWEEN -180 AND 180)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;