// route_detail_screen.dart
// Màn hình XEM CHI TIẾT một tuyến xe buýt.
// Dữ liệu lấy từ API: thông tin tuyến + danh sách trạm (theo chiều đi)
// + danh sách xe đang hoạt động. Có trạng thái loading/lỗi/không có dữ liệu.

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/bus.dart';
import '../models/bus_route.dart';
import '../services/favorite_service.dart';
import '../services/transit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/error_state.dart';

class RouteDetailScreen extends StatefulWidget {
  const RouteDetailScreen({super.key, required this.route});

  // Tuyến cần xem (có thể chỉ có thông tin tóm tắt từ danh sách).
  final BusRoute route;

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  bool _loading = true;
  String? _error;

  // Tuyến đã nạp kèm danh sách trạm.
  BusRoute? _route;
  List<Bus> _buses = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Tải chi tiết tuyến + danh sách trạm + danh sách xe.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final route = await TransitService.instance.fetchRouteWithStops(
        widget.route.id,
      );
      final buses = await TransitService.instance.fetchRouteBuses(
        widget.route.id,
      );
      if (!mounted) return;
      setState(() {
        _route = route;
        _buses = buses;
        _loading = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error =
            err is TransitException ? err.message : context.tr('load_error');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = _route ?? widget.route;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('route_no', params: {'number': route.routeNumber}),
        ),
        actions: [
          // Nút yêu thích trên AppBar, trạng thái tự cập nhật.
          ListenableBuilder(
            listenable: FavoriteService.instance,
            builder: (context, _) {
              final bool fav = FavoriteService.instance.isFavorite(route.id);
              return IconButton(
                tooltip: 'Yêu thích',
                icon: Icon(
                  fav ? Icons.favorite : Icons.favorite_border,
                  color: fav ? context.colors.error : context.colors.onPrimary,
                ),
                onPressed: () {
                  FavoriteService.instance.toggle(route.id);
                },
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _buildBody(context, route),
    );
  }

  Widget _buildBody(BuildContext context, BusRoute route) {
    final stops = route.stops;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Phần đầu: số tuyến + tên tuyến trong khối hero.
        _buildHeader(context, route),

        const SizedBox(height: 16),

        // Card thông tin cơ bản.
        _buildInfoCard(context, route),

        const SizedBox(height: 20),

        // Tiêu đề danh sách trạm (kèm số lượng).
        _buildSectionTitle(
          context,
          context.tr('journey'),
          context.tr('stops_count', params: {'count': '${stops.length}'}),
        ),
        const SizedBox(height: 8),

        // Hiển thị từng trạm theo dạng timeline, đánh số thứ tự 1, 2, 3...
        for (int i = 0; i < stops.length; i++) _buildStopTimeline(context, i),

        const SizedBox(height: 12),

        // Tiêu đề danh sách xe buýt.
        _buildSectionTitle(
          context,
          context.tr('buses_on_route'),
          _buses.isEmpty
              ? null
              : context.tr('bus_count', params: {'count': '${_buses.length}'}),
        ),
        const SizedBox(height: 8),

        // Nếu không có xe nào thì hiện thông báo.
        if (_buses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.tr('no_active_buses'),
              style: TextStyle(color: context.colors.onSurfaceVariant),
            ),
          )
        else
          for (final bus in _buses) _buildBusTile(context, bus),
      ],
    );
  }

  // Phần đầu màn hình: số tuyến trong ô trắng + tên tuyến.
  Widget _buildHeader(BuildContext context, BusRoute route) {
    final colors = context.colors;
    final color = _parseColor(route.color) ?? colors.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.onPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              route.routeNumber,
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${route.startPoint} → ${route.endPoint}',
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                if (route.operatingTime.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.onPrimary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, color: colors.onPrimary, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          context.tr('service_hours', params: {
                            'time': route.operatingTime,
                          }),
                          style: TextStyle(
                            color: colors.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card thông tin cơ bản của tuyến.
  Widget _buildInfoCard(BuildContext context, BusRoute route) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            _InfoTile(
              icon: Icons.directions,
              label: context.tr('start_point'),
              value: route.startPoint,
            ),
            _InfoTile(
              icon: Icons.flag_outlined,
              label: context.tr('end_point'),
              value: route.endPoint,
            ),
            if (route.operatingTime.isNotEmpty)
              _InfoTile(
                icon: Icons.schedule,
                label: context.tr('operating_time'),
                value: route.operatingTime,
              ),
            _InfoTile(
              icon: Icons.layers_outlined,
              label: context.tr('num_stops'),
              value: context.tr('stops_count', params: {
                'count': '${route.displayStopCount}',
              }),
            ),
            if (route.fare != null)
              _InfoTile(
                icon: Icons.payments_outlined,
                label: context.tr('fare'),
                value: '${route.fare!.toStringAsFixed(0)} đ',
              ),
            if (route.frequencyMinutes != null)
              _InfoTile(
                icon: Icons.repeat,
                label: context.tr('frequency'),
                value: context.tr('minutes_value', params: {
                  'count': '${route.frequencyMinutes}',
                }),
              ),
          ],
        ),
      ),
    );
  }

  // Tiêu đề một phần nội dung + số liệu kèm theo.
  Widget _buildSectionTitle(BuildContext context, String title, String? badge) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: context.colors.onSurface,
            ),
          ),
          const Spacer(),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.colors.onPrimaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Một trạm dưới dạng timeline: số thứ tự nối với đường kẻ dọc.
  Widget _buildStopTimeline(BuildContext context, int index) {
    final colors = context.colors;
    final route = _route!;
    final stop = route.stops[index];
    final bool isFirst = index == 0;
    final bool isLast = index == route.stops.length - 1;

    final Color circleColor = isFirst
        ? colors.primary
        : (isLast ? colors.secondary : colors.primaryContainer);
    final Color circleTextColor =
        (isFirst || isLast) ? colors.onPrimary : colors.onPrimaryContainer;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: circleColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: circleTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 16, bottom: isLast ? 0 : 8),
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              stop.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                          if (isFirst)
                            _StopTag(
                              label: context.tr('stop_start_tag'),
                              color: colors.primary,
                            ),
                          if (isLast)
                            _StopTag(
                              label: context.tr('stop_end_tag'),
                              color: colors.secondary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stop.address,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Một xe buýt dưới dạng Card, hiện mã xe + trạng thái.
  Widget _buildBusTile(BuildContext context, Bus bus) {
    final colors = context.colors;
    final bool active = bus.isActive;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child:
              Icon(Icons.directions_bus, color: colors.onPrimary, size: 24),
        ),
        title: Text(
          bus.busNumber,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          active ? context.tr('bus_active') : context.tr('bus_stopped'),
          style: const TextStyle(fontSize: 12.5),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active
                ? colors.primaryContainer
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            active ? context.tr('bus_active') : context.tr('bus_stopped'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active
                  ? colors.onPrimaryContainer
                  : colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  // Đổi mã màu "#RRGGBB" từ backend thành Color (null nếu không hợp lệ).
  Color? _parseColor(String? value) {
    if (value == null) return null;
    final hex = value.replaceFirst('#', '');
    if (hex.length != 6) return null;
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? null : Color(0xFF000000 | parsed);
  }
}

// Nhãn nhỏ hiện trên trạm đầu / trạm cuối của tuyến.
class _StopTag extends StatelessWidget {
  const _StopTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}

// Một dòng thông tin (icon + nhãn + giá trị) trong card thông tin.
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: colors.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
