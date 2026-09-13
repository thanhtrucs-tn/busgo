// notification_screen.dart
// Man hinh Thong bao cua ung dung BusGo.
// - Danh sach thong bao chia theo moc thoi gian: Moi nhat, Hom nay, Cu hon.
// - Moi item: icon loai, tieu de, noi dung, thoi gian, cham xanh "chua doc".
// - Loc theo tab: Tat ca, Tuyen xe, He thong.
// - Vuot phai: danh dau da doc | vuot trai: xoa.
// - Nut "Danh dau tat ca la da doc" tren AppBar.
// - Empty state khi khong co thong bao.
// Mau sac lay tu theme, van ban lay tu he thong da ngon ngu.

import 'package:flutter/material.dart';

import '../data/demo_notifications.dart';
import '../l10n/app_localizations.dart';
import '../models/app_notification.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';

// Bo loc danh sach thong bao.
enum _Filter { all, route, system }

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late List<AppNotification> _items;
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _items = buildDemoNotifications();
  }

  // Danh sach sau khi ap bo loc.
  List<AppNotification> get _filtered {
    if (_filter == _Filter.all) return _items;
    final NotificationCategory category = _filter == _Filter.route
        ? NotificationCategory.route
        : NotificationCategory.system;
    return _items.where((n) => n.category == category).toList();
  }

  // Danh dau tat ca thong bao da doc.
  void _markAllRead() {
    setState(() {
      _items = [for (final n in _items) n.copyWith(isRead: true)];
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr('mark_all_read'))));
  }

  // Danh dau mot thong bao da doc khi cham vao item.
  void _markRead(AppNotification item) {
    setState(() {
      _items = [
        for (final n in _items) n.id == item.id ? n.copyWith(isRead: true) : n,
      ];
    });
  }

  // Nhom cac thong bao theo moc thoi gian.
  List<_Group> _buildGroups() {
    final now = DateTime.now();
    final recent = <AppNotification>[];
    final today = <AppNotification>[];
    final older = <AppNotification>[];

    for (final n in _filtered) {
      final diff = now.difference(n.time);
      if (diff.inHours < 1) {
        recent.add(n);
      } else if (n.time.year == now.year &&
          n.time.month == now.month &&
          n.time.day == now.day) {
        today.add(n);
      } else {
        older.add(n);
      }
    }

    return [
      if (recent.isNotEmpty) _Group(context.tr('group_recent'), recent),
      if (today.isNotEmpty) _Group(context.tr('group_today'), today),
      if (older.isNotEmpty) _Group(context.tr('group_older'), older),
    ];
  }

  // Xu ly vuot: vuot phai = da doc, vuot trai = xoa.
  Future<bool?> _onDismiss(
    DismissDirection direction,
    AppNotification item,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      // Vuot phai: danh dau da doc (giu lai thong bao).
      setState(() {
        _items = [
          for (final n in _items)
            n.id == item.id ? n.copyWith(isRead: true) : n,
        ];
      });
      return false;
    }

    // Vuot trai: xoa thong bao.
    setState(() {
      _items = _items.where((n) => n.id != item.id).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr('notif_deleted', params: {'title': item.title}),
        ),
      ),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('notif_title')),
        actions: [
          // Nut danh dau tat ca la da doc.
          IconButton(
            tooltip: context.tr('mark_all_read'),
            icon: Icon(Icons.mark_email_read_outlined, color: colors.onPrimary),
            onPressed: _filtered.isEmpty ? null : _markAllRead,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _filtered.isEmpty
                ? EmptyState(
                    icon: _emptyIcon(context),
                    message: _emptyMessage(context),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      for (final group in _buildGroups()) ...[
                        SectionHeader(label: group.label, topPadding: 14),
                        for (final n in group.items)
                          _buildDismissible(context, n),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // Icon va message cho trang thai rong (theo bo loc hien tai).
  IconData _emptyIcon(BuildContext context) => switch (_filter) {
    _Filter.all => Icons.notifications_off_outlined,
    _Filter.route => Icons.directions_bus_outlined,
    _Filter.system => Icons.settings_suggest_outlined,
  };

  String _emptyMessage(BuildContext context) => switch (_filter) {
    _Filter.all => context.tr('notif_empty'),
    _Filter.route => context.tr('notif_empty_routes'),
    _Filter.system => context.tr('notif_empty_system'),
  };

  // Thanh loc: Tat ca | Tuyen xe | He thong.
  Widget _buildFilterBar() {
    final labels = {
      _Filter.all: context.tr('filter_all'),
      _Filter.route: context.tr('filter_routes'),
      _Filter.system: context.tr('filter_system'),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          for (final f in _Filter.values) ...[
            if (f != _Filter.values.first) const SizedBox(width: 10),
            Expanded(
              child: _FilterPill(
                label: labels[f]!,
                selected: _filter == f,
                onTap: () => setState(() => _filter = f),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Mot thong bao co ho tro vuot de xoa / danh dau da doc.
  Widget _buildDismissible(BuildContext context, AppNotification item) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) => _onDismiss(direction, item),
      background: Container(
        color: context.colors.primary,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mark_email_read, color: context.colors.onPrimary),
            const SizedBox(width: 8),
            Text(
              context.tr('swiped_read'),
              style: TextStyle(
                color: context.colors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: context.colors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: context.colors.onError),
            const SizedBox(width: 8),
            Text(
              context.tr('swiped_delete'),
              style: TextStyle(
                color: context.colors.onError,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      child: _NotificationTile(item: item, onTap: () => _markRead(item)),
    );
  }
}

// Ten mot nhom thong bao theo thoi gian.
class _Group {
  final String label;
  final List<AppNotification> items;

  const _Group(this.label, this.items);
}

// Nut loc dang vien thuoc (pill).
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: selected ? colors.primary : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? colors.onPrimary : colors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// Mot dong thong bao trong danh sach.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spec = _specFor(context, item.kind);
    final bool unread = !item.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        // Nen the mau theo surface (dam hon khi chua doc).
        color: colors.surface.withValues(alpha: unread ? 0.9 : 0.6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon loai thong bao.
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: spec.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(spec.icon, color: spec.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: unread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: unread
                                ? colors.onSurface
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      // Cham mau danh dau chua doc.
                      if (unread) ...[
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _timeAgo(context, item.time),
                        style: TextStyle(fontSize: 11.5, color: colors.outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spec.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: spec.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Icon, mau va nhan cua tung loai thong bao.
  ({IconData icon, Color color, String label}) _specFor(
    BuildContext context,
    NotificationKind kind,
  ) {
    final colors = context.colors;
    switch (kind) {
      case NotificationKind.arrival:
        return (
          icon: Icons.directions_bus,
          color: colors.primary,
          label: context.tr('kind_arrival'),
        );
      case NotificationKind.issue:
        return (
          icon: Icons.warning_amber_rounded,
          color: colors.error,
          label: context.tr('kind_issue'),
        );
      case NotificationKind.news:
        return (
          icon: Icons.campaign_outlined,
          color: const Color(0xFF0B7285),
          label: context.tr('kind_news'),
        );
      case NotificationKind.account:
        return (
          icon: Icons.account_circle_outlined,
          color: const Color(0xFF7048E8),
          label: context.tr('kind_account'),
        );
    }
  }

  // Thoi gian tuong doi, vd: "5 phút trước".
  String _timeAgo(BuildContext context, DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return context.tr('time_just_now');
    if (diff.inMinutes < 60) {
      return context.tr('time_min_ago', params: {'count': '${diff.inMinutes}'});
    }
    if (diff.inHours < 24) {
      return context.tr('time_hour_ago', params: {'count': '${diff.inHours}'});
    }
    final days = diff.inDays;
    if (days == 1) return context.tr('time_yesterday');
    return context.tr('time_day_ago', params: {'count': '$days'});
  }
}
