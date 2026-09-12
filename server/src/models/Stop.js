// ------------------------------------------------------------
// models/Stop.js - Model Sequelize cho bảng stops (trạm xe buýt).
// ------------------------------------------------------------

import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/db.js';

class Stop extends Model {}

Stop.init(
  {
    id: {
      type: DataTypes.INTEGER.UNSIGNED,
      autoIncrement: true,
      primaryKey: true,
    },
    stopCode: {
      type: DataTypes.STRING(20),
      allowNull: false,
      unique: true, // Mã trạm, vd: "ST-001"
    },
    stopName: {
      type: DataTypes.STRING(255),
      allowNull: false,
    },
    address: {
      type: DataTypes.STRING(255),
      allowNull: true,
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
    status: {
      type: DataTypes.STRING(20),
      allowNull: false,
      defaultValue: 'active',
    },
  },
  {
    sequelize,
    modelName: 'Stop',
    tableName: 'stops',
  },
);

export default Stop;