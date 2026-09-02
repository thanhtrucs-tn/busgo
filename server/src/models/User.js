// ------------------------------------------------------------
// models/User.js - Model Sequelize cho bảng users.
//
// Đây là mô hình TÀI KHOẢN NGƯỜI DÙNG duy nhất của ứng dụng.
// Bảng users đã tồn tại từ giai đoạn trước (username + password),
// chúng ta GIỮ NGUYÊN và chỉ BỔ SUNG các trường cần thiết:
//   - email       : phục vụ đăng nhập bằng email (tùy chọn)
//   - name        : tên hiển thị (mặc định bằng username)
//   - role        : phân quyền ('user' | 'admin')
//   - updated_at  : thời điểm cập nhật (Sequelize tự quản lý)
//
// QUAN TRỌNG: không tạo bảng mới, không xóa dữ liệu hiện có.
// ------------------------------------------------------------

import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/db.js';

// Định nghĩa Model User tương ứng bảng 'users'.
class User extends Model {}

User.init(
  {
    id: {
      type: DataTypes.INTEGER.UNSIGNED,
      autoIncrement: true, // Tự tăng
      primaryKey: true, // Khóa chính
    },
    username: {
      type: DataTypes.STRING(32), // Tối đa 32 ký tự (giữ nguyên từ giai đoạn trước)
      allowNull: false,
      unique: true, // Không trùng tên đăng nhập
    },
    email: {
      type: DataTypes.STRING(255),
      allowNull: true, // Không bắt buộc; NULL cho phép nhiều user bỏ trống email
      unique: true, // Nếu có email thì phải duy nhất
    },
    password: {
      type: DataTypes.STRING(64), // Chuỗi bcrypt dài 60 ký tự
      allowNull: false,
    },
    name: {
      type: DataTypes.STRING(50),
      allowNull: true, // Tên hiển thị, mặc định lấy username
    },
    role: {
      type: DataTypes.STRING(20),
      allowNull: false,
      defaultValue: 'user', // Mặc định là người dùng thường
    },
    createdAt: {
      type: DataTypes.DATE,
      field: 'created_at', // Ánh xạ đúng cột created_at trong MySQL
    },
    updatedAt: {
      type: DataTypes.DATE,
      field: 'updated_at',
    },
  },
  {
    sequelize,
    modelName: 'User',
    tableName: 'users',
  },
);

export default User;