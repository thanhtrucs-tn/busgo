// Test kiem tra ung dung hien thi man hinh DANG NHAP dau tien
// (truoc khi dang nhap thanh cong moi vao duoc trang chu).
//
// LUU Y: app mo dau bang AuthGate - kiem tra JWT trong secure storage.
// Trong moi truong test khong co plugin that, ta gia lap (mock) MethodChannel
// cua flutter_secure_storage de no tra ve "khong co token" -> app hien man hinh
// dang nhap giong nhu may chua tung dang nhap lan nao.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:busgo/main.dart';

void main() {
  // Gia lap kenh luu tru an toan: moi thao tac tra ve null (khong co du lieu).
  setUp(() {
    const MethodChannel channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          null,
        );
  });

  testWidgets('BusGo hien thi man hinh dang nhap', (WidgetTester tester) async {
    // Khoi tao app va chay mot frame dau tien.
    await tester.pumpWidget(const BusGoApp());
    // Cho AuthGate kiem tra JWT xong + MaterialApp nap du lieu da ngon ngu.
    await tester.pumpAndSettle();

    // Kiem tra man hinh dang nhap co hien thi hay khong.
    // Vi du: tieu de "Đăng nhập BusGo", o nhap ten va mat khau.
    expect(find.text('Đăng nhập BusGo'), findsOneWidget);
    expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
    expect(find.text('Tên đăng nhập'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
  });
}