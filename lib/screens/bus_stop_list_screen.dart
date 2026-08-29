// bus_stop_list_screen.dart
// Man hinh hien thi danh sach cac tram xe buyt.
// Co o tim kiem de loc tram theo ten hoac dia chi.
// Tap vao mot tram de xem chi tiet.

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../l10n/app_localizations.dart';
import '../models/bus_stop.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import 'stop_detail_screen.dart';

class BusStopListScreen extends StatefulWidget {
  const BusStopListScreen({super.key});

  @override
  State<BusStopListScreen> createState() => _BusStopListScreenState();
}

// StatefulWidget vi tu khoa tim kiem thay doi khi nguoi dung go chu.
class _BusStopListScreenState extends State<BusStopListScreen> {
  String _query = '';

  // Loc danh sach tram theo tu khoa tim kiem.
  List<BusStop> get _filteredStops {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return sampleStops;

    return sampleStops.where((stop) {
      return stop.name.toLowerCase().contains(query) ||
          stop.address.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final stops = _filteredStops;
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('stop_list_title'))),
      body: Column(
        children: [
          // O tim kiem tram.
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

          // Danh sach tram (da duoc loc).
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
                      final int routeCount = routesThroughStop(stop.id).length;

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
                                                  'count': '$routeCount',
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
      ),
    );
  }
}