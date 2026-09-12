# BusGo – Bộ mô phỏng GPS xe buýt

Công cụ dòng lệnh giả lập xe buýt chạy dọc theo `route_points` của một tuyến
và gửi vị trí lên API BusGo theo chu kỳ. Dùng thay cho thiết bị GPS thật khi
chạy thử đồ án.

> Đây là **dữ liệu mô phỏng**, không phải vị trí xe thật.

## Yêu cầu

- Node.js >= 18 (đã có sẵn `fetch`).
- Backend BusGo đang chạy (mặc định `http://localhost:3000`).
- Database đã có dữ liệu tuyến/trạm/`route_points` (xem `server/sql/transit_seed.sql`).
- Một tài khoản **admin** để lấy token (endpoint cập nhật vị trí yêu cầu quyền admin).

## Cấu hình

Sao chép file mẫu rồi điền thông tin, **không commit file cấu hình thật**:

```bash
cp config.example.json config.json
```

| Trường | Ý nghĩa | Ví dụ |
|--------|---------|-------|
| `apiBaseUrl` | Địa chỉ API backend (có `/api`) | `http://localhost:3000/api` |
| `busId` | Mã xe gửi vị trí | `1` |
| `routeId` | Tuyến xe đang chạy | `1` |
| `direction` | Chiều ban đầu: `0` = đi, `1` = về | `0` |
| `intervalMs` | Chu kỳ gửi (mili giây) | `2500` |
| `defaultSpeedKmh` | Tốc độ giả lập | `25` |
| `switchDirectionAtEnd` | Hết chiều thì đổi chiều (`true`) hay quay lại điểm đầu (`false`) | `true` |

Có thể ghi đè mọi giá trị bằng biến môi trường: `SIM_API_URL`, `SIM_BUS_ID`,
`SIM_ROUTE_ID`, `SIM_DIRECTION`, `SIM_INTERVAL_MS`, `SIM_SPEED_KMH`,
`SIM_SWITCH_DIRECTION`.

## Lấy token (không hardcode mật khẩu)

Ưu tiên truyền token trực tiếp:

```bash
# Windows PowerShell
$env:SIM_TOKEN = "<JWT của tài khoản admin>"
node index.js --config=config.json
```

Hoặc để script tự đăng nhập (cần tài khoản admin):

```bash
# Windows PowerShell
$env:SIM_USERNAME = "ten_admin"
$env:SIM_PASSWORD = "mat_khau_admin"
node index.js --config=config.json
```

Lấy token admin bằng API:

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"identifier\":\"ten_admin\",\"password\":\"mat_khau_admin\"}"
```

> Nếu tài khoản chưa phải admin, chạy trong MySQL:
> `UPDATE users SET role='admin' WHERE username='ten_admin';`

## Chạy

```bash
cd tools/gps-simulator
node index.js --config=config.json
```

Log mẫu:

```text
[2026-09-12T...Z] Bộ mô phỏng GPS BusGo: bus=1, route=1, chu kỳ 2500ms
[2026-09-12T...Z] BUS 1 | chiều 0 | điểm 1/9 | (10.7719, 106.698) | OK
[2026-09-12T...Z] BUS 1 | chiều 0 | điểm 2/9 | (10.775, 106.6975) | OK
...
[2026-09-12T...Z] → Đổi sang chiều 1.
```

Nhấn `Ctrl + C` để dừng.

## Cách hoạt động

1. Đọc cấu hình (file + biến môi trường).
2. Lấy token (có sẵn hoặc đăng nhập).
3. `GET /api/routes/:routeId/path?direction=...` để lấy `route_points`.
4. Mỗi chu kỳ gửi `POST /api/buses/:busId/location` với tọa độ tiếp theo.
5. Hết chiều thì đổi chiều hoặc quay lại điểm đầu.

Backend lưu vị trí vào MySQL và phát sự kiện Socket.IO `bus:location-updated`
tới phòng `route:<routeId>` để Flutter cập nhật marker xe.
