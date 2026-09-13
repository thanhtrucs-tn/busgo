// app_notification.dart
// Model dai dien cho mot thong bao trong ung dung BusGo.
// Moi thong bao co loai (kind), tieu de, noi dung, thoi gian va trang thai da doc.

enum NotificationKind {
  arrival, // Xe sap den tram
  issue, // Su co / thay doi tuyen
  news, // Tin tuc / cap nhat he thong
  account, // Tai khoan
}

enum NotificationCategory {
  route, // Tuyen xe
  system, // He thong
}

class AppNotification {
  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime time;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });

  // Phan loai lon: thong bao tuyen xe hoac he thong.
  NotificationCategory get category => switch (kind) {
    NotificationKind.arrival ||
    NotificationKind.issue => NotificationCategory.route,
    NotificationKind.news ||
    NotificationKind.account => NotificationCategory.system,
  };

  // Tao ban sao voi trang thai da doc moi (dung khi danh dau da doc).
  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      kind: kind,
      title: title,
      body: body,
      time: time,
      isRead: isRead ?? this.isRead,
    );
  }
}
