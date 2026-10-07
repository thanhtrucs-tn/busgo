

import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/db.js';

class RoutePoint extends Model {}

RoutePoint.init(
  {
    id: {
      type: DataTypes.INTEGER.UNSIGNED,
      autoIncrement: true,
      primaryKey: true,
    },
    routeId: {
      type: DataTypes.INTEGER.UNSIGNED,
      allowNull: false,
    },
    direction: {
      type: DataTypes.TINYINT,
      allowNull: false,
      defaultValue: 0, // 0 = chiều đi, 1 = chiều về
    },
    pointOrder: {
      type: DataTypes.INTEGER,
      allowNull: false, // Thứ tự điểm trong chuỗi polyline
    },
    latitude: {
      type: DataTypes.DOUBLE,
      allowNull: false,
      validate: { min: -90, max: 90 },
    },
    longitude: {
      type: DataTypes.DOUBLE,
      allowNull: false,
      validate: { min: -180, max: 180 },
    },
  },
  {
    sequelize,
    modelName: 'RoutePoint',
    tableName: 'route_points',
    // Mỗi tuyến/chiều không được trùng thứ tự điểm polyline.
    // Đặt tên index trùng với file SQL (transit_schema.sql) để tránh
    // tạo trùng hai index giống nhau trên cùng bảng.
    indexes: [
      {
        name: 'uk_route_points_order',
        unique: true,
        fields: ['route_id', 'direction', 'point_order'],
      },
    ],
  },
);

export default RoutePoint;