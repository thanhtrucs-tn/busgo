// Test kiem tra ung dung hien thi man hinh DANG NHAP dau tien
// (truoc khi dang nhap thanh cong moi vao duoc trang chu).

import 'package:flutter_test/flutter_test.dart';

import 'package:busgo/main.dart';

void main() {
  testWidgets('BusGo hien thi man hinh dang nhap', (WidgetTester tester) async {
    // Khoi tao app va chay mot frame dau tien.
    await tester.pumpWidget(const BusGoApp());
    // Cho MaterialApp nap xong du lieu da ngon ngu (Localizations bat dong bo).
    await tester.pumpAndSettle();

    // Kiem tra man hinh dang nhap co hien thi hay khong.
    // Vi du: tieu de "Đăng nhập BusGo", o nhap ten va mat khau.
    expect(find.text('Đăng nhập BusGo'), findsOneWidget);
    expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
    expect(find.text('Tên đăng nhập'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
  });
}
