// user_account.dart
// Model đại diện cho tài khoản người dùng đã đăng nhập.
// Dữ liệu được trả về từ API đăng nhập (backend Node.js + MySQL).
//
// Ví dụ JSON từ server:
//   { "success": true, "message": "Đăng nhập thành công", "data": { "id": 1, "username": "admin" } }

class UserAccount {
  // Khóa chính của tài khoản trong bảng users.
  final int id;

  // Tên đăng nhập (tối đa 32 ký tự theo cấu trúc database).
  final String username;

  const UserAccount({required this.id, required this.username});

  // Chuyển dữ liệu JSON từ server thành đối tượng UserAccount.
  // Ví dụ: UserAccount.fromJson(json['data'] as Map<String, dynamic>);
  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
    );
  }

  // Chuyển đối tượng UserAccount thành JSON (nếu cần gửi dữ liệu lên server).
  Map<String, dynamic> toJson() => {'id': id, 'username': username};
}
