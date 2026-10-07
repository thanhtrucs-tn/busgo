

import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/db.js';

class RouteStop extends Model {}

RouteStop.init(
  {
    routeId: {
      type: DataTypes.INTEGER.UNSIGNED,
      allowNull: false,
      primaryKey: true,
    },
    stopId: {
      type: DataTypes.INTEGER.UNSIGNED,
      allowNull: false,
      primaryKey: true,
    },
    direction: {
      type: DataTypes.TINYINT,
      allowNull: false,
      primaryKey: true,
      defaultValue: 0, // 0 = chiều đi, 1 = chiều về
    },
    stopOrder: {
      type: DataTypes.INTEGER,
      allowNull: false, // Thứ tự trạm trong chiều đó
    },
    estimatedMinutesFromStart: {
      type: DataTypes.INTEGER,
      allowNull: true, // Thời gian ~ từ điểm đầu đến trạm (phút)
    },
  },
  {
    sequelize,
    modelName: 'RouteStop',
    tableName: 'route_stops',
  },
);

export default RouteStop;