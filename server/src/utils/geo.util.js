// ------------------------------------------------------------
// utils/geo.util.js - Các hàm tính toán địa lý dùng chung.
//
//  - haversineMeters: khoảng cách đường chim bay giữa 2 tọa độ (mét).
//  - nearestPointIndex: tìm điểm gần nhất trong chuỗi route_points.
//  - pathDistanceMeters: tổng khoảng cách dọc theo chuỗi điểm (mét).
//
// LƯU Ý: đây là ước lượng phục vụ đồ án, KHÔNG phải dữ liệu giao thông thật.
// ------------------------------------------------------------

// Khoảng cách giữa hai tọa độ theo công thức Haversine (mét).
export function haversineMeters(lat1, lon1, lat2, lon2) {
  const R = 6371000; // Bán kính Trái Đất (mét)
  const toRad = (deg) => (deg * Math.PI) / 180;

  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// Tìm chỉ số của điểm trong chuỗi route_points gần một tọa độ nhất.
// points: [{ latitude, longitude }] đã sắp xếp theo point_order.
export function nearestPointIndex(points, latitude, longitude) {
  let bestIndex = 0;
  let bestDistance = Infinity;

  for (let i = 0; i < points.length; i += 1) {
    const d = haversineMeters(
      latitude,
      longitude,
      points[i].latitude,
      points[i].longitude,
    );
    if (d < bestDistance) {
      bestDistance = d;
      bestIndex = i;
    }
  }
  return bestIndex;
}

// Tổng khoảng cách dọc theo chuỗi điểm từ fromIndex đến toIndex (mét).
// Nếu fromIndex >= toIndex trả về 0.
export function pathDistanceMeters(points, fromIndex, toIndex) {
  if (fromIndex >= toIndex) return 0;

  let total = 0;
  for (let i = fromIndex; i < toIndex; i += 1) {
    total += haversineMeters(
      points[i].latitude,
      points[i].longitude,
      points[i + 1].latitude,
      points[i + 1].longitude,
    );
  }
  return total;
}
