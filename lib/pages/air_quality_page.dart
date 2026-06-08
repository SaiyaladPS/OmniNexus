import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../theme/app_theme.dart';
import '../services/air_quality_service.dart';
import '../services/aqi_history_service.dart';
import '../services/maps_config.dart';
import '../models/air_quality.dart';

class AirQualityPage extends StatefulWidget {
  const AirQualityPage({super.key});

  @override
  State<AirQualityPage> createState() => _AirQualityPageState();
}

class _AirQualityPageState extends State<AirQualityPage> {
  final _service = AirQualityService();
  final _searchCtrl = TextEditingController();
  AirQualityData? _data;
  List<StationInfo> _stations = [];
  bool _loading = true;
  bool _stationLoading = false;
  String? _error;
  double _lat = 13.75;
  double _lng = 100.52;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pos = await _getPosition();
      if (pos != null) {
        _lat = pos.latitude;
        _lng = pos.longitude;
      }
      _data = await _service.fetchNearby(latitude: _lat, longitude: _lng);
      aqiHistoryService.addRecord(
        AqiRecord(
          date: DateTime.now(),
          aqi: _data!.aqi,
          pm25: _data!.pm25,
          pm10: _data!.pm10,
          city: _data!.cityName,
        ),
      );
      _fetchStations();
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _fetchStations() async {
    setState(() => _stationLoading = true);
    try {
      final stations = await _service.fetchStations(lat: _lat, lng: _lng);
      if (mounted) {
        setState(() {
          _stations = stations.where((s) => s.lat != 0 || s.lng != 0).toList();
          _stationLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _stationLoading = false);
    }
  }

  Future<void> _searchCity(String city) async {
    if (city.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _data = await _service.searchByCity(city.trim());
      _lat = _data!.latitude;
      _lng = _data!.longitude;
      _fetchStations();
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'City not found. Try "Bangkok", "Beijing", etc.';
        _loading = false;
      });
    }
  }

  Future<Position?> _getPosition() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  String _formatLatLng(double lat, double lng) {
    final ns = lat >= 0 ? 'N' : 'S';
    final ew = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}°$ns, ${lng.abs().toStringAsFixed(4)}°$ew';
  }

  void _shareAqi() {
    if (_data == null) return;
    final text =
        '🌍 Air Quality in ${_data!.cityName}\n'
        'AQI: ${_data!.aqi} (${_data!.levelLabel})\n'
        'Location: ${_formatLatLng(_data!.latitude, _data!.longitude)}\n'
        'PM2.5: ${_data!.pm25?.toStringAsFixed(1) ?? "N/A"} μg/m³\n'
        'PM10: ${_data!.pm10?.toStringAsFixed(1) ?? "N/A"} μg/m³\n'
        '${_data!.shortAdvice}\n'
        'via OmniNexus';
    Share.share(text);
  }

  void _showAlertDialog() {
    if (_data == null) return;
    showDialog(
      context: context,
      builder: (ctx) {
        final tc = ThemeProviderScope.of(context).colors;
        return AlertDialog(
          backgroundColor: tc.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Set AQI Alert', style: TextStyle(color: tc.text)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current AQI: ${_data!.aqi} (${_data!.levelLabel})',
                style: TextStyle(color: tc.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                'Alert thresholds:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: tc.text,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              _alertOption(tc, ctx, 'Unhealthy (>150)', 0xFFFF0000, 151),
              _alertOption(tc, ctx, 'Very Unhealthy (>200)', 0xFF8F3F97, 201),
              _alertOption(tc, ctx, 'Hazardous (>300)', 0xFF7E0023, 301),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _alertOption(
    AppThemeColors tc,
    BuildContext ctx,
    String label,
    int colorInt,
    int threshold,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: GestureDetector(
        onTap: () async {
          final plugin = FlutterLocalNotificationsPlugin();
          final android = AndroidNotificationDetails(
            'aqi_alerts',
            'AQI Alerts',
            importance: Importance.high,
            priority: Priority.high,
          );
          await plugin.show(
            threshold,
            'AQI Alert: $label',
            'Air quality has reached $threshold+ at ${_data!.cityName}. ${_data!.shortAdvice}',
            NotificationDetails(android: android),
          );
          if (ctx.mounted) Navigator.pop(ctx);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Alert saved for $label'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Color(colorInt).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Color(colorInt).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: Color(colorInt),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13, color: tc.text)),
            ],
          ),
        ),
      ),
    );
  }

  void _showPollutantInfo(String name, double? value) {
    final info = AirQualityData.pollutantHealthInfo(name, value);
    final c = ThemeProviderScope.of(context).colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: c.text,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                info,
                style: TextStyle(
                  fontSize: 13,
                  color: c.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeProviderScope.of(context).colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Air Quality'),
        backgroundColor: c.card,
        foregroundColor: c.text,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareAqi),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError(c)
          : RefreshIndicator(onRefresh: _load, child: _buildContent(c)),
    );
  }

  Widget _buildError(AppThemeColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 56,
              color: c.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load air quality data',
              style: TextStyle(fontSize: 16, color: c.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 13,
                color: c.textSecondary.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 240,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search city...',
                  filled: true,
                  fillColor: c.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: c.textSecondary,
                    size: 20,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (v) => _searchCity(v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppThemeColors c) {
    final d = _data!;
    final color = Color(d.levelColor);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── City Search ─────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search city (e.g. Bangkok)...',
                    hintStyle: TextStyle(fontSize: 12, color: c.textSecondary),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: c.textSecondary,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (v) => _searchCity(v),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _load,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.my_location, color: c.accent, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ─── AQI Ring Card ────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                d.cityName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: c.text,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _showAlertDialog,
                              child: Icon(
                                Icons.notifications_outlined,
                                size: 18,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Updated: ${d.updatedAt}',
                          style: TextStyle(
                            fontSize: 10,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 13,
                              color: c.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _formatLatLng(d.latitude, d.longitude),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: c.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          d.levelEmoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          d.levelLabel,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  // AQI Ring
                  Expanded(
                    flex: 3,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 130,
                          height: 130,
                          child: CircularProgressIndicator(
                            value: d.aqi / 500,
                            strokeWidth: 12,
                            backgroundColor: c.surface,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${d.aqi}',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: c.text,
                              ),
                            ),
                            Text(
                              'AQI',
                              style: TextStyle(
                                fontSize: 11,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Key values
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _miniRow(c, 'PM2.5', d.pm25, 'μg', _pm25Color(d.pm25)),
                        const SizedBox(height: 6),
                        _miniRow(c, 'PM10', d.pm10, 'μg', _pm10Color(d.pm10)),
                        const SizedBox(height: 6),
                        _miniRow(c, 'O₃', d.o3, 'ppb', null),
                        const SizedBox(height: 6),
                        _miniRow(c, 'NO₂', d.no2, 'ppb', null),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                d.shortAdvice,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: c.textSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── Activity Recommendations ────────────────────────────────
        Text(
          'Activity Recommendations',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: c.text,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: d.activityRecommendations.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final act = d.activityRecommendations[i];
              return Container(
                width: 100,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: act.safe
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(act.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      act.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Icon(
                      act.safe ? Icons.check_circle : Icons.cancel,
                      size: 14,
                      color: act.safe ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // ─── Map ──────────────────────────────────────────────────────
        Text(
          'Nearby Monitoring Stations',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: c.text,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.accent.withValues(alpha: 0.2)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(_lat, _lng),
                  initialZoom: 10,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapsConfig.tileUrl,
                    userAgentPackageName: 'com.omninexus.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_lat, _lng),
                        width: 30,
                        height: 30,
                        child: Tooltip(
                          message:
                              'Current search location\n${_formatLatLng(_lat, _lng)}',
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ),
                      ),
                      if (d.latitude != 0 || d.longitude != 0)
                        Marker(
                          point: LatLng(d.latitude, d.longitude),
                          width: 32,
                          height: 32,
                          child: Tooltip(
                            message:
                                '${d.cityName}\n${_formatLatLng(d.latitude, d.longitude)}',
                            child: Icon(
                              Icons.location_on,
                              color: color,
                              size: 30,
                            ),
                          ),
                        ),
                      ..._stations.map(
                        (s) => Marker(
                          point: LatLng(s.lat, s.lng),
                          width: 28,
                          height: 28,
                          child: Tooltip(
                            message:
                                '${s.name}\nAQI ${s.aqi}\n${_formatLatLng(s.lat, s.lng)}',
                            child: Container(
                              decoration: BoxDecoration(
                                color: _aqiColor(s.aqi),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${s.aqi}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_stationLoading)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildStationLocations(c, d),
        const SizedBox(height: 16),

        // ─── AQI Forecast / Trend Chart ──────────────────────────────
        Text(
          'AQI Trend (Last 30 Records)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: c.text,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.accent.withValues(alpha: 0.12)),
          ),
          child: aqiHistoryService.records.length < 2
              ? SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'Check back after more data is collected',
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  ),
                )
              : SizedBox(
                  height: 140,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 50,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: c.textSecondary.withValues(alpha: 0.1),
                          strokeWidth: 1,
                        ),
                        drawVerticalLine: false,
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}',
                              style: TextStyle(
                                fontSize: 9,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            aqiHistoryService.records.length,
                            (i) {
                              final rec = aqiHistoryService.records[i];
                              return FlSpot(i.toDouble(), rec.aqi.toDouble());
                            },
                          ),
                          isCurved: true,
                          color: color,
                          barWidth: 2.5,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: 2.5,
                                  color: color,
                                  strokeWidth: 0,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withValues(alpha: 0.08),
                          ),
                        ),
                      ],
                      minY: 0,
                      maxY: 500,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 16),

        // ─── Pollutant Breakdown ──────────────────────────────────────
        Text(
          'Pollutant Levels',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: c.text,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.accent.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              _pollutantRow(
                c,
                'PM2.5',
                d.pm25,
                'μg/m³',
                'Fine particulate matter',
                _pm25Color(d.pm25),
              ),
              const Divider(height: 16),
              _pollutantRow(
                c,
                'PM10',
                d.pm10,
                'μg/m³',
                'Coarse particulate matter',
                _pm10Color(d.pm10),
              ),
              const Divider(height: 16),
              _pollutantRow(c, 'O₃', d.o3, 'ppb', 'Ground-level ozone', null),
              const Divider(height: 16),
              _pollutantRow(c, 'NO₂', d.no2, 'ppb', 'Nitrogen dioxide', null),
              const Divider(height: 16),
              _pollutantRow(c, 'SO₂', d.so2, 'ppb', 'Sulfur dioxide', null),
              const Divider(height: 16),
              _pollutantRow(c, 'CO', d.co, 'ppb', 'Carbon monoxide', null),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── WHO Guidelines ───────────────────────────────────────────
        if (d.pm25 != null || d.pm10 != null) ...[
          Text(
            'WHO Air Quality Guidelines',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: c.text,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.accent.withValues(alpha: 0.12)),
            ),
            child: Column(
              children: [
                if (d.whoPm25Note != null)
                  _whoRow(
                    c,
                    'PM2.5',
                    d.pm25!,
                    d.whoPm25Note!,
                    '≤ 5 μg/m³',
                    _pm25Color(d.pm25),
                  ),
                if (d.pm25 != null && d.pm10 != null) const Divider(height: 14),
                if (d.whoPm10Note != null)
                  _whoRow(
                    c,
                    'PM10',
                    d.pm10!,
                    d.whoPm10Note!,
                    '≤ 15 μg/m³',
                    _pm10Color(d.pm10),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ─── Weather at Station ───────────────────────────────────────
        if (d.temperature != null ||
            d.humidity != null ||
            d.windSpeed != null) ...[
          Text(
            'Weather at Station',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: c.text,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.accent.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (d.temperature != null)
                  _weatherChip(
                    c,
                    '${d.temperature!.toStringAsFixed(1)}°C',
                    Icons.thermostat,
                  ),
                if (d.humidity != null)
                  _weatherChip(
                    c,
                    '${d.humidity!.toStringAsFixed(0)}%',
                    Icons.water_drop,
                  ),
                if (d.windSpeed != null)
                  _weatherChip(
                    c,
                    '${d.windSpeed!.toStringAsFixed(1)} m/s',
                    Icons.air,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ─── Health Advice ───────────────────────────────────────────
        Text(
          'Smart Recommendation',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: c.text,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.1), Colors.transparent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.health_and_safety, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  d.healthAdvice,
                  style: TextStyle(
                    fontSize: 13,
                    color: c.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── AQI Scale Legend ─────────────────────────────────────────
        Text(
          'AQI Scale',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: c.text,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.accent.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              _legendRow(c, '0 - 50', 'Good', 0xFF00E400, 'No precautions'),
              const Divider(height: 8),
              _legendRow(
                c,
                '51 - 100',
                'Moderate',
                0xFFFFFF00,
                'Sensitive groups: limit',
              ),
              const Divider(height: 8),
              _legendRow(
                c,
                '101 - 150',
                'Unhealthy (Sensitive)',
                0xFFFF7E00,
                'Sensitive: N95 mask',
              ),
              const Divider(height: 8),
              _legendRow(
                c,
                '151 - 200',
                'Unhealthy',
                0xFFFF0000,
                'Everyone: limit outdoors',
              ),
              const Divider(height: 8),
              _legendRow(
                c,
                '201 - 300',
                'Very Unhealthy',
                0xFF8F3F97,
                'Avoid outdoors',
              ),
              const Divider(height: 8),
              _legendRow(
                c,
                '301 - 500',
                'Hazardous',
                0xFF7E0023,
                'Stay indoors',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Powered by WAQI.info',
            style: TextStyle(
              fontSize: 11,
              color: c.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStationLocations(AppThemeColors c, AirQualityData d) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.place, size: 18, color: c.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'All Loaded Locations',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: c.text,
                  ),
                ),
              ),
              Text(
                '${_stations.length + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _locationRow(
            c,
            name: d.cityName,
            detail: 'Current station • AQI ${d.aqi}',
            coordinates: _formatLatLng(d.latitude, d.longitude),
            color: Color(d.levelColor),
            icon: Icons.location_on,
          ),
          if (_stations.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _stationLoading
                  ? 'Loading nearby station locations...'
                  : 'No nearby station locations returned for this area.',
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
          ] else ...[
            const Divider(height: 18),
            ..._stations.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _locationRow(
                  c,
                  name: s.name,
                  detail: 'AQI ${s.aqi}${s.time != null ? ' • ${s.time}' : ''}',
                  coordinates: _formatLatLng(s.lat, s.lng),
                  color: _aqiColor(s.aqi),
                  icon: Icons.sensors,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _locationRow(
    AppThemeColors c, {
    required String name,
    required String detail,
    required String coordinates,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: c.text,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: TextStyle(fontSize: 11, color: c.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                coordinates,
                style: TextStyle(
                  fontSize: 11,
                  color: c.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniRow(
    AppThemeColors c,
    String name,
    double? value,
    String unit,
    Color? dotColor,
  ) {
    return GestureDetector(
      onTap: () => _showPollutantInfo(name, value),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor ?? c.textSecondary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 36,
            child: Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.text,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value != null ? '${value.toStringAsFixed(1)} $unit' : '-- $unit',
              style: TextStyle(fontSize: 11, color: c.textSecondary),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pollutantRow(
    AppThemeColors c,
    String name,
    double? value,
    String unit,
    String desc,
    Color? dotColor,
  ) {
    return GestureDetector(
      onTap: () => _showPollutantInfo(name, value),
      child: Row(
        children: [
          if (dotColor != null)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            )
          else
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: c.textSecondary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.text,
              ),
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(fontSize: 11, color: c.textSecondary),
            ),
          ),
          Text(
            value != null ? '${value.toStringAsFixed(1)} $unit' : '-- $unit',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: c.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _whoRow(
    AppThemeColors c,
    String name,
    double value,
    String note,
    String guideline,
    Color? dotColor,
  ) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: dotColor ?? c.textSecondary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 48,
          child: Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.text,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current: ${value.toStringAsFixed(1)} | WHO: $guideline',
                style: TextStyle(fontSize: 11, color: c.textSecondary),
              ),
              Text(
                note,
                style: TextStyle(
                  fontSize: 11,
                  color: dotColor ?? c.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _weatherChip(AppThemeColors c, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: c.textSecondary),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: c.textSecondary)),
      ],
    );
  }

  Widget _legendRow(
    AppThemeColors c,
    String range,
    String label,
    int colorInt,
    String note,
  ) {
    final col = Color(colorInt);
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: col,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: Text(range, style: TextStyle(fontSize: 11, color: c.text)),
        ),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: c.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            note,
            style: TextStyle(
              fontSize: 10,
              color: c.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Color? _pm25Color(double? v) {
    if (v == null) return null;
    if (v <= 12) return const Color(0xFF00E400);
    if (v <= 35.4) return const Color(0xFFFFFF00);
    if (v <= 55.4) return const Color(0xFFFF7E00);
    if (v <= 150.4) return const Color(0xFFFF0000);
    if (v <= 250.4) return const Color(0xFF8F3F97);
    return const Color(0xFF7E0023);
  }

  Color? _pm10Color(double? v) {
    if (v == null) return null;
    if (v <= 54) return const Color(0xFF00E400);
    if (v <= 154) return const Color(0xFFFFFF00);
    if (v <= 254) return const Color(0xFFFF7E00);
    if (v <= 354) return const Color(0xFFFF0000);
    if (v <= 424) return const Color(0xFF8F3F97);
    return const Color(0xFF7E0023);
  }

  Color _aqiColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF00E400);
    if (aqi <= 100) return const Color(0xFFFFFF00);
    if (aqi <= 150) return const Color(0xFFFF7E00);
    if (aqi <= 200) return const Color(0xFFFF0000);
    if (aqi <= 300) return const Color(0xFF8F3F97);
    return const Color(0xFF7E0023);
  }
}
