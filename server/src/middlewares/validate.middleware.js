

const USERNAME_MIN = 3;
const USERNAME_MAX = 32;
const PASSWORD_MIN = 6;
const PASSWORD_MAX = 64;
const EMAIL_MAX = 48;
const NAME_MAX = 50;

const USERNAME_REGEX = /^[a-zA-Z0-9_]+$/;

// Định dạng email tiêu chuẩn, ví dụ: abc@example.com
const EMAIL_REGEX = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

// Trả lỗi 400 theo đúng cấu trúc response chung của API.
function badRequest(res, message) {
  return res.status(400).json({ success: false, message, data: null });
}

// Kiểm tra dữ liệu hợp lệ cho chức năng ĐĂNG KÝ.
export function validateRegister(req, res, next) {
  const { username, password, email, name } = req.body || {};

  // Tên đăng nhập: bắt buộc, 3-32 ký tự, chỉ chữ cái/số/gạch dưới.
  if (!username || typeof username !== 'string') {
    return badRequest(res, 'Vui lòng nhập tên đăng nhập');
  }
  const cleanedUsername = username.trim();
  if (
    cleanedUsername.length < USERNAME_MIN ||
    cleanedUsername.length > USERNAME_MAX
  ) {
    return badRequest(
      res,
      `Tên đăng nhập phải có từ ${USERNAME_MIN} đến ${USERNAME_MAX} ký tự`,
    );
  }
  if (!USERNAME_REGEX.test(cleanedUsername)) {
    return badRequest(
      res,
      'Tên đăng nhập chỉ gồm chữ cái, số và dấu gạch dưới',
    );
  }

  // Mật khẩu: bắt buộc, 6-64 ký tự.
  if (!password || typeof password !== 'string') {
    return badRequest(res, 'Vui lòng nhập mật khẩu');
  }
  if (password.length < PASSWORD_MIN || password.length > PASSWORD_MAX) {
    return badRequest(
      res,
      `Mật khẩu phải có từ ${PASSWORD_MIN} đến ${PASSWORD_MAX} ký tự`,
    );
  }

  // Email (tùy chọn): nếu có nhập thì phải là chuỗi, đúng định dạng, đủ ngắn.
  if (email !== undefined && email !== null && typeof email !== 'string') {
    return badRequest(res, 'Email không hợp lệ');
  }
  const cleanedEmail = (email || '').trim();
  if (cleanedEmail.length > EMAIL_MAX) {
    return badRequest(res, `Email tối đa ${EMAIL_MAX} ký tự`);
  }
  if (cleanedEmail && !EMAIL_REGEX.test(cleanedEmail)) {
    return badRequest(
      res,
      'Email không đúng định dạng, ví dụ: abc@example.com',
    );
  }

  // Tên hiển thị (tùy chọn): nếu có nhập thì phải là chuỗi, tối đa 50 ký tự.
  if (name !== undefined && name !== null && typeof name !== 'string') {
    return badRequest(res, 'Tên hiển thị không hợp lệ');
  }
  const cleanedName = (name || '').trim();
  if (cleanedName.length > NAME_MAX) {
    return badRequest(
      res,
      `Tên hiển thị không được quá ${NAME_MAX} ký tự`,
    );
  }

  // Thay giá trị đã chuẩn hóa vào body để controller xử lý tiếp.
  req.body = {
    username: cleanedUsername,
    password,
    email: cleanedEmail,
    name: cleanedName,
  };
  return next();
}

// Kiểm tra dữ liệu hợp lệ cho chức năng ĐĂNG NHẬP.
// identifier có thể là tên đăng nhập HOẶC email.
export function validateLogin(req, res, next) {
  const { password } = req.body || {};
  const identifier =
    req.body?.identifier || req.body?.username || req.body?.email;

  if (
    !identifier ||
    typeof identifier !== 'string' ||
    !password ||
    typeof password !== 'string'
  ) {
    return badRequest(
      res,
      'Vui lòng nhập đầy đủ tên đăng nhập (hoặc email) và mật khẩu',
    );
  }

  // Giới hạn độ dài để khớp với cơ sở dữ liệu (email tối đa 255 ký tự).
  if (identifier.length > 255) {
    return badRequest(
      res,
      'Tên đăng nhập hoặc email vượt quá độ dài cho phép',
    );
  }
  if (password.length > PASSWORD_MAX) {
    return badRequest(res, 'Mật khẩu vượt quá độ dài cho phép');
  }

  req.body = { identifier: identifier.trim(), password };
  return next();
}
