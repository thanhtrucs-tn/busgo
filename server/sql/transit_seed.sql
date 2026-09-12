-- ============================================================
-- transit_seed.sql - DỮ LIỆU MINH HỌA cho các bảng tuyến / trạm / xe.
--
-- CẢNH BÁO: Đây là dữ liệu MẪU phục vụ chạy thử và demo đồ án,
-- KHÔNG phải dữ liệu vận hành chính thức. Tọa độ nằm trong khu vực
-- TP.HCM và được sắp xếp nhất quán giữa tuyến - trạm - xe - polyline.
--
-- Cách chạy (sau khi đã chạy BusGo.sql và transit_schema.sql):
--   mysql -u root BusGo < transit_seed.sql
-- Script có thể chạy lại nhiều lần: các dòng demo (id cố định) được
-- xóa trước khi chèn lại.
--
-- Nội dung:
--   2 tuyến (01, 04), mỗi tuyến có chiều đi (0) và chiều về (1).
--   Mỗi chiều có 6-7 trạm, kèm polyline route_points.
--   3 xe buýt, 3 vị trí mẫu trong bus_locations.
-- ============================================================

USE BusGo;

-- Xóa dữ liệu demo cũ (chỉ các id demo) để chạy lại không bị trùng.
DELETE FROM bus_locations WHERE bus_id IN (1, 2, 3);
DELETE FROM buses        WHERE id IN (1, 2, 3);
DELETE FROM route_points WHERE route_id IN (1, 2);
DELETE FROM route_stops  WHERE route_id IN (1, 2);
DELETE FROM routes       WHERE id IN (1, 2);
DELETE FROM stops        WHERE id BETWEEN 1 AND 13;

-- ------------------------------------------------------------
-- Trạm xe buýt.
-- ------------------------------------------------------------
INSERT INTO stops (id, stop_code, stop_name, address, latitude, longitude, status) VALUES
  (1,  'ST-001', 'Bến Thành',            'Trần Hưng Đạo, Quận 1',      10.7719, 106.6980, 'active'),
  (2,  'ST-002', 'Nhà thờ Đức Bà',       'Công xã Paris, Quận 1',      10.7798, 106.6990, 'active'),
  (3,  'ST-003', 'Bưu điện TP.HCM',      'Công xã Paris, Quận 1',      10.7796, 106.6999, 'active'),
  (4,  'ST-004', 'Hồ Con Rùa',           'Phạm Ngọc Thạch, Quận 3',    10.7829, 106.6956, 'active'),
  (5,  'ST-005', 'Chợ Lớn',              'Nguyễn Trãi, Quận 5',        10.7489, 106.6500, 'active'),
  (6,  'ST-006', 'Bến xe Chợ Lớn',       'Nguyễn Văn Cừ, Quận 5',      10.7527, 106.6588, 'active'),
  (7,  'ST-007', 'Sân bay Tân Sơn Nhất', 'Trường Sơn, Tân Bình',       10.8188, 106.6523, 'active'),
  (8,  'ST-008', 'Cộng Hòa',             'Cộng Hòa, Tân Bình',         10.8010, 106.6590, 'active'),
  (9,  'ST-009', 'Bến xe Miền Đông',     'Quốc lộ 13, Bình Thạnh',     10.8146, 106.7117, 'active'),
  (10, 'ST-010', 'Cầu Thị Nghè',         'Nguyễn Hữu Cảnh, Bình Thạnh',10.7899, 106.7030, 'active'),
  (11, 'ST-011', 'Công viên Tao Đàn',    'Nguyễn Thị Minh Khai, Q.1',  10.7743, 106.6923, 'active'),
  (12, 'ST-012', 'Bệnh viện Chợ Rẫy',    'Nguyễn Chí Thanh, Quận 5',   10.7562, 106.6607, 'active'),
  (13, 'ST-013', 'Đại học Sài Gòn',      'An Dương Vương, Quận 5',     10.7599, 106.6822, 'active');

-- ------------------------------------------------------------
-- Tuyến xe buýt.
-- ------------------------------------------------------------
INSERT INTO routes
  (id, route_code, route_name, start_point, end_point, color, start_time, end_time, frequency_minutes, fare, status)
VALUES
  (1, '01', 'Bến Thành - Chợ Lớn', 'Bến Thành', 'Chợ Lớn', '#1E88E5', '05:00', '21:00', 15, 7000, 'active'),
  (2, '04', 'Bến xe Miền Đông - Sân bay Tân Sơn Nhất', 'Bến xe Miền Đông', 'Sân bay Tân Sơn Nhất', '#E53935', '05:30', '20:30', 20, 8000, 'active');

-- ------------------------------------------------------------
-- Trạm của tuyến theo từng chiều.
--   direction 0 = chiều đi, 1 = chiều về.
-- ------------------------------------------------------------
INSERT INTO route_stops (route_id, stop_id, direction, stop_order, estimated_minutes_from_start) VALUES
  -- Tuyến 01 - chiều đi: Bến Thành -> Chợ Lớn
  (1, 1,  0, 1, 0),
  (1, 2,  0, 2, 3),
  (1, 3,  0, 3, 5),
  (1, 11, 0, 4, 10),
  (1, 13, 0, 5, 15),
  (1, 12, 0, 6, 20),
  (1, 5,  0, 7, 28),
  -- Tuyến 01 - chiều về: Chợ Lớn -> Bến Thành
  (1, 5,  1, 1, 0),
  (1, 12, 1, 2, 8),
  (1, 13, 1, 3, 13),
  (1, 11, 1, 4, 18),
  (1, 3,  1, 5, 23),
  (1, 2,  1, 6, 25),
  (1, 1,  1, 7, 28),

  -- Tuyến 04 - chiều đi: Bến xe Miền Đông -> Sân bay Tân Sơn Nhất
  (2, 9,  0, 1, 0),
  (2, 10, 0, 2, 8),
  (2, 1,  0, 3, 18),
  (2, 2,  0, 4, 24),
  (2, 8,  0, 5, 35),
  (2, 7,  0, 6, 45),
  -- Tuyến 04 - chiều về: Sân bay Tân Sơn Nhất -> Bến xe Miền Đông
  (2, 7,  1, 1, 0),
  (2, 8,  1, 2, 10),
  (2, 2,  1, 3, 21),
  (2, 1,  1, 4, 27),
  (2, 10, 1, 5, 37),
  (2, 9,  1, 6, 45);

-- ------------------------------------------------------------
-- Polyline của tuyến (tọa độ bám theo trục đường chính).
-- ------------------------------------------------------------
INSERT INTO route_points (route_id, direction, point_order, latitude, longitude) VALUES
  -- Tuyến 01 - chiều đi
  (1, 0, 1, 10.7719, 106.6980),
  (1, 0, 2, 10.7750, 106.6975),
  (1, 0, 3, 10.7798, 106.6990),
  (1, 0, 4, 10.7796, 106.6999),
  (1, 0, 5, 10.7770, 106.6960),
  (1, 0, 6, 10.7743, 106.6923),
  (1, 0, 7, 10.7599, 106.6822),
  (1, 0, 8, 10.7562, 106.6607),
  (1, 0, 9, 10.7489, 106.6500),
  -- Tuyến 01 - chiều về
  (1, 1, 1, 10.7489, 106.6500),
  (1, 1, 2, 10.7562, 106.6607),
  (1, 1, 3, 10.7599, 106.6822),
  (1, 1, 4, 10.7743, 106.6923),
  (1, 1, 5, 10.7770, 106.6960),
  (1, 1, 6, 10.7796, 106.6999),
  (1, 1, 7, 10.7798, 106.6990),
  (1, 1, 8, 10.7750, 106.6975),
  (1, 1, 9, 10.7719, 106.6980),

  -- Tuyến 04 - chiều đi
  (2, 0, 1,  10.8146, 106.7117),
  (2, 0, 2,  10.8060, 106.7080),
  (2, 0, 3,  10.7899, 106.7030),
  (2, 0, 4,  10.7830, 106.7005),
  (2, 0, 5,  10.7796, 106.6999),
  (2, 0, 6,  10.7798, 106.6990),
  (2, 0, 7,  10.7719, 106.6980),
  (2, 0, 8,  10.7850, 106.6750),
  (2, 0, 9,  10.8010, 106.6590),
  (2, 0, 10, 10.8188, 106.6523),
  -- Tuyến 04 - chiều về
  (2, 1, 1,  10.8188, 106.6523),
  (2, 1, 2,  10.8010, 106.6590),
  (2, 1, 3,  10.7850, 106.6750),
  (2, 1, 4,  10.7719, 106.6980),
  (2, 1, 5,  10.7798, 106.6990),
  (2, 1, 6,  10.7796, 106.6999),
  (2, 1, 7,  10.7830, 106.7005),
  (2, 1, 8,  10.7899, 106.7030),
  (2, 1, 9,  10.8060, 106.7080),
  (2, 1, 10, 10.8146, 106.7117);

-- ------------------------------------------------------------
-- Xe buýt.
-- ------------------------------------------------------------
INSERT INTO buses (id, bus_code, license_plate, route_id, status) VALUES
  (1, 'BUS-001', '51B-12345', 1, 'RUNNING'),
  (2, 'BUS-002', '51B-23456', 1, 'ACTIVE'),
  (3, 'BUS-003', '51B-34567', 2, 'RUNNING');

-- ------------------------------------------------------------
-- Vị trí mẫu của xe (dữ liệu minh họa, không phải GPS thực).
-- ------------------------------------------------------------
INSERT INTO bus_locations (bus_id, latitude, longitude, speed, heading, recorded_at) VALUES
  (1, 10.7750, 106.6975, 25, 90,  NOW() - INTERVAL 2 MINUTE),
  (2, 10.7489, 106.6500, 18, 270, NOW() - INTERVAL 5 MINUTE),
  (3, 10.7899, 106.7030, 30, 200, NOW() - INTERVAL 1 MINUTE);
