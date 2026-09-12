// index.js
// Bộ MÔ PHỎNG GPS xe buýt cho BusGo.
//
// Vì dự án chưa có thiết bị GPS thật trên xe, script này giả lập xe chạy dọc
// theo các tọa độ có sẵn trong bảng route_points và gửi vị trí lên backend:
//
//   1. Đọc cấu hình từ file JSON (--config=...) hoặc biến môi trường.
//   2. Lấy token: ưu tiên SIM_TOKEN; nếu không có thì đăng nhập bằng
//      SIM_USERNAME / SIM_PASSWORD qua POST /api/auth/login.
//   3. Lấy danh sách tọa độ: GET /api/routes/:routeId/path?direction=...
//   4. Cứ mỗi intervalMs lấy điểm tiếp theo và gửi:
//      POST /api/buses/:busId/location  (kèm Bearer token).
//   5. Hết chiều đi: chuyển sang chiều về hoặc quay lại điểm đầu.
//
// BẢO MẬT: KHÔNG hardcode token / mật khẩu trong mã nguồn.
// Dùng biến môi trường hoặc file config (không commit file config thật).
//
// Cách chạy: xem README.md trong cùng thư mục.

import fs from 'node:fs';
import path from 'node:path';

// Đọc cấu hình từ tham số dòng lệnh + biến môi trường.
function loadConfig() {
  const arg = process.argv.find((a) => a.startsWith('--config='));
  const configPath = arg ? arg.split('=')[1] : null;

  let fileConfig = {};
  if (configPath) {
    const resolved = path.resolve(process.cwd(), configPath);
    fileConfig = JSON.parse(fs.readFileSync(resolved, 'utf8'));
  }

  return {
    apiBaseUrl:
      process.env.SIM_API_URL ||
      fileConfig.apiBaseUrl ||
      'http://localhost:3000/api',
    busId: Number(process.env.SIM_BUS_ID || fileConfig.busId || 1),
    routeId: Number(process.env.SIM_ROUTE_ID || fileConfig.routeId || 1),
    direction: Number(process.env.SIM_DIRECTION ?? fileConfig.direction ?? 0),
    intervalMs: Number(
      process.env.SIM_INTERVAL_MS || fileConfig.intervalMs || 2500,
    ),
    defaultSpeedKmh: Number(
      process.env.SIM_SPEED_KMH || fileConfig.defaultSpeedKmh || 25,
    ),
    switchDirectionAtEnd:
      process.env.SIM_SWITCH_DIRECTION !== undefined
        ? process.env.SIM_SWITCH_DIRECTION === 'true'
        : fileConfig.switchDirectionAtEnd ?? true,
    token: process.env.SIM_TOKEN || fileConfig.token || '',
    username: process.env.SIM_USERNAME || fileConfig.username || '',
    password: process.env.SIM_PASSWORD || fileConfig.password || '',
  };
}

const config = loadConfig();
let token = config.token;
let direction = config.direction;

const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const log = (...args) =>
  console.log(`[${new Date().toISOString()}]`, ...args);

// Gọi API và luôn trả về object { ok, status, body } thay vì ném lỗi HTTP.
async function apiFetch(url, options = {}) {
  const res = await fetch(url, options);
  const text = await res.text();
  let body;
  try {
    body = JSON.parse(text);
  } catch {
    body = { message: text };
  }
  return { ok: res.ok, status: res.status, body };
}

// Bảo đảm có token hợp lệ (đăng nhập nếu cần).
async function ensureToken() {
  if (token) return token;

  if (!config.username || !config.password) {
    throw new Error(
      'Thiếu token. Hãy đặt SIM_TOKEN hoặc SIM_USERNAME/SIM_PASSWORD.',
    );
  }

  const { ok, status, body } = await apiFetch(
    `${config.apiBaseUrl}/auth/login`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        identifier: config.username,
        password: config.password,
      }),
    },
  );

  if (!ok || !body?.data?.token) {
    throw new Error(
      `Đăng nhập thất bại (${status}): ${body?.message || 'không rõ lỗi'}`,
    );
  }

  token = body.data.token;
  log('Đăng nhập thành công, đã nhận token.');
  return token;
}

// Lấy danh sách tọa độ polyline của tuyến theo chiều.
async function fetchPath(routeId, dir) {
  const { ok, status, body } = await apiFetch(
    `${config.apiBaseUrl}/routes/${routeId}/path?direction=${dir}`,
  );
  if (!ok || !Array.isArray(body?.data)) {
    throw new Error(
      `Không lấy được route_points (${status}): ${body?.message || ''}`,
    );
  }
  return body.data;
}

// Tính hướng di chuyển (độ) giữa hai tọa độ.
function bearing(lat1, lon1, lat2, lon2) {
  const toRad = (d) => (d * Math.PI) / 180;
  const toDeg = (r) => (r * 180) / Math.PI;
  const dLon = toRad(lon2 - lon1);
  const y = Math.sin(dLon) * Math.cos(toRad(lat2));
  const x =
    Math.cos(toRad(lat1)) * Math.sin(toRad(lat2)) -
    Math.sin(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.cos(dLon);
  return (toDeg(Math.atan2(y, x)) + 360) % 360;
}

// Gửi một vị trí lên backend.
async function sendLocation(busId, routeId, point, heading) {
  return apiFetch(`${config.apiBaseUrl}/buses/${busId}/location`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      routeId,
      latitude: point.latitude,
      longitude: point.longitude,
      speed: config.defaultSpeedKmh,
      heading: Math.round(heading),
    }),
  });
}

let running = true;
process.on('SIGINT', () => {
  log('Đang dừng bộ mô phỏng...');
  running = false;
});

async function main() {
  log(
    `Bộ mô phỏng GPS BusGo: bus=${config.busId}, route=${config.routeId}, ` +
      `chu kỳ ${config.intervalMs}ms`,
  );

  await ensureToken();

  let points = await fetchPath(config.routeId, direction);
  if (points.length < 2) {
    throw new Error('route_points không đủ để mô phỏng (cần ít nhất 2 điểm).');
  }

  let index = 0;
  let prev = points[0];

  while (running) {
    const point = points[index];
    const heading =
      index === 0
        ? 0
        : bearing(prev.latitude, prev.longitude, point.latitude, point.longitude);

    let result;
    try {
      result = await sendLocation(config.busId, config.routeId, point, heading);
    } catch (err) {
      log(`Lỗi mạng khi gửi vị trí: ${err.message}`);
      await delay(config.intervalMs);
      continue;
    }

    const resultText = result.ok
      ? 'OK'
      : `LỖI ${result.status} - ${result.body?.message || ''}`;
    log(
      `BUS ${config.busId} | chiều ${direction} | điểm ${index + 1}/` +
        `${points.length} | (${point.latitude}, ${point.longitude}) | ${resultText}`,
    );

    prev = point;
    index += 1;

    // Hết danh sách điểm: đổi chiều hoặc quay lại điểm đầu.
    if (index >= points.length) {
      if (config.switchDirectionAtEnd) {
        direction = direction === 0 ? 1 : 0;
        points = await fetchPath(config.routeId, direction);
        log(`→ Đổi sang chiều ${direction}.`);
      } else {
        log('→ Quay lại điểm đầu.');
      }
      index = 0;
      prev = points[0];
    }

    await delay(config.intervalMs);
  }

  log('Đã dừng bộ mô phỏng.');
}

main().catch((err) => {
  console.error('[LỖI]', err.message);
  process.exit(1);
});
