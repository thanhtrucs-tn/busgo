

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
    googleId: {
      type: DataTypes.STRING(255),
      allowNull: true, // Chỉ tài khoản đăng ký bằng Google mới có
      unique: true, // Nếu có Google ID thì phải duy nhất
      field: 'google_id', // Ánh xạ đúng cột google_id trong MySQL
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