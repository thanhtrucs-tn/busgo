// stop_detail_screen.dart
// Màn hình CHI TIẾT một trạm xe buýt:
// thông tin trạm + các tuyến đi qua trạm (lấy từ API) + xem vị trí trên bản đồ.

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/bus_route.dart';
import '../models/bus_stop.dart';
import '../models/stop_arrival.dart';
import '../services/transit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/error_state.dart';
import '../widgets/route_card.dart';
import 'map_screen.dart';
import 'route_detail_screen.dart';

class StopDetailScreen extends StatefulWidget {
  const StopDetailScreen({super.key, required this.stop});

  // Trạm đang được xem.
  final BusStop stop;

  @override
  State<StopDetailScreen> createState() => _StopDetailScreenState();
}

class _StopDetailScreenState extends State<StopDetailScreen> {
  bool _loading = true;
  String? _error;
  List<BusRoute> _routes = const [];
  List<StopArrival> _arrivals = const [];

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  // Tải danh sách các tuyến đi qua trạm này + xe đang đến.
  Future<void> _loadRoutes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final routes = await TransitService.instance.fetchStopRoutes(
        widget.stop.id,
      );

      // Xe đang đến là thông tin phụ: lỗi ở đây không làm hỏng cả màn hình.
      List<StopArrival> arrivals = const [];
      try {
        arrivals = await TransitService.instance.fetchStopArrivals(
          widget.stop.id,
        );
      } catch (_) {
        arrivals = const [];
      }

      if (!mounted) return;
      setState(() {
        _routes = routes;
        _arrivals = arrivals;
        _loading = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err is TransitException
            ? err.message
            : context.tr('load_error');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stop = widget.stop;

    return Scaffold(
      appBar: AppBar(title: Text(stop.name, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Card thông tin trạm.
          Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: context.colors.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.place,
                          color: context.colors.error,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop.name,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: context.colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr('stop_type'),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: context.colors.outlineVariant),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.location_on_outlined,
                    label: context.tr('address'),
                    value: stop.address,
                    iconColor: context.colors.error,
                  ),
                  _InfoTile(
                    icon: Icons.explore_outlined,
                    label: context.tr('coordinates'),
                    value: '${stop.latitude}, ${stop.longitude}',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Nút xem vị trí trạm trên bản đồ (mở bản đồ và căn giữa trạm này).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapScreen(focusStop: stop),
                    ),
                  );
                },
                icon: const Icon(Icons.map),
                label: Text(context.tr('view_on_map')),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ===== Xe đang đến trạm (kèm thời gian dự kiến) =====
          _buildArrivalsSection(context),

          const SizedBox(height: 24),

          // Tiêu đề danh sách các tuyến đi qua trạm.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  context.tr('routes_through'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.colors.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    context.tr(
                      'route_count',
                      params: {'count': '${_routes.length}'},
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Trạng thái tải / lỗi / dữ liệu.
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            ErrorState(message: _error!, onRetry: _loadRoutes)
          else if (_routes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                context.tr('no_routes_through'),
                style: TextStyle(color: context.colors.onSurfaceVariant),
              ),
            )
          else
            for (final route in _routes)
              RouteCard(
                route: route,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteDetailScreen(route: route),
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }

  // Phần "Xe đang đến": danh sách xe sắp tới trạm + thời gian dự kiến.
  Widget _buildArrivalsSection(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                context.tr('arrivals_title'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const Spacer(),
              if (_arrivals.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    context.tr(
                      'bus_count',
                      params: {'count': '${_arrivals.length}'},
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_arrivals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.tr('arrival_none'),
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          )
        else
          for (final arrival in _arrivals) _buildArrivalTile(context, arrival),
      ],
    );
  }

  // Một xe sắp đến trạm: mã xe, tuyến, thời gian dự kiến, khoảng cách.
  Widget _buildArrivalTile(BuildContext context, StopArrival arrival) {
    final colors = context.colors;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.directions_bus,
                color: colors.onPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    arrival.busCode,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    arrival.routeName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr(
                      'arrival_eta',
                      params: {'minutes': '${arrival.estimatedMinutes}'},
                    ),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  context.tr(
                    'arrival_distance',
                    params: {'distance': '${arrival.distanceMeters} m'},
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (arrival.isSimulated) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      context.tr('data_simulated'),
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
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
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor ?? colors.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
