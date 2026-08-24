// main.dart
// Day la diem bat dau cua ung dung BusGo.
// File nay khoi tao app va cau hinh giao dien chung (theme) cho toan bo app.

import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  // runApp la ham dau tien duoc goi de chay ung dung Flutter.
  runApp(const BusGoApp());
}

// BusGoApp la widget goc (root) cua ung dung.
// StatelessWidget: widget khong co trang thai thay doi.
class BusGoApp extends StatelessWidget {
  const BusGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusGo',
      // An banner "DEBUG" o goc man hinh khi chay app.
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Mau chu dao cua app. Mau xanh la phu hop voi ung dung xe buyt.
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      ),
      // Man hinh dau tien hien thi khi mo app.
      home: const HomeScreen(),
    );
  }
}
