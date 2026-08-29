// ------------------------------------------------------------
// Các hàm tiện ích giúp trả về phản hồi JSON thống nhất
// cho toàn bộ API.
//
// Định dạng chuẩn của mọi phản hồi:
//   { "success": true/false, "message": "...", "data": ... }
// ------------------------------------------------------------

// Trả về phản hồi thành công.
// Ví dụ: success(res, { username: 'admin' }, 'Đăng nhập thành công');
export function success(res, data = null, message = 'Thành công', status = 200) {
  return res.status(status).json({ success: true, message, data });
}

// Trả về phản hồi thất bại kèm mã lỗi HTTP tương ứng.
// Ví dụ: failure(res, 'Mật khẩu không đúng', 401);
export function failure(res, message = 'Đã xảy ra lỗi', status = 400) {
  return res.status(status).json({ success: false, message, data: null });
}

// Middleware xử lý lỗi ngoài ý muốn ở server (bắt lỗi cuối cùng).
export function errorHandler(err, req, res, next) {
  // Tránh lộ chi tiết lỗi kỹ thuật cho người dùng cuối.
  console.error('[Lỗi máy chủ]', err);
  return failure(res, 'Đã xảy ra lỗi máy chủ, vui lòng thử lại sau', 500);
}

// Chuyển đổi chuỗi lỗi từ cơ sở dữ liệu sang thông điệp thân thiện.
// Ví dụ: lỗi trùng khóa duy nhất khi đăng ký tài khoản trùng tên.
export function dbErrorMessage(err) {
  if (err && err.code === 'ER_DUP_ENTRY') {
    return 'Tên đăng nhập đã tồn tại, vui lòng chọn tên khác';
  }
  return 'Lỗi cơ sở dữ liệu, vui lòng thử lại sau';
}