// user_account.dart
// Model đại diện cho tài khoản người dùng đã đăng nhập (JWT).
//
// Ví dụ JSON từ API login:
//   "user": { "id": 1, "username": "nguyenvana", "name": "Nguyễn Văn A",
//             "email": "a@example.com", "role": "user" }

class UserAccount {
  // Khóa chính của tài khoản trong bảng users.
  final int id;

  // Tên đăng nhập (tối đa 32 ký tự theo cấu trúc database).
  final String username;

  // Tên hiển thị (mặc định bằng username nếu không nhập).
  final String name;

  // Email (có thể rỗng nếu người dùng không nhập).
  final String email;

  // Phân quyền: 'user' hoặc 'admin'.
  final String role;

  const UserAccount({
    required this.id,
    required this.username,
    this.name = '',
    this.email = '',
    this.role = 'user',
  });

  // Chuyển dữ liệu JSON từ server thành đối tượng UserAccount.
  // Ví dụ: UserAccount.fromJson(json['user'] as Map<String, dynamic>);
  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
    );
  }

  // Chuyển đối tượng UserAccount thành JSON (lưu vào secure storage).
  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'email': email,
        'role': role,
      };
}