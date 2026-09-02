// ------------------------------------------------------------
// Middleware kiểm tra dữ liệu đầu vào TRƯỚC khi xử lý.
// Độ dài tối đa khớp với cấu trúc bảng users:
//   - username tối đa 32 ký tự
//   - password tối đa 64 ký tự
//   - email tối đa 255 ký tự (tùy chọn, đúng định dạng nếu có)
//   - name tối đa 50 ký tự (tùy chọn)
// ------------------------------------------------------------

// Hằng số giới hạn dùng chung (khớp với model Sequelize).
export const USERNAME_MIN = 3;
export const USERNAME_MAX = 32;
export const PASSWORD_MIN = 6;
export const PASSWORD_MAX = 64;
export const NAME_MAX = 50;

// Định dạng email tiêu chuẩn, ví dụ: abc@example.com
const EMAIL_REGEX = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

// Kiểm tra dữ liệu hợp lệ cho chức năng ĐĂNG KÝ.
export function validateRegister(req, res, next) {
  const { username, password, email, name } = req.body || {};

  // Tên đăng nhập: bắt buộc, dài từ 3 đến 32 ký tự.
  if (!username || typeof username !== 'string') {
    return res.status(400).json({
      success: false,
      message: 'Vui lòng nhập tên đăng nhập',
      data: null,
    });
  }
  const cleanedUsername = username.trim();
  if (
    cleanedUsername.length < USERNAME_MIN ||
    cleanedUsername.length > USERNAME_MAX
  ) {
    return res.status(400).json({
      success: false,
      message: `Tên đăng nhập phải có từ ${USERNAME_MIN} đến ${USERNAME_MAX} ký tự`,
      data: null,
    });
  }

  // Mật khẩu: bắt buộc, dài từ 6 đến 64 ký tự.
  if (!password || typeof password !== 'string') {
    return res.status(400).json({
      success: false,
      message: 'Vui lòng nhập mật khẩu',
      data: null,
    });
  }
  if (password.length < PASSWORD_MIN || password.length > PASSWORD_MAX) {
    return res.status(400).json({
      success: false,
      message: `Mật khẩu phải có từ ${PASSWORD_MIN} đến ${PASSWORD_MAX} ký tự`,
      data: null,
    });
  }

  // Email (tùy chọn): nếu có nhập thì phải đúng định dạng.
  const cleanedEmail = (email || '').trim();
  if (cleanedEmail && !EMAIL_REGEX.test(cleanedEmail)) {
    return res.status(400).json({
      success: false,
      message: 'Email không đúng định dạng, ví dụ: abc@example.com',
      data: null,
    });
  }

  // Tên hiển thị (tùy chọn): không quá 50 ký tự.
  const cleanedName = (name || '').trim();
  if (cleanedName.length > NAME_MAX) {
    return res.status(400).json({
      success: false,
      message: `Tên hiển thị không được quá ${NAME_MAX} ký tự`,
      data: null,
    });
  }

  // Thay giá trị đã chuẩn hóa vào body để xử lý tiếp.
  req.body = {
    username: cleanedUsername,
    password,
    email: cleanedEmail,
    name: cleanedName,
  };
  return next();
}

// Kiểm tra dữ liệu hợp lệ cho chức năng ĐĂNG NHẬP.
export function validateLogin(req, res, next) {
  const { password } = req.body || {};
  // Chấp nhận tên đăng nhập HOẶC email (cả 2 đều nằm trong 'identifier').
  const identifier =
    req.body?.identifier || req.body?.username || req.body?.email;

  if (!identifier || !password) {
    return res.status(400).json({
      success: false,
      message: 'Vui lòng nhập đầy đủ tên đăng nhập (hoặc email) và mật khẩu',
      data: null,
    });
  }

  // Giới hạn độ dài để khớp với cơ sở dữ liệu.
  if (identifier.length > USERNAME_MAX && identifier.length > 255) {
    return res.status(400).json({
      success: false,
      message: 'Tên đăng nhập hoặc email vượt quá độ dài cho phép',
      data: null,
    });
  }
  if (password.length > PASSWORD_MAX) {
    return res.status(400).json({
      success: false,
      message: 'Mật khẩu vượt quá độ dài cho phép',
      data: null,
    });
  }

  req.body = { identifier: identifier.trim(), password };
  return next();
}