// ------------------------------------------------------------
// Middleware kiểm tra dữ liệu đầu vào trước khi xử lý.
// Độ dài tối đa được đặt KHỚP với cấu trúc bảng users:
//   - username tối đa 32 ký tự
//   - password tối đa 64 ký tự
// ------------------------------------------------------------

// Hằng số giới hạn được dùng chung (validate + hướng dẫn ở tầng giao diện).
export const USERNAME_MIN = 3;
export const USERNAME_MAX = 32;
export const PASSWORD_MIN = 6;
export const PASSWORD_MAX = 64;

// Kiểm tra dữ liệu hợp lệ cho chức năng ĐĂNG KÝ.
export function validateRegister(req, res, next) {
  const { username, password } = req.body || {};

  // Tên đăng nhập: bắt buộc, dài từ 3 đến 32 ký tự.
  if (!username || typeof username !== 'string') {
    return res.status(400).json({
      success: false,
      message: 'Vui lòng nhập tên đăng nhập',
      data: null,
    });
  }
  const name = username.trim();
  if (name.length < USERNAME_MIN || name.length > USERNAME_MAX) {
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

  // Thay giá trị đã chuẩn hóa vào body để xử lý tiếp.
  req.body = { username: name, password };
  return next();
}

// Kiểm tra dữ liệu hợp lệ cho chức năng ĐĂNG NHẬP.
export function validateLogin(req, res, next) {
  const { username, password } = req.body || {};

  if (!username || !password) {
    return res.status(400).json({
      success: false,
      message: 'Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu',
      data: null,
    });
  }

  // Giới hạn độ dài tương tự như đăng ký để khớp với cơ sở dữ liệu.
  if (username.length > USERNAME_MAX || password.length > PASSWORD_MAX) {
    return res.status(400).json({
      success: false,
      message: 'Tên đăng nhập hoặc mật khẩu vượt quá độ dài cho phép',
      data: null,
    });
  }

  req.body = { username: username.trim(), password };
  return next();
}