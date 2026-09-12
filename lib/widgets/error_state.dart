// error_state.dart
// Widget hiển thị trạng thái LỖI dùng chung: icon + thông điệp + nút thử lại.
// Giúp mọi màn hình hiển thị lỗi thống nhất khi không gọi được API.

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  // Thông điệp lỗi thân thiện (tiếng Việt).
  final String message;

  // Bấm "Thử lại" để tải lại dữ liệu (có thể null nếu không cần).
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 52, color: colors.outline),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(context.tr('retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
