import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../services/maps_config.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _service = WeatherService();
  WeatherData? _weather;
  bool _loading = true;
  String? _error;
  bool _showMap = false;
  double _lat = 52.52;
  double _lng = 13.41;
  bool _isLocating = false;
  String _locationName = 'Berlin, Germany';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchWeather(latitude: _lat, longitude: _lng);
      if (!mounted) return;
      setState(() {
        _weather = data;
        _loading = false;
      });
      final codes = data.daily.map((d) => d.weatherCode);
      if (codes.isNotEmpty) {
        ThemeProviderScope.of(context).setFromWeather(codes.first);
      }
      _checkRainAlert(codes);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  bool _isRainCode(int code) =>
      (code >= 51 && code <= 67) ||
      (code >= 80 && code <= 82) ||
      (code >= 95 && code <= 99);

  void _checkRainAlert(Iterable<int> codes) {
    final hasRain = codes.any(_isRainCode);
    if (hasRain) notificationService.showRainAlert();
  }

  Future<void> _locateUser() async {
    setState(() => _isLocating = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _showSnack('Location service disabled');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnack('Location permission denied');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
          _locationName =
              '${pos.latitude.toStringAsFixed(2)}°N, ${pos.longitude.toStringAsFixed(2)}°E';
        });
        _load();
      }
    } catch (_) {
      _showSnack('Failed to get location');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _share() {
    if (_weather?.current == null) return;
    final c = _weather!.current!;
    final text =
        '🌤 Weather at ${_lat.toStringAsFixed(2)}°N, ${_lng.toStringAsFixed(2)}°E\n'
        'Temperature: ${c.temperature.toStringAsFixed(1)}°C'
        '${c.apparentTemperature != null ? " (Feels like ${c.apparentTemperature!.toStringAsFixed(1)}°C)" : ""}\n'
        'Humidity: ${c.humidity}%\n'
        '${c.windSpeed != null ? "Wind: ${c.windSpeed!.toStringAsFixed(1)} km/h\n" : ""}'
        '${c.pressure != null ? "Pressure: ${c.pressure!.toStringAsFixed(0)} hPa" : ""}';
    Share.share(text);
  }

  static const _weatherEmojis = {
    0: '☀️',
    1: '🌤',
    2: '⛅',
    3: '☁️',
    45: '🌫',
    48: '🌫',
    51: '🌦',
    53: '🌦',
    55: '🌦',
    56: '🌧',
    57: '🌧',
    61: '🌧',
    63: '🌧',
    65: '🌧',
    66: '🌧',
    67: '🌧',
    71: '🌨',
    73: '🌨',
    75: '🌨',
    77: '🌨',
    80: '🌦',
    81: '🌦',
    82: '🌦',
    85: '🌨',
    86: '🌨',
    95: '⛈',
    96: '⛈',
    99: '⛈',
  };

  String _emoji(int code) => _weatherEmojis[code] ?? '❓';

  @override
  Widget build(BuildContext context) {
    final c = ThemeProviderScope.of(context).colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Weather Forecast'),
        backgroundColor: c.appBar,
        foregroundColor: c.accentTertiary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _weather?.current != null ? _share : null,
          ),
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _buildBody(c),
    );
  }

  Widget _buildBody(AppThemeColors c) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: c.accentTertiary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 64, color: c.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Failed to load',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.text,
              ),
            ),
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
    if (_weather == null) {
      return Center(
        child: Text('No data', style: TextStyle(color: c.textSecondary)),
      );
    }
    if (_showMap) return _buildMapView(c);
    return _buildListView(c);
  }

  Widget _buildListView(AppThemeColors c) {
    return RefreshIndicator(
      onRefresh: _load,
      color: c.accentTertiary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: [
          _buildLocationRow(c),
          const SizedBox(height: 10),
          if (_weather!.current != null) _buildCurrentCard(c),
          const SizedBox(height: 14),
          _buildChart(c),
          const SizedBox(height: 14),
          ..._weather!.daily.map(
            (d) => _DayCard(
              day: d,
              emoji: _emoji(d.weatherCode),
              hourly:
                  _weather!.hourlyByDay[DateTime(
                    d.dateTime.year,
                    d.dateTime.month,
                    d.dateTime.day,
                  ).millisecondsSinceEpoch] ??
                  [],
              c: c,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(AppThemeColors c) {
    return Row(
      children: [
        GestureDetector(
          onTap: _locateUser,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: _isLocating
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.accentTertiary,
                    ),
                  )
                : Icon(Icons.my_location, size: 18, color: c.accentTertiary),
          ),
        ),
        const SizedBox(width: 10),
        Icon(Icons.location_on, size: 16, color: c.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            _locationName,
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentCard(AppThemeColors c) {
    final cur = _weather!.current!;
    final feelsLike = cur.apparentTemperature;
    final windDir = cur.windDirection;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.card, c.card.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.accentTertiary.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${cur.temperature.toStringAsFixed(1)}°C',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: c.text,
                ),
              ),
              const SizedBox(width: 16),
              if (feelsLike != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Feels like',
                      style: TextStyle(fontSize: 11, color: c.textSecondary),
                    ),
                    Text(
                      '${feelsLike.toStringAsFixed(1)}°C',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: c.accentTertiary,
                      ),
                    ),
                  ],
                ),
              const Spacer(),
              Text(
                _emoji(_weather!.daily.first.weatherCode),
                style: const TextStyle(fontSize: 40),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _miniStat(c, Icons.water_drop, '${cur.humidity}%', 'Humidity'),
              if (cur.windSpeed != null)
                _miniStat(
                  c,
                  Icons.air,
                  '${cur.windSpeed!.toStringAsFixed(1)} km/h',
                  'Wind',
                  trailing: windDir != null ? _windArrow(windDir, c) : null,
                ),
              if (cur.pressure != null)
                _miniStat(
                  c,
                  Icons.speed,
                  '${cur.pressure!.toStringAsFixed(0)} hPa',
                  'Pressure',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
    AppThemeColors c,
    IconData icon,
    String value,
    String label, {
    Widget? trailing,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: c.accentTertiary),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.text,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 4), trailing],
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, color: c.textSecondary)),
        ],
      ),
    );
  }

  Widget _windArrow(double degrees, AppThemeColors c) {
    return Transform.rotate(
      angle: degrees * math.pi / 180,
      child: Icon(Icons.arrow_upward, size: 14, color: c.accentTertiary),
    );
  }

  Widget _buildChart(AppThemeColors c) {
    final daily = _weather!.daily;
    if (daily.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 140,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: BoxDecoration(
        color: c.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.accentTertiary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, size: 14, color: c.accentTertiary),
              const SizedBox(width: 6),
              Text(
                '7-Day Temperature',
                style: TextStyle(
                  fontSize: 11,
                  color: c.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _TempChart(daily: daily, c: c),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView(AppThemeColors c) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(_lat, _lng),
            initialZoom: 8.0,
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
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.location_on,
                    color: Colors.purple,
                    size: 40,
                  ),
                ),
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
            child: Text(
              _locationName,
              style: TextStyle(fontSize: 11, color: c.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}

class _TempChart extends StatelessWidget {
  final List<DailyWeather> daily;
  final AppThemeColors c;
  const _TempChart({required this.daily, required this.c});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _ChartPainter(daily, c),
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<DailyWeather> daily;
  final AppThemeColors c;
  _ChartPainter(this.daily, this.c);

  @override
  void paint(Canvas canvas, Size size) {
    if (daily.isEmpty) return;
    final allTemps = daily
        .expand((d) => [d.temperatureMax, d.temperatureMin])
        .toList();
    final minT = allTemps.reduce((a, b) => a < b ? a : b) - 2;
    final maxT = allTemps.reduce((a, b) => a > b ? a : b) + 2;
    final range = maxT - minT;
    if (range <= 0) return;

    final stepX = size.width / (daily.length - 1);
    final highPaint = Paint()
      ..color = c.accentTertiary
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final lowPaint = Paint()
      ..color = const Color(0xFF74B9FF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < daily.length; i++) {
      final x = i * stepX;
      final yHigh =
          size.height -
          ((daily[i].temperatureMax - minT) / range) * (size.height - 20) -
          10;
      final yLow =
          size.height -
          ((daily[i].temperatureMin - minT) / range) * (size.height - 20) -
          10;
      final nextYHigh = i < daily.length - 1
          ? size.height -
                ((daily[i + 1].temperatureMax - minT) / range) *
                    (size.height - 20) -
                10
          : yHigh;
      final nextYLow = i < daily.length - 1
          ? size.height -
                ((daily[i + 1].temperatureMin - minT) / range) *
                    (size.height - 20) -
                10
          : yLow;
      final nextX = i < daily.length - 1 ? (i + 1) * stepX : x;

      canvas.drawLine(Offset(x, yHigh), Offset(nextX, nextYHigh), highPaint);
      canvas.drawLine(Offset(x, yLow), Offset(nextX, nextYLow), lowPaint);

      canvas.drawCircle(
        Offset(x, yHigh),
        3.5,
        dotPaint..color = c.accentTertiary,
      );
      canvas.drawCircle(
        Offset(x, yLow),
        3.5,
        dotPaint..color = const Color(0xFF74B9FF),
      );

      final dayName = [
        'S',
        'M',
        'T',
        'W',
        'T',
        'F',
        'S',
      ][daily[i].dateTime.weekday % 7];
      final tp = TextPainter(
        text: TextSpan(
          text: dayName,
          style: TextStyle(fontSize: 8, color: c.textSecondary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - 9));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DayCard extends StatefulWidget {
  final DailyWeather day;
  final String emoji;
  final List<HourlyWeather> hourly;
  final AppThemeColors c;
  const _DayCard({
    required this.day,
    required this.emoji,
    required this.hourly,
    required this.c,
  });

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.day;
    final c = widget.c;
    final hasHourly = widget.hourly.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.accentTertiary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: hasHourly
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          _formatDate(d.date),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.text,
                          ),
                        ),
                      ),
                      Text(widget.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _tempBar(c, d.temperatureMin, d.temperatureMax),
                      ),
                      if (hasHourly)
                        Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                          color: c.textSecondary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const SizedBox(width: 90),
                        if (d.precipitationProbability != null) ...[
                          Icon(Icons.water_drop, size: 11, color: Colors.blue.shade300),
                          const SizedBox(width: 2),
                          Text(
                            '${d.precipitationProbability!.toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 10, color: Colors.blue.shade300),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (d.uvIndex != null) ...[
                          Icon(Icons.wb_sunny, size: 11, color: Colors.orange.shade300),
                          const SizedBox(width: 2),
                          Text(
                            'UV ${d.uvIndex!.toStringAsFixed(1)}',
                            style: TextStyle(fontSize: 10, color: Colors.orange.shade300),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (d.windSpeedMax != null) ...[
                          Icon(Icons.air, size: 11, color: c.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            '${d.windSpeedMax!.toStringAsFixed(0)} km/h',
                            style: TextStyle(fontSize: 10, color: c.textSecondary),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (d.sunrise != null && d.sunset != null) ...[
                          Icon(Icons.wb_sunny, size: 10, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            _formatTime(d.sunrise!),
                            style: TextStyle(fontSize: 9, color: Colors.amber),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.nights_stay, size: 10, color: c.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            _formatTime(d.sunset!),
                            style: TextStyle(fontSize: 9, color: c.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded && hasHourly) _buildHourly(c),
        ],
      ),
    );
  }

  Widget _buildHourly(AppThemeColors c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: widget.hourly.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final h = widget.hourly[i];
            return Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    '${h.hour}:00',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _hourEmoji(h.weatherCode),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${h.temperature.toStringAsFixed(0)}°',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                  if (h.precipitationProbability != null)
                    Text(
                      '${h.precipitationProbability!.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.blue.shade300,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Widget _tempBar(AppThemeColors c, double min, double max) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: Container(
      height: 8,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(
        builder: (_, constraints) {
          return Row(
            children: [
              Container(
                width: constraints.maxWidth * 0.5,
                color: Colors.transparent,
              ),
              Container(
                width: constraints.maxWidth * 0.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF74B9FF), c.accentTertiary],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

String _formatDate(String raw) {
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${days[dt.weekday - 1]} ${dt.day}/${dt.month}';
}

String _formatTime(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso.length >= 5 ? iso.substring(11, 16) : iso;
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

const _hourEmojiMap = {
  0: '☀️',
  1: '🌤',
  2: '⛅',
  3: '☁️',
  45: '🌫',
  48: '🌫',
  51: '🌦',
  53: '🌦',
  55: '🌦',
  56: '🌧',
  57: '🌧',
  61: '🌧',
  63: '🌧',
  65: '🌧',
  66: '🌧',
  67: '🌧',
  71: '🌨',
  73: '🌨',
  75: '🌨',
  77: '🌨',
  80: '🌦',
  81: '🌦',
  82: '🌦',
  85: '🌨',
  86: '🌨',
  95: '⛈',
  96: '⛈',
  99: '⛈',
};

String _hourEmoji(int code) => _hourEmojiMap[code] ?? '❓';
