// empty_state.dart
// Widget dung chung hien thi thong bao khi danh sach rong
// (khong tim thay ket qua, chua co du lieu...).
// Dung o nhieu man hinh nen tach ra de khong lap lai code.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon nam trong vong tron nen the.
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Icon(icon, size: 44, color: colors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}