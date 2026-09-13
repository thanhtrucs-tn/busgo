// ------------------------------------------------------------
// controllers/profile.controller.js - API HỒ SƠ CÁ NHÂN (protected).
//
//   GET /api/profile/me -> hồ sơ của chính người đang đăng nhập
//   PUT /api/profile/me -> cập nhật hồ sơ của chính người đang đăng nhập
//
// NGUYÊN TẮC BẢO MẬT QUAN TRỌNG:
//  - Chỉ dùng req.user.id (lấy từ JWT đã xác thực) để xác định hồ sơ.
//  - KHÔNG đọc userId/id từ body, query hay URL của client.
//  - Mọi truy vấn Profile đều có điều kiện where: { userId }, không có
//    truy vấn kiểu Profile.findOne() hay findByPk(1) lấy bừa hồ sơ đầu tiên.
// ------------------------------------------------------------

import Profile from '../models/Profile.js';
import User from '../models/User.js';
import { failure, success } from '../utils/response.util.js';

const EMAIL_REGEX = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
const PHONE_REGEX = /^0[0-9]{9}$/;
const ADDRESS_MAX_LENGTH = 255;
const MAX_ADDRESSES = 10;
// Giới hạn ảnh base64 (~3MB ảnh) để không làm phình bản ghi/dung lượng request.
const MAX_AVATAR_LENGTH = 4_000_000;

// Lấy hồ sơ của MỘT user_id; nếu chưa có thì tạo mới đúng cho user đó.
async function getOrCreateProfile(userId) {
  const [profile] = await Profile.findOrCreate({
    where: { userId },
    defaults: { userId },
  });
  return profile;
}

// Chuyển user + hồ sơ thành dữ liệu trả cho Flutter.
function publicProfile(user, profile) {
  return {
    id: user.id,
    username: user.username,
    name: user.name,
    email: user.email,
    role: user.role,
    phone: profile.phone || '',
    birthday: profile.birthday || null,
    avatar: profile.avatar || null,
    addresses: parseAddresses(profile.addresses),
    defaultAddressIndex: profile.defaultAddressIndex || 0,
    locationLat: profile.locationLat,
    locationLng: profile.locationLng,
  };
}

function parseAddresses(raw) {
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch (_) {
    return [];
  }
}

// ------------------------------------------------------------
// GET /api/profile/me
// ------------------------------------------------------------
export async function getMyProfile(req, res) {
  try {
    const profile = await getOrCreateProfile(req.user.id);
    return success(res, publicProfile(req.user, profile), 'Lấy hồ sơ thành công');
  } catch (err) {
    console.error('[Lỗi lấy hồ sơ]', err.message);
    return failure(res, 'Lỗi lấy hồ sơ, vui lòng thử lại sau', 500);
  }
}

// ------------------------------------------------------------
// PUT /api/profile/me
// Body: { name, email, phone, birthday, avatar, addresses,
//         defaultAddressIndex, locationLat, locationLng, password? }
// ------------------------------------------------------------
export async function updateMyProfile(req, res) {
  const userId = req.user.id; // Chỉ tin user_id từ JWT
  const body = req.body || {};

  const validationError = validateProfileInput(body);
  if (validationError) {
    return failure(res, validationError, 400);
  }

  const name = body.name.trim();
  const email = (body.email || '').trim() || null;
  const phone = (body.phone || '').trim() || null;
  const birthday = (body.birthday || '').trim() || null;
  const avatar = typeof body.avatar === 'string' && body.avatar ? body.avatar : null;

  const addresses = (Array.isArray(body.addresses) ? body.addresses : [])
    .map((a) => String(a).trim())
    .filter((a) => a.length > 0);

  let defaultAddressIndex = Number(body.defaultAddressIndex);
  if (!Number.isInteger(defaultAddressIndex) || defaultAddressIndex < 0) {
    defaultAddressIndex = 0;
  }
  if (addresses.length === 0) {
    defaultAddressIndex = 0;
  } else if (defaultAddressIndex >= addresses.length) {
    defaultAddressIndex = addresses.length - 1;
  }

  try {
    // Kiểm tra email mới có bị tài khoản KHÁC dùng chưa.
    if (email && email !== req.user.email) {
      const existing = await User.findOne({ where: { email } });
      if (existing && existing.id !== userId) {
        return failure(res, 'Email đã được sử dụng, vui lòng dùng email khác', 409);
      }
    }

    // Cập nhật tên/email trên bảng users (thông tin tài khoản).
    req.user.name = name;
    req.user.email = email;
    await req.user.save();

    // Cập nhật hồ sơ mở rộng, LUÔN giới hạn theo userId của token.
    const profile = await getOrCreateProfile(userId);
    profile.phone = phone;
    profile.birthday = birthday;
    profile.avatar = avatar;
    profile.addresses = addresses.length ? JSON.stringify(addresses) : null;
    profile.defaultAddressIndex = defaultAddressIndex;
    // Không gửi tọa độ (undefined) hoặc gửi null đều hiểu là xóa vị trí đã lưu.
    profile.locationLat = body.locationLat == null ? null : Number(body.locationLat);
    profile.locationLng = body.locationLng == null ? null : Number(body.locationLng);
    await profile.save();

    return success(res, publicProfile(req.user, profile), 'Cập nhật hồ sơ thành công');
  } catch (err) {
    if (err.name === 'SequelizeUniqueConstraintError') {
      return failure(res, 'Email đã được sử dụng, vui lòng dùng email khác', 409);
    }
    console.error('[Lỗi cập nhật hồ sơ]', err.message);
    return failure(res, 'Lỗi cập nhật hồ sơ, vui lòng thử lại sau', 500);
  }
}

// Kiểm tra toàn bộ dữ liệu đầu vào; trả null nếu hợp lệ.
function validateProfileInput(body) {
  if (typeof body.name !== 'string' || !body.name.trim()) {
    return 'Vui lòng nhập họ và tên';
  }
  if (body.name.trim().length > 50) {
    return 'Họ và tên tối đa 50 ký tự';
  }

  if (typeof body.email !== 'string' && body.email != null) {
    return 'Email không hợp lệ';
  }
  const email = (body.email || '').trim();
  if (email) {
    if (email.length > 48) return 'Email tối đa 48 ký tự';
    if (!EMAIL_REGEX.test(email)) return 'Email không đúng định dạng';
  }

  if (typeof body.phone !== 'string' && body.phone != null) {
    return 'Số điện thoại không hợp lệ';
  }
  const phone = (body.phone || '').trim();
  if (phone && !PHONE_REGEX.test(phone)) {
    return 'Số điện thoại gồm 10 chữ số, bắt đầu bằng số 0';
  }

  if (typeof body.birthday !== 'string' && body.birthday != null) {
    return 'Ngày sinh không hợp lệ';
  }
  const birthday = (body.birthday || '').trim();
  if (birthday && Number.isNaN(Date.parse(birthday))) {
    return 'Ngày sinh không hợp lệ';
  }

  if (body.avatar !== undefined && body.avatar !== null) {
    if (typeof body.avatar !== 'string') return 'Ảnh đại diện không hợp lệ';
    if (body.avatar.length > MAX_AVATAR_LENGTH) {
      return 'Ảnh đại diện quá lớn, vui lòng chọn ảnh nhỏ hơn';
    }
  }

  if (body.addresses !== undefined && !Array.isArray(body.addresses)) {
    return 'Danh sách địa chỉ không hợp lệ';
  }
  const addresses = Array.isArray(body.addresses) ? body.addresses : [];
  if (addresses.length > MAX_ADDRESSES) {
    return `Chỉ được lưu tối đa ${MAX_ADDRESSES} địa chỉ`;
  }
  for (const address of addresses) {
    if (typeof address !== 'string') return 'Địa chỉ không hợp lệ';
    if (address.trim().length > ADDRESS_MAX_LENGTH) {
      return `Mỗi địa chỉ tối đa ${ADDRESS_MAX_LENGTH} ký tự`;
    }
  }

  const hasLat = body.locationLat !== undefined && body.locationLat !== null;
  const hasLng = body.locationLng !== undefined && body.locationLng !== null;
  if (hasLat !== hasLng) {
    return 'Tọa độ vị trí không hợp lệ';
  }
  if (hasLat) {
    const lat = Number(body.locationLat);
    const lng = Number(body.locationLng);
    if (!Number.isFinite(lat) || lat < -90 || lat > 90) {
      return 'Vĩ độ không hợp lệ (phải trong khoảng -90 đến 90)';
    }
    if (!Number.isFinite(lng) || lng < -180 || lng > 180) {
      return 'Kinh độ không hợp lệ (phải trong khoảng -180 đến 180)';
    }
  }

  return null;
}
