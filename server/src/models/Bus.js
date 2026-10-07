

import { DataTypes, Model } from 'sequelize';
import { sequelize } from '../config/db.js';

class Bus extends Model {}

Bus.init(
  {
    id: {
      type: DataTypes.INTEGER.UNSIGNED,
      autoIncrement: true,
      primaryKey: true,
    },
    busCode: {
      type: DataTypes.STRING(30),
      allowNull: false,
      unique: true, // Mã xe không trùng, vd: "BUS-001"
    },
    licensePlate: {
      type: DataTypes.STRING(20),
      allowNull: false,
      unique: true, // Biển số không trùng
    },
    routeId: {
      type: DataTypes.INTEGER.UNSIGNED,
      allowNull: false,
    },
    status: {
      type: DataTypes.STRING(20),
      allowNull: false,
      defaultValue: 'ACTIVE', // ACTIVE | RUNNING | INACTIVE
    },
  },
  {
    sequelize,
    modelName: 'Bus',
    tableName: 'buses',
  },
);

export default Bus;