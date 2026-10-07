

import User from './User.js';
import Profile from './Profile.js';
import Route from './Route.js';
import Stop from './Stop.js';
import RouteStop from './RouteStop.js';
import RoutePoint from './RoutePoint.js';
import Bus from './Bus.js';
import BusLocation from './BusLocation.js';

// Một tài khoản có một hồ sơ; xóa tài khoản thì xóa luôn hồ sơ.
User.hasOne(Profile, { foreignKey: 'userId', onDelete: 'CASCADE' });
Profile.belongsTo(User, { foreignKey: 'userId' });

// Một tuyến có nhiều dòng trong route_stops (nhiều trạm theo từng chiều).
Route.hasMany(RouteStop, { foreignKey: 'routeId' });
RouteStop.belongsTo(Route, { foreignKey: 'routeId' });

// Một trạm có nhiều dòng trong route_stops (nằm trên nhiều tuyến/chiều).
Stop.hasMany(RouteStop, { foreignKey: 'stopId' });
RouteStop.belongsTo(Stop, { foreignKey: 'stopId' });

// Quan hệ nhiều - nhiều giữa Route và Stop thông qua route_stops.
// unique: false để Sequelize KHÔNG tạo khóa duy nhất (route_id, stop_id),
// vì một trạm có thể nằm ở cả chiều đi và chiều về của cùng một tuyến.
Route.belongsToMany(Stop, {
  through: { model: RouteStop, unique: false },
  foreignKey: 'routeId',
  otherKey: 'stopId',
});
Stop.belongsToMany(Route, {
  through: { model: RouteStop, unique: false },
  foreignKey: 'stopId',
  otherKey: 'routeId',
});

// Một tuyến có nhiều điểm polyline.
Route.hasMany(RoutePoint, { foreignKey: 'routeId' });
RoutePoint.belongsTo(Route, { foreignKey: 'routeId' });

// Một tuyến có nhiều xe buýt.
Route.hasMany(Bus, { foreignKey: 'routeId' });
Bus.belongsTo(Route, { foreignKey: 'routeId' });

// Một xe có nhiều lần ghi nhận vị trí; vị trí mới nhất là recorded_at lớn nhất.
Bus.hasMany(BusLocation, { foreignKey: 'busId' });
BusLocation.belongsTo(Bus, { foreignKey: 'busId' });

// Xuất ra để server.js import một lần cho chắc chắn.
export default { User, Profile, Route, Stop, RouteStop, RoutePoint, Bus, BusLocation };