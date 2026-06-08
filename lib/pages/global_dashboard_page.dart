import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../services/global_stats_service.dart';
import '../services/voice_service.dart';
import '../widgets/animated_background.dart';

class GlobalDashboardPage extends StatefulWidget {
  const GlobalDashboardPage({super.key});

  @override
  State<GlobalDashboardPage> createState() => _GlobalDashboardPageState();
}

class _GlobalDashboardPageState extends State<GlobalDashboardPage>
    with WidgetsBindingObserver {
  final _service = GlobalStatsService();
  final _scrollController = ScrollController();
  GlobalStatsData? _data;
  bool _loading = true;
  String? _error;
  double _userLat = 13.736717;
  double _userLng = 100.523186;

  StreamSubscription<AccelerometerEvent>? _shakeSub;
  DateTime _lastShake = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _findLocation().then((_) => _refresh());
    _initShakeDetection();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shakeSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _initShakeDetection();
    if (state == AppLifecycleState.paused) _shakeSub?.cancel();
  }

  void _initShakeDetection() {
    _shakeSub?.cancel();
    _shakeSub = accelerometerEventStream().listen((event) {
      final mag = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      if (mag > 30 && DateTime.now().difference(_lastShake).inSeconds > 3) {
        _lastShake = DateTime.now();
        HapticFeedback.heavyImpact();
        _refresh();
      }
    });
  }

  Future<void> _findLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      _userLat = pos.latitude;
      _userLng = pos.longitude;
    } catch (_) {}
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _data = await _service.fetchAll(lat: _userLat, lng: _userLng);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _playAudioReport() async {
    await voiceService.speak(_buildReport());
  }

  String _buildReport() {
    if (_data == null) return 'No data available yet.';
    final d = _data!;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';

    final buffer = StringBuffer('$greeting. Here is your global summary.');

    if (d.weather?.current != null) {
      final w = d.weather!.current!;
      final code = d.weather!.daily.isNotEmpty
          ? d.weather!.daily.first.weatherCode
          : 0;
      buffer.write(
        ' Temperature is ${w.temperature.toStringAsFixed(0)} degrees with ${_weatherDesc(code)}.',
      );
    }

    if (d.iss != null) {
      final lat = d.iss!.position.latitude;
      final lon = d.iss!.position.longitude;
      final ns = lat >= 0 ? 'North' : 'South';
      final ew = lon >= 0 ? 'East' : 'West';
      buffer.write(
        ' The International Space Station is at ${lat.abs().toStringAsFixed(1)} degrees $ns, ${lon.abs().toStringAsFixed(1)} degrees $ew.',
      );
    }

    if (d.stocks.isNotEmpty) {
      buffer.write(' In the markets:');
      for (final s in d.stocks.take(3)) {
        final dir = s.isPositive ? 'up' : 'down';
        buffer.write(
          ' ${s.name} is $dir ${s.changePercent.abs().toStringAsFixed(1)} percent.',
        );
      }
    }

    buffer.write(
      ' In the last 24 hours, there have been ${d.quakeCount} recorded earthquakes.',
    );
    if (d.quakeCount > 0) {
      final biggest = d.earthquakes.first;
      buffer.write(
        ' The largest was magnitude ${biggest.magnitude.toStringAsFixed(1)} at ${biggest.place}.',
      );
    }

    buffer.write(' That concludes your global update. Have a great day.');
    return buffer.toString();
  }

  String _weatherDesc(int code) {
    if (code == 0) return 'clear skies';
    if (code < 4) return 'mainly clear';
    if (code < 50) return 'cloudy';
    if (code < 60) return 'foggy';
    if (code < 70) return 'rainy';
    if (code < 80) return 'showery';
    if (code < 90) return 'stormy';
    return 'precipitating';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProviderScope.of(context);
    final c = theme.colors;
    return AnimatedBackground(
      mode: theme.mode,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Global Dashboard'),
          backgroundColor: c.card,
          foregroundColor: c.text,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: _data != null && !_loading ? _playAudioReport : null,
              tooltip: 'Audio Report',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _refresh,
            ),
          ],
        ),
        body: _loading && _data == null
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _data == null
            ? _buildError(c)
            : RefreshIndicator(onRefresh: _refresh, child: _buildContent(c)),
      ),
    );
  }

  Widget _buildError(AppThemeColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: c.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Could not load data',
              style: TextStyle(color: c.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Shake phone or tap refresh to try again',
              style: TextStyle(
                color: c.textSecondary.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppThemeColors c) {
    final d = _data;
    if (d == null) return const SizedBox();
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _buildHeader(c, d),
        const SizedBox(height: 16),
        _buildQuickStats(c, d),
        const SizedBox(height: 16),
        _buildAudioReportCard(c, d),
        const SizedBox(height: 16),
        if (d.stocks.isNotEmpty) _buildStockChart(c, d),
        if (d.stocks.isNotEmpty) const SizedBox(height: 16),
        if (d.earthquakes.isNotEmpty) _buildQuakeChart(c, d),
        if (d.earthquakes.isNotEmpty) const SizedBox(height: 16),
        _buildIssCard(c, d),
        const SizedBox(height: 16),
        _buildUpdatedAt(c, d),
      ],
    );
  }

  Widget _buildHeader(AppThemeColors c, GlobalStatsData d) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 18
        ? 'Good Afternoon'
        : 'Good Evening';
    return Semantics(
      label: '$greeting. Global overview last updated at ${_formatTime(now)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: c.text,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Live snapshot from all sources',
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, size: 12, color: c.accent),
                const SizedBox(width: 4),
                Text(
                  'Updated ${_formatTime(now)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: c.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.motion_photos_auto,
                  size: 11,
                  color: c.accent.withValues(alpha: 0.6),
                ),
                Text(
                  'Shake to refresh',
                  style: TextStyle(
                    fontSize: 10,
                    color: c.accent.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(AppThemeColors c, GlobalStatsData d) {
    return Semantics(
      label:
          'Quick statistics. Temperature ${d.avgTemp.toStringAsFixed(0)} degrees. ${d.quakeCount} earthquakes. ${d.stockCount} stocks tracked.',
      child: Row(
        children: [
          _StatCard(
            icon: Icons.thermostat,
            label: 'Temperature',
            value: '${d.avgTemp.toStringAsFixed(0)}°',
            sub: d.weather != null && d.weather!.daily.isNotEmpty
                ? _weatherEmoji(d.weather!.daily.first.weatherCode)
                : '',
            color: c,
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.landslide,
            label: 'Quakes (24h)',
            value: '${d.quakeCount}',
            sub: d.quakeCount > 0
                ? 'Max ${d.maxQuakeMag.toStringAsFixed(1)}'
                : '',
            color: c,
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.trending_up,
            label: 'Markets',
            value: '${d.stockCount}',
            sub: '${d.stockGainers}↑ ${d.stockLosers}↓',
            color: c,
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.satellite_alt,
            label: 'ISS',
            value: d.iss != null ? 'Tracking' : 'N/A',
            sub: '',
            color: c,
          ),
        ],
      ),
    );
  }

  Widget _buildAudioReportCard(AppThemeColors c, GlobalStatsData d) {
    return Semantics(
      label: 'Listen to audio report',
      child: GestureDetector(
        onTap: _playAudioReport,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c.accent, c.accentSecondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: c.accent.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.volume_up,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'AI reads your global summary aloud',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockChart(AppThemeColors c, GlobalStatsData d) {
    return Semantics(
      label: 'Stock market performance chart',
      child: _ChartCard(
        title: 'Market Watch',
        icon: Icons.trending_up,
        color: c,
        chart: SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 24),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY:
                    d.stocks
                            .map((s) => s.changePercent.abs())
                            .reduce((a, b) => a > b ? a : b) *
                        1.3 +
                    1,
                minY:
                    -d.stocks
                            .map((s) => s.changePercent.abs())
                            .reduce((a, b) => a > b ? a : b) *
                        1.3 -
                    1,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final s = d.stocks[group.x.toInt()];
                      return BarTooltipItem(
                        '${s.symbol}\n${s.changePercentFormatted}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final i = val.toInt();
                        if (i < 0 || i >= d.stocks.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            d.stocks[i].symbol,
                            style: TextStyle(
                              fontSize: 10,
                              color: c.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (val, _) {
                        return Text(
                          '${val.toInt()}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: c.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: c.textSecondary.withValues(alpha: 0.1),
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(d.stocks.length, (i) {
                  final s = d.stocks[i];
                  final pct = s.changePercent;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: pct,
                        color: pct >= 0
                            ? const Color(0xFF3B887A)
                            : const Color(0xFFE57373),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuakeChart(AppThemeColors c, GlobalStatsData d) {
    final minor = d.minorQuakes.toDouble();
    final moderate = d.moderateQuakes.toDouble();
    final severe = d.severeQuakes.toDouble();
    final total = minor + moderate + severe;
    if (total == 0) return const SizedBox();

    return Semantics(
      label:
          'Earthquake distribution. $minor minor quakes, $moderate moderate quakes, $severe severe quakes.',
      child: _ChartCard(
        title: 'Earthquake Magnitude Distribution',
        icon: Icons.landslide,
        color: c,
        chart: SizedBox(
          height: 180,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: [
                        PieChartSectionData(
                          value: minor,
                          color: const Color(0xFF81C784),
                          title: minor > 0 ? '${minor.toInt()}' : '',
                          radius: 50,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          value: moderate,
                          color: const Color(0xFFFFB74D),
                          title: moderate > 0 ? '${moderate.toInt()}' : '',
                          radius: 50,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          value: severe,
                          color: const Color(0xFFE57373),
                          title: severe > 0 ? '${severe.toInt()}' : '',
                          radius: 50,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendRow(
                      color: const Color(0xFF81C784),
                      label: 'Minor (<4.0)',
                      count: minor.toInt(),
                    ),
                    const SizedBox(height: 8),
                    _LegendRow(
                      color: const Color(0xFFFFB74D),
                      label: 'Moderate (4-5)',
                      count: moderate.toInt(),
                    ),
                    const SizedBox(height: 8),
                    _LegendRow(
                      color: const Color(0xFFE57373),
                      label: 'Severe (5+)',
                      count: severe.toInt(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIssCard(AppThemeColors c, GlobalStatsData d) {
    if (d.iss == null) return const SizedBox();
    final iss = d.iss!;
    final lat = iss.position.latitude;
    final lon = iss.position.longitude;
    final ns = lat >= 0 ? 'N' : 'S';
    final ew = lon >= 0 ? 'E' : 'W';
    return Semantics(
      label:
          'International Space Station is at latitude ${lat.abs().toStringAsFixed(2)} degrees $ns, longitude ${lon.abs().toStringAsFixed(2)} degrees $ew',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.accent.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.satellite_alt, color: c.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'ISS Live Position',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: c.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _IssInfo(
                  label: 'Latitude',
                  value: '${lat.abs().toStringAsFixed(2)}° $ns',
                ),
                const SizedBox(width: 16),
                _IssInfo(
                  label: 'Longitude',
                  value: '${lon.abs().toStringAsFixed(2)}° $ew',
                ),
                const SizedBox(width: 16),
                _IssInfo(label: 'Altitude', value: '~408 km'),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Orbiting Earth at 28,000 km/h',
              style: TextStyle(fontSize: 11, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdatedAt(AppThemeColors c, GlobalStatsData d) {
    return Center(
      child: Text(
        'Last updated: ${_formatTime(d.updatedAt)} | Shake to refresh',
        style: TextStyle(
          fontSize: 11,
          color: c.textSecondary.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _weatherEmoji(int code) {
    if (code == 0) return '☀️';
    if (code < 4) return '⛅';
    if (code < 50) return '☁️';
    if (code < 60) return '🌫️';
    if (code < 70) return '🌧️';
    if (code < 80) return '🌦️';
    if (code < 90) return '⛈️';
    return '🌨️';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final AppThemeColors color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.accent.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color.accent, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10,
                  color: color.accent,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final AppThemeColors color;
  final Widget chart;

  const _ChartCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color.accent, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          chart,
        ],
      ),
    );
  }
}

class _IssInfo extends StatelessWidget {
  final String label;
  final String value;

  const _IssInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: ThemeProviderScope.of(context).colors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ThemeProviderScope.of(context).colors.text,
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: ThemeProviderScope.of(context).colors.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: ThemeProviderScope.of(context).colors.text,
          ),
        ),
      ],
    );
  }
}
