// Test kiem tra ung dung hien thi man hinh Home voi ten "BusGo".

import 'package:flutter_test/flutter_test.dart';

import 'package:busgo/main.dart';

void main() {
  testWidgets('BusGo hien thi man hinh Home', (WidgetTester tester) async {
    // Khoi tao app va chay mot frame dau tien.
    await tester.pumpWidget(const BusGoApp());

    // Kiem tra chu "BusGo" co xuat hien tren man hinh hay khong.
    // Chu "BusGo" xuat hien 2 lan: tren AppBar va o phan gioi thieu.
    expect(find.text('BusGo'), findsWidgets);
  });
}
