

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
