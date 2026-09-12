// ------------------------------------------------------------
// models/Profile.js - Model Sequelize cho bảng profiles (hồ sơ mở rộng).
//
// Vì sao tách riêng khỏi bảng users?
//  - Bảng users chỉ giữ thông tin đăng nhập (username, password, email, role).
//  - Các thông tin hồ sơ như số điện thoại, ngày sinh, địa chỉ, ảnh đại diện
//    được tách sang bảng profiles.
//
// QUAN TRỌNG: mỗi tài khoản chỉ có DUY NHẤT một hồ sơ, ràng buộc bởi
// user_id (UNIQUE + khóa ngoại tới users.id). Mọi truy vấn hồ sơ BẮT BUỘC
// lọc theo user_id của người đang đăng nhập (req.user.id), không dùng ID cố định.
// ------------------------------------------------------------

import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/db.js';

class Profile extends Model {}

Profile.init(
  {
    id: {
      type: DataTypes.INTEGER.UNSIGNED,
      autoIncrement: true,
      primaryKey: true,
    },
    userId: {
      type: DataTypes.INTEGER.UNSIGNED,
      allowNull: false,
      unique: true, // Mỗi tài khoản chỉ có một hồ sơ
    },
    phone: {
      type: DataTypes.STRING(20),
      allowNull: true, // Số điện thoại (10 chữ số), có thể bỏ trống
    },
    birthday: {
      type: DataTypes.DATEONLY,
      allowNull: true, // Ngày sinh (YYYY-MM-DD)
    },
    avatar: {
      type: DataTypes.TEXT('medium'),
      allowNull: true, // Ảnh đại diện lưu dạng chuỗi base64
    },
    addresses: {
      type: DataTypes.TEXT,
      allowNull: true, // Danh sách địa chỉ lưu dạng JSON: ["...", "..."]
    },
    defaultAddressIndex: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0, // Vị trí địa chỉ mặc định trong danh sách
    },
    locationLat: {
      type: DataTypes.DOUBLE,
      allowNull: true, // Vĩ độ của địa chỉ chính (nếu lấy từ GPS)
    },
    locationLng: {
      type: DataTypes.DOUBLE,
      allowNull: true, // Kinh độ của địa chỉ chính (nếu lấy từ GPS)
    },
  },
  {
    sequelize,
    modelName: 'Profile',
    tableName: 'profiles',
  },
);

export default Profile;
