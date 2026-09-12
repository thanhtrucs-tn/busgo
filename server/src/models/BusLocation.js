// ------------------------------------------------------------
// models/BusLocation.js - Model Sequelize cho bảng bus_locations.
//
// Mỗi dòng là một lần cập nhật vị trí của xe buýt (do tài xế/thiết bị GPS
// gửi lên qua POST /api/buses/:busId/location). Bảng này chỉ ghi thêm,
// vị trí mới nhất của một xe là dòng có recorded_at lớn nhất.
// ------------------------------------------------------------

import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/db.js';

class BusLocation extends Model {}

BusLocation.init(
  {
    id: {
      type: DataTypes.INTEGER.UNSIGNED,
      autoIncrement: true,
      primaryKey: true,
    },
    busId: {
      type: DataTypes.INTEGER.UNSIGNED,
      allowNull: false,
    },
    latitude: {
      type: DataTypes.DOUBLE,
      allowNull: false,
      validate: { min: -90, max: 90 }, // Hợp lệ vĩ độ [-90, 90]
    },
    longitude: {
      type: DataTypes.DOUBLE,
      allowNull: false,
      validate: { min: -180, max: 180 }, // Hợp lệ kinh độ [-180, 180]
    },
    speed: {
      type: DataTypes.FLOAT,
      allowNull: true, // Tốc độ tức thời (km/h)
    },
    heading: {
      type: DataTypes.FLOAT,
      allowNull: true, // Hướng di chuyển (độ, 0-360)
    },
    recordedAt: {
      type: DataTypes.DATE,
      allowNull: false,
      field: 'recorded_at',
      defaultValue: DataTypes.NOW, // Thời điểm ghi nhận vị trí
    },
  },
  {
    sequelize,
    modelName: 'BusLocation',
    tableName: 'bus_locations',
    timestamps: false, // Chỉ cần recorded_at, không cần created_at/updated_at
    indexes: [{ fields: ['bus_id', 'recorded_at'] }],
  },
);

export default BusLocation;
