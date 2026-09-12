// bus_stop_list_screen.dart
// Màn hình DANH SÁCH TRẠM xe buýt.
// Dữ liệu lấy từ API backend thông qua TransitService.
// Có ô tìm kiếm (lọc cục bộ), trạng thái loading/lỗi/không có dữ liệu.

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/bus_stop.dart';
import '../services/transit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import 'stop_detail_screen.dart';

class BusStopListScreen extends StatefulWidget {
  const BusStopListScreen({super.key});

  @override
  State<BusStopListScreen> createState() => _BusStopListScreenState();
}

class _BusStopListScreenState extends State<BusStopListScreen> {
  String _query = '';

  bool _loading = true;
  String? _error;
  List<BusStop> _stops = const [];

  @override
  void initState() {
    super.initState();
    _loadStops();
  }

  Future<void> _loadStops() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stops = await TransitService.instance.fetchStops();
      if (!mounted) return;
      setState(() {
        _stops = stops;
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

  // Lọc danh sách trạm theo từ khóa tìm kiếm (ở phía app).
  List<BusStop> get _filteredStops {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _stops;

    return _stops.where((stop) {
      return stop.name.toLowerCase().contains(query) ||
          stop.address.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('stop_list_title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(message: _error!, onRetry: _loadStops)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final stops = _filteredStops;
    final colors = context.colors;

    return Column(
      children: [
        // Ô tìm kiếm trạm.
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: context.tr('search_stop_hint'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => _query = '');
                      },
                    ),
            ),
            onChanged: (value) {
              setState(() => _query = value);
            },
          ),
        ),

        // Danh sách trạm (đã được lọc).
        Expanded(
          child: stops.isEmpty
              ? EmptyState(
                  icon: Icons.location_off,
                  message: context.tr('no_stops_found'),
                )
              : ListView.builder(
                  itemCount: stops.length,
                  itemBuilder: (context, index) {
                    final stop = stops[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StopDetailScreen(stop: stop),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.place,
                                  color: colors.error,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stop.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: colors.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      stop.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.directions_bus,
                                          size: 13,
                                          color: colors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          context.tr('routes_passing',
                                              params: {
                                                'count': '${stop.routeCount}',
                                              }),
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: colors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: colors.outlineVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
