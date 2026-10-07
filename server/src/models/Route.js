

import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/db.js';

class Route extends Model {}

Route.init(
  {
    id: {
      type: DataTypes.INTEGER.UNSIGNED,
      autoIncrement: true,
      primaryKey: true,
    },
    routeCode: {
      type: DataTypes.STRING(20),
      allowNull: false,
      unique: true, // Mã tuyến không trùng, vd: "01", "04"
    },
    routeName: {
      type: DataTypes.STRING(255),
      allowNull: false,
    },
    startPoint: {
      type: DataTypes.STRING(255),
      allowNull: false,
    },
    endPoint: {
      type: DataTypes.STRING(255),
      allowNull: false,
    },
    color: {
      type: DataTypes.STRING(20),
      allowNull: true, // Màu vẽ polyline, vd: "#1E88E5"
    },
    startTime: {
      type: DataTypes.STRING(10),
      allowNull: true, // Giờ mở bán, vd: "05:00"
    },
    endTime: {
      type: DataTypes.STRING(10),
      allowNull: true, // Giờ kết thúc, vd: "21:00"
    },
    frequencyMinutes: {
      type: DataTypes.INTEGER,
      allowNull: true, // Tần suất chuyến (phút)
    },
    fare: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: true, // Giá vé (VNĐ)
    },
    status: {
      type: DataTypes.STRING(20),
      allowNull: false,
      defaultValue: 'active', // active | inactive
    },
  },
  {
    sequelize,
    modelName: 'Route',
    tableName: 'routes',
  },
);

export default Route;