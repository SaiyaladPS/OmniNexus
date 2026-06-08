import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:latlong2/latlong.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../theme/app_theme.dart';

class ArIssPage extends StatefulWidget {
  final LatLng userPosition;
  final LatLng issPosition;
  final double? distance;

  const ArIssPage({
    super.key,
    required this.userPosition,
    required this.issPosition,
    this.distance,
  });

  @override
  State<ArIssPage> createState() => _ArIssPageState();
}

class _ArIssPageState extends State<ArIssPage>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _cameraReady = false;
  String? _cameraError;

  StreamSubscription<CompassEvent>? _compassSub;
  double? _heading;
  bool _hasCompass = true;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  double _pitch = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  double _issElevation = 0;
  double _issBearing = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initCompass();
    _initAccelerometer();
    _calculateIssPosition();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _cameraError = 'No camera available';
        if (mounted) setState(() {});
        return;
      }
      final cam = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      _cameraController = CameraController(
        cam,
        ResolutionPreset.high,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _cameraReady = true);
      }
    } catch (e) {
      _cameraError = 'Camera error: $e';
      if (mounted) setState(() {});
    }
  }

  void _initCompass() {
    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      if (event.heading == null) {
        _hasCompass = false;
      } else {
        _hasCompass = true;
        _heading = event.heading;
      }
    });
    if (FlutterCompass.events == null) {
      _hasCompass = false;
    }
  }

  void _initAccelerometer() {
    _accelSub = accelerometerEventStream().listen((event) {
      final raw = math.atan2(event.y, event.z) * 180 / math.pi;
      _pitch = raw.clamp(-90.0, 90.0);
    });
  }

  void _calculateIssPosition() {
    final lat1 = widget.userPosition.latitude * math.pi / 180;
    final lon1 = widget.userPosition.longitude * math.pi / 180;
    final lat2 = widget.issPosition.latitude * math.pi / 180;
    final lon2 = widget.issPosition.longitude * math.pi / 180;

    final dLon = lon2 - lon1;
    final yB = math.sin(dLon) * math.cos(lat2);
    final xB = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    _issBearing = (math.atan2(yB, xB) * 180 / math.pi + 360) % 360;

    final dLat = lat2 - lat1;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final groundDist = 6371000 * c;

    const issAlt = 408000.0;
    _issElevation = math.atan2(issAlt, math.max(groundDist, 1)) * 180 / math.pi;
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _accelSub?.cancel();
    _cameraController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProviderScope.of(context);
    final c = theme.colors;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _buildCameraView(c),
            if (_cameraReady || _cameraError != null)
              _buildArOverlay(c),
            _buildTopBar(c),
            _buildBottomInfo(c),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView(AppThemeColors c) {
    if (_cameraError != null) {
      return _buildFallbackSky(c);
    }
    if (!_cameraReady || _cameraController == null) {
      return _buildFallbackSky(c);
    }
    if (!_cameraController!.value.isInitialized) {
      return _buildFallbackSky(c);
    }
    return ClipRect(
      child: CameraPreview(_cameraController!),
    );
  }

  Widget _buildFallbackSky(AppThemeColors c) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0a0e27),
            const Color(0xFF1a1f45),
            const Color(0xFF2d3359),
          ],
        ),
      ),
      child: Stack(
        children: List.generate(60, (i) {
          final rng = math.Random(i * 7 + 3);
          return Positioned(
            left: rng.nextDouble() * 400,
            top: rng.nextDouble() * 800,
            child: Container(
              width: rng.nextDouble() * 2 + 1,
              height: rng.nextDouble() * 2 + 1,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: rng.nextDouble() * 0.7 + 0.3,
                ),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildArOverlay(AppThemeColors c) {
    if (_heading == null || !_hasCompass) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_off, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(
              'Compass sensor required\nPoint your phone at the sky',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      );
    }
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ArOverlayPainter(
            heading: _heading!,
            issBearing: _issBearing,
            issElevation: _issElevation,
            phonePitch: _pitch,
            pulseValue: _pulseAnimation.value,
            themeColors: c,
          ),
        );
      },
    );
  }

  Widget _buildTopBar(AppThemeColors c) {
    return Positioned(
      top: 8,
      left: 0,
      right: 0,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sensors, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  _hasCompass ? 'AR Active' : 'No Compass',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildBottomInfo(AppThemeColors c) {
    final heading = _heading;
    final relAzimuth = heading != null
        ? (_issBearing - heading + 540) % 360 - 180
        : 0.0;
    final isAligned = relAzimuth.abs() < 20 && _issElevation - _pitch < 30;
    final directionLabel = _directionLabel(_issBearing);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAligned)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B887A).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.satellite_alt, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'ISS in view! Look up!',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.explore,
                  label: 'Bearing',
                  value: '${_issBearing.toStringAsFixed(0)}° $directionLabel',
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.arrow_upward,
                  label: 'Elevation',
                  value: '${_issElevation.toStringAsFixed(0)}°',
                ),
                const SizedBox(width: 8),
                if (widget.distance != null)
                  _InfoChip(
                    icon: Icons.straighten,
                    label: 'Distance',
                    value: _formatDist(widget.distance!),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (!isAligned)
              Text(
                _guidanceText(relAzimuth),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  String _directionLabel(double bearing) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[((bearing + 22.5) / 45).floor() % 8];
  }

  String _formatDist(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)}m';
    return '${(meters / 1000).toStringAsFixed(0)}km';
  }

  String _guidanceText(double relAzimuth) {
    if (relAzimuth.abs() < 15) return 'Tilt your phone up to find ISS';
    if (relAzimuth > 0) return 'Rotate right → to find ISS';
    return 'Rotate left ← to find ISS';
  }
}

class _ArOverlayPainter extends CustomPainter {
  final double heading;
  final double issBearing;
  final double issElevation;
  final double phonePitch;
  final double pulseValue;
  final AppThemeColors themeColors;

  _ArOverlayPainter({
    required this.heading,
    required this.issBearing,
    required this.issElevation,
    required this.phonePitch,
    required this.pulseValue,
    required this.themeColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawCompassRing(canvas, size);
    _drawIssMarker(canvas, size);
  }

  void _drawCompassRing(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final radius = 60.0;
    final topY = size.height - 160;
    final headingRad = -heading * math.pi / 180;

    canvas.save();
    canvas.translate(cx, topY);

    final bgPaint = Paint()
      ..color = Colors.black26
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset.zero, radius + 4, bgPaint);

    final ringPaint = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset.zero, radius, ringPaint);

    for (int i = 0; i < 36; i++) {
      final angle = i * 10 * math.pi / 180 + headingRad;
      final isMajor = i % 9 == 0;
      final outerR = isMajor ? radius : radius * 0.92;
      final innerR = radius * 0.82;
      final x1 = math.sin(angle) * innerR;
      final y1 = -math.cos(angle) * innerR;
      final x2 = math.sin(angle) * outerR;
      final y2 = -math.cos(angle) * outerR;
      final tickPaint = Paint()
        ..color = isMajor ? Colors.white60 : Colors.white24
        ..strokeWidth = isMajor ? 1.5 : 0.8;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);

      if (isMajor) {
        final labelR = radius * 0.68;
        final lx = math.sin(angle) * labelR;
        final ly = -math.cos(angle) * labelR;
        const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
        final lbl = labels[i ~/ 9];
        final tp = TextPainter(
          text: TextSpan(
            text: lbl,
            style: TextStyle(
              color: i == 0 ? Colors.white : Colors.white38,
              fontSize: i == 0 ? 12 : 10,
              fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
      }
    }

    final triPath = ui.Path()
      ..moveTo(0, -radius + 3)
      ..lineTo(-7, -radius - 12)
      ..lineTo(7, -radius - 12)
      ..close();
    final triPaint = Paint()..color = Colors.redAccent;
    canvas.drawPath(triPath, triPaint);

    canvas.restore();
  }

  void _drawIssMarker(Canvas canvas, Size size) {
    final relAzimuth = (issBearing - heading + 540) % 360 - 180;
    final relElevation = issElevation - phonePitch;

    final aziClamped = relAzimuth.clamp(-80.0, 80.0);
    final elevClamped = relElevation.clamp(-40.0, 60.0);

    final cx = size.width / 2 + (aziClamped / 80) * (size.width / 2.5);
    final cy = size.height / 2 - (elevClamped / 60) * (size.height / 3);

    final isOnScreen = relAzimuth.abs() < 80 && relElevation > -40 && relElevation < 70;
    final isAligned = relAzimuth.abs() < 15 && (issElevation - phonePitch).abs() < 20;

    if (isOnScreen) {
      _drawPulsingIss(canvas, Offset(cx, cy), isAligned);
      _drawElevationLabel(canvas, cx, cy, isAligned);
    } else {
      _drawDirectionArrow(canvas, size, relAzimuth, relElevation);
    }

    if (!isAligned && relAzimuth.abs() < 80) {
      _drawCrosshair(canvas, Offset(cx, cy));
    }
  }

  void _drawPulsingIss(Canvas canvas, Offset pos, bool aligned) {
    final baseR = aligned ? 28.0 : 20.0;
    final r = baseR * (0.8 + 0.2 * pulseValue);

    if (aligned) {
      final glowPaint = Paint()
        ..color = const Color(0xFF3B887A).withValues(alpha: 0.3 * pulseValue)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(pos, r * 1.8, glowPaint);

      final outerGlow = Paint()
        ..color = const Color(0xFF3B887A).withValues(alpha: 0.15 * pulseValue)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
      canvas.drawCircle(pos, r * 3, outerGlow);
    }

    final bgPaint = Paint()
      ..color = aligned
          ? const Color(0xFF3B887A).withValues(alpha: 0.9)
          : Colors.white.withValues(alpha: 0.2)
      ..maskFilter = aligned ? const MaskFilter.blur(BlurStyle.normal, 4) : null;
    canvas.drawCircle(pos, r, bgPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '🛰',
        style: TextStyle(fontSize: r * (aligned ? 1.1 : 0.9)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
    );

    if (aligned) {
      final labelTp = TextPainter(
        text: const TextSpan(
          text: 'ISS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelTp.paint(
        canvas,
        Offset(pos.dx - labelTp.width / 2, pos.dy + r + 4),
      );
    }
  }

  void _drawElevationLabel(Canvas canvas, double cx, double cy, bool aligned) {
    if (!aligned) return;
    final tp = TextPainter(
      text: TextSpan(
        text: '${issElevation.toStringAsFixed(0)}° above horizon',
        style: const TextStyle(color: Colors.white70, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(cx - tp.width / 2, cy - 50),
    );
  }

  void _drawCrosshair(Canvas canvas, Offset pos) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 0.5;
    const len = 12.0;
    canvas.drawLine(Offset(pos.dx - len, pos.dy), Offset(pos.dx + len, pos.dy), paint);
    canvas.drawLine(Offset(pos.dx, pos.dy - len), Offset(pos.dx, pos.dy + len), paint);
  }

  void _drawDirectionArrow(Canvas canvas, Size size, double relAzi, double relElev) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    double angle;
    if (relAzi.abs() > 80) {
      angle = relAzi > 0 ? math.pi / 2 : -math.pi / 2;
    } else if (relElev < -40) {
      angle = math.pi;
    } else {
      angle = relElev > 70 ? 0 : (relAzi > 0 ? math.pi / 4 : -math.pi / 4);
    }

    canvas.save();
    canvas.translate(cx, cy - 40);
    canvas.rotate(angle);

    final arrowPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = ui.Path()
      ..moveTo(0, -25)
      ..lineTo(-12, -8)
      ..moveTo(0, -25)
      ..lineTo(12, -8)
      ..moveTo(0, -25)
      ..lineTo(0, 20);
    canvas.drawPath(path, arrowPaint);

    canvas.restore();

    final tp = TextPainter(
      text: TextSpan(
        text: relAzi.abs() > 80
            ? 'Turn ${relAzi > 0 ? "right" : "left"} →'
            : relElev < -40
                ? 'Tilt up ↑'
                : 'Look ${relAzi > 0 ? "right" : "left"}',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy + 20));
  }

  @override
  bool shouldRepaint(covariant _ArOverlayPainter old) {
    return old.heading != heading ||
        old.issBearing != issBearing ||
        old.issElevation != issElevation ||
        old.phonePitch != phonePitch ||
        old.pulseValue != pulseValue;
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 9),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
