// sample_notifications.dart
// Du lieu mau (du lieu gia) cho cac thong bao cua ung dung BusGo.
// Thoi gian duoc tinh tu luc chay app de thanh "Moi nhat / Hom nay / Cu hon"
// hien thi dung theo mien thoi gian cua ngay chay thu.

import '../models/app_notification.dart';

// Tao danh sach thong bao mau voi thoi gian tuong doi so voi thoi diem hien tai.
List<AppNotification> buildSampleNotifications() {
  final DateTime now = DateTime.now();
  return [
    AppNotification(
      id: 'n1',
      kind: NotificationKind.arrival,
      title: 'Xe buýt 19 sắp đến trạm Bến Thành',
      body: 'Xe BUS-002 sắp đến trạm Bến Thành. Vui lòng chuẩn bị xuống xe.',
      time: now.subtract(const Duration(minutes: 5)),
      isRead: false,
    ),
    AppNotification(
      id: 'n2',
      kind: NotificationKind.issue,
      title: 'Sự cố tuyến 06 - Bến Thành → Biên Hòa',
      body: 'Tuyến 06 đang tạm dừng hoạt động do sự cố, vui lòng chọn tuyến khác.',
      time: now.subtract(const Duration(minutes: 40)),
      isRead: false,
    ),
    AppNotification(
      id: 'n3',
      kind: NotificationKind.news,
      title: 'Cập nhật lịch trình tuyến 01',
      body: 'Tuyến 01 mở rộng giờ hoạt động: 05:00 - 22:00 để phục vụ người dân.',
      time: now.subtract(const Duration(hours: 3)),
      isRead: false,
    ),
    AppNotification(
      id: 'n4',
      kind: NotificationKind.account,
      title: 'Đăng nhập thiết bị mới',
      body: 'Tài khoản của bạn vừa đăng nhập trên một thiết bị mới.',
      time: now.subtract(const Duration(hours: 6)),
      isRead: true,
    ),
    AppNotification(
      id: 'n5',
      kind: NotificationKind.news,
      title: 'Bảo trì hệ thống định kỳ',
      body: 'Hệ thống BusGo sẽ bảo trì vào 01:00 - 03:00 sáng Chủ nhật.',
      time: now.subtract(const Duration(days: 1, hours: 2)),
      isRead: true,
    ),
    AppNotification(
      id: 'n6',
      kind: NotificationKind.issue,
      title: 'Thay đổi điểm dừng tuyến 04',
      body: 'Điểm dừng "Cộng Hòa" tạm di dời 50m so với vị trí cũ.',
      time: now.subtract(const Duration(days: 2, hours: 5)),
      isRead: true,
    ),
  ];
}