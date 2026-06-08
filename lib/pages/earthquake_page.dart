import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../services/maps_config.dart';
import '../services/earthquake_service.dart';
import '../models/earthquake.dart';
import 'earthquake_detail_page.dart';

enum _SortBy { magnitude, time, distance }

class EarthquakePage extends StatefulWidget {
  const EarthquakePage({super.key});

  @override
  State<EarthquakePage> createState() => _EarthquakePageState();
}

class _EarthquakePageState extends State<EarthquakePage> {
  List<Earthquake> _quakes = [];
  bool _loading = true;
  String? _error;

  TimeRange _timeRange = TimeRange.day;
  double _minMag = 0;
  _SortBy _sortBy = _SortBy.magnitude;
  bool _showMap = false;
  bool _alertEnabled = true;
  double? _userLat;
  double? _userLng;
  bool _isLocating = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 90), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sortByDist = _sortBy == _SortBy.distance;
      final quakes = await earthquakeService.fetchEarthquakes(
        range: _timeRange,
        minMagnitude: _minMag,
        userLat: _userLat,
        userLng: _userLng,
        sortByDistance: sortByDist,
      );
      if (mounted) {
        setState(() {
          _quakes = _sortLocal(quakes);
          _loading = false;
        });
        _checkSevere(quakes);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<Earthquake> _sortLocal(List<Earthquake> quakes) {
    final sorted = List<Earthquake>.of(quakes);
    switch (_sortBy) {
      case _SortBy.magnitude:
        sorted.sort((a, b) => b.magnitude.compareTo(a.magnitude));
      case _SortBy.time:
        sorted.sort((a, b) => b.time.compareTo(a.time));
      case _SortBy.distance:
        if (_userLat != null && _userLng != null) {
          sorted.sort((a, b) =>
              a.distanceFrom(_userLat!, _userLng!).compareTo(b.distanceFrom(_userLat!, _userLng!)));
        }
    }
    return sorted;
  }

  void _checkSevere(List<Earthquake> quakes) {
    if (!_alertEnabled) return;
    final severe = quakes.where((e) => e.isSevere);
    for (final eq in severe) {
      _showAlert(eq);
    }
  }

  void _showAlert(Earthquake eq) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ ${eq.title}'),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _locateUser() async {
    setState(() => _isLocating = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) _showSnack('Location service disabled');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) _showSnack('Location permission denied');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
        });
        if (_sortBy == _SortBy.distance) _load();
        _showSnack('Location found');
      }
    } catch (_) {
      if (mounted) _showSnack('Failed to get location');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openDetail(Earthquake eq) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EarthquakeDetailPage(eq: eq),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeProviderScope.of(context).colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Earthquake Alerts'),
        backgroundColor: c.appBar,
        foregroundColor: c.accentTertiary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () => setState(() => _showMap = !_showMap),
            tooltip: _showMap ? 'List view' : 'Map view',
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          _buildToolbar(c),
          if (_timeRange != TimeRange.hour || _quakes.isNotEmpty)
            Expanded(child: _buildBody(c))
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
                    const SizedBox(height: 16),
                    Text('No earthquakes in the past hour', style: TextStyle(fontSize: 16, color: c.text)),
                    Text('Try a wider time range', style: TextStyle(fontSize: 12, color: c.textSecondary)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbar(AppThemeColors c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      color: c.card.withValues(alpha: 0.5),
      child: Column(
        children: [
          _buildTimeTabs(c),
          const SizedBox(height: 8),
          _buildFilterRow(c),
          const SizedBox(height: 4),
          _buildSortRow(c),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildTimeTabs(AppThemeColors c) {
    return Row(
      children: [
        _tab(c, 'Past Hour', TimeRange.hour),
        const SizedBox(width: 6),
        _tab(c, 'Past Day', TimeRange.day),
        const SizedBox(width: 6),
        _tab(c, 'Past Week', TimeRange.week),
      ],
    );
  }

  Widget _tab(AppThemeColors c, String label, TimeRange range) {
    final active = _timeRange == range;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _timeRange = range);
          _load();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? c.accent : c.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? Colors.white : c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(AppThemeColors c) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Min Mag: ${_minMag.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 11, color: c.textSecondary)),
              Slider(
                value: _minMag,
                min: 0,
                max: 9,
                divisions: 18,
                activeColor: c.accent,
                inactiveColor: c.surface,
                label: _minMag.toStringAsFixed(1),
                onChanged: (v) => setState(() => _minMag = v),
                onChangeEnd: (_) => _load(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _locateUser,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _userLat != null ? c.accent : c.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: _isLocating
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: c.accentTertiary))
                : Icon(Icons.my_location, size: 18, color: _userLat != null ? Colors.white : c.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() {
            _alertEnabled = !_alertEnabled;
            if (_alertEnabled) _checkSevere(_quakes);
          }),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _alertEnabled ? c.accent : c.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _alertEnabled ? Icons.notifications_active : Icons.notifications_off,
              size: 18, color: _alertEnabled ? Colors.white : c.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSortRow(AppThemeColors c) {
    return Row(
      children: [
        Icon(Icons.sort, size: 14, color: c.textSecondary),
        const SizedBox(width: 6),
        ..._SortBy.values.map((s) {
          final active = _sortBy == s;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                setState(() => _sortBy = s);
                _load();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: active ? c.accent.withValues(alpha: 0.15) : c.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: active ? Border.all(color: c.accent) : null,
                ),
                child: Text(
                  s.name,
                  style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? c.accent : c.textSecondary),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        if (_userLat != null)
          GestureDetector(
            onTap: () {
              setState(() {
                _userLat = null;
                _userLng = null;
              });
              _load();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('GPS', style: TextStyle(fontSize: 9, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(AppThemeColors c) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: c.accent));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: c.textSecondary),
            const SizedBox(height: 12),
            Text('Failed to load', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text)),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_quakes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
            const SizedBox(height: 16),
            Text('No earthquakes match', style: TextStyle(fontSize: 16, color: c.text)),
            Text('Try adjusting filters', style: TextStyle(fontSize: 12, color: c.textSecondary)),
          ],
        ),
      );
    }
    if (_showMap) return _buildMapView(c);
    return _buildListView(c);
  }

  Widget _buildListView(AppThemeColors c) {
    return RefreshIndicator(
      onRefresh: _load,
      color: c.accent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _quakes.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) return _buildSummaryHeader(c);
          final eq = _quakes[i - 1];
          return _EarthquakeCard(
            eq: eq,
            c: c,
            distance: _userLat != null && _userLng != null
                ? eq.distanceFrom(_userLat!, _userLng!)
                : null,
            onTap: () => _openDetail(eq),
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(AppThemeColors c) {
    final severe = _quakes.where((e) => e.isSevere).length;
    final moderate = _quakes.where((e) => e.isModerate).length;
    final minor = _quakes.where((e) => e.isMinor).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _summaryChip(c, '≥5.0', severe.toString(), Colors.red.shade400),
          const SizedBox(width: 6),
          _summaryChip(c, '4.0-4.9', moderate.toString(), Colors.orange.shade400),
          const SizedBox(width: 6),
          _summaryChip(c, '<4.0', minor.toString(), Colors.green.shade400),
          const SizedBox(width: 6),
          _summaryChip(c, 'Total', '${_quakes.length}', c.textSecondary, bgColor: c.surface),
        ],
      ),
    );
  }

  Widget _summaryChip(AppThemeColors c, String label, String count, Color color, {Color? bgColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor ?? color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 9, color: c.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(AppThemeColors c) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: _userLat != null && _userLng != null
                ? LatLng(_userLat!, _userLng!)
                : const LatLng(20, 0),
            initialZoom: 2.0,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
          ),
          children: [
            TileLayer(
              urlTemplate: MapsConfig.tileUrl,
              userAgentPackageName: 'com.omninexus.app',
            ),
            MarkerLayer(
              markers: [
                if (_userLat != null && _userLng != null)
                  Marker(
                    point: LatLng(_userLat!, _userLng!),
                    width: 24,
                    height: 24,
                    child: Icon(Icons.my_location, color: Colors.purple, size: 24),
                  ),
                ..._quakes.map((eq) => Marker(
                      point: LatLng(eq.latitude, eq.longitude),
                      width: 30 + eq.magnitude * 4,
                      height: 30 + eq.magnitude * 4,
                      child: GestureDetector(
                        onTap: () => _openDetail(eq),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _magColor(eq).withValues(alpha: 0.3),
                            border: Border.all(color: _magColor(eq), width: 2),
                          ),
                          child: Center(
                            child: Text(eq.magFormatted, style: TextStyle(
                                fontSize: 9, fontWeight: FontWeight.bold, color: _magColor(eq))),
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          ],
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: c.card.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${_quakes.length} events', style: TextStyle(fontSize: 11, color: c.textSecondary)),
          ),
        ),
      ],
    );
  }

  Color _magColor(Earthquake eq) {
    if (eq.isSevere) return Colors.red.shade400;
    if (eq.isModerate) return Colors.orange.shade400;
    return Colors.green.shade400;
  }
}

class _EarthquakeCard extends StatelessWidget {
  final Earthquake eq;
  final AppThemeColors c;
  final double? distance;
  final VoidCallback onTap;
  const _EarthquakeCard({required this.eq, required this.c, this.distance, required this.onTap});

  Color get _magColor {
    if (eq.isSevere) return Colors.red.shade400;
    if (eq.isModerate) return Colors.orange.shade400;
    return Colors.green.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _magColor.withValues(alpha: eq.isSevere ? 0.4 : 0.12),
            width: eq.isSevere ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _magColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(eq.magFormatted,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _magColor)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eq.place,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 10, color: c.textSecondary),
                      const SizedBox(width: 2),
                      Text(eq.timeFormatted, style: TextStyle(fontSize: 10, color: c.textSecondary)),
                      const SizedBox(width: 8),
                      Icon(Icons.explore, size: 10, color: c.textSecondary),
                      const SizedBox(width: 2),
                      Text('${eq.depth.toStringAsFixed(1)} km', style: TextStyle(fontSize: 10, color: c.textSecondary)),
                      if (distance != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.near_me, size: 10, color: c.accent),
                        const SizedBox(width: 2),
                        Text('${distance!.toStringAsFixed(0)} km', style: TextStyle(fontSize: 10, color: c.accent)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (eq.hasTsunami)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.warning, size: 16, color: Colors.red.shade400),
              ),
            if (eq.alert != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _alertColor(eq.alert!).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(eq.alert!, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: _alertColor(eq.alert!))),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 16, color: c.textSecondary),
          ],
        ),
      ),
    );
  }

  Color _alertColor(String alert) {
    switch (alert) {
      case 'green': return Colors.green;
      case 'yellow': return Colors.orange;
      case 'orange': return Colors.deepOrange;
      case 'red': return Colors.red;
      default: return c.textSecondary;
    }
  }
}
