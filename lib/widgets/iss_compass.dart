import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:latlong2/latlong.dart';

class IssCompass extends StatefulWidget {
  final LatLng? userPosition;
  final LatLng issPosition;

  const IssCompass({
    super.key,
    required this.userPosition,
    required this.issPosition,
  });

  @override
  State<IssCompass> createState() => _IssCompassState();
}

class _IssCompassState extends State<IssCompass> {
  StreamSubscription<CompassEvent>? _compassSub;
  double? _heading;
  bool _hasSensor = true;

  @override
  void initState() {
    super.initState();
    _initCompass();
  }

  void _initCompass() {
    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      setState(() {
        if (event.heading == null) {
          _hasSensor = false;
        } else {
          _hasSensor = true;
          _heading = event.heading;
        }
      });
    });
    if (FlutterCompass.events == null) {
      _hasSensor = false;
    }
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasSensor) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF3D5A52).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore, color: Color(0xFF88B8AE), size: 18),
            SizedBox(width: 8),
            Text(
              'Compass sensor not available',
              style: TextStyle(color: Color(0xFF88B8AE), fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_heading == null) {
      return const Center(
        child: SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF5BA89A),
          ),
        ),
      );
    }

    final bearing = _calculateBearing(widget.userPosition, widget.issPosition);
    final heading = _heading!;
    final directionLabel = _directionLabel(bearing);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4F1F4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.explore, color: Color(0xFF3B887A), size: 18),
              const SizedBox(width: 6),
              const Text(
                'ISS Compass',
                style: TextStyle(
                  color: Color(0xFF3D5A52),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B887A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$directionLabel ${bearing.toStringAsFixed(0)}°',
                  style: const TextStyle(
                    color: Color(0xFF3B887A),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(160, 160),
                  painter: _CompassPainter(
                    heading: heading,
                    bearing: bearing,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${bearing.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D5A52),
                      ),
                    ),
                    Text(
                      directionLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF88B8AE),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _headingLabel(heading, bearing),
            style: const TextStyle(
              color: Color(0xFF5A7A72),
              fontSize: 11,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  double _calculateBearing(LatLng? from, LatLng to) {
    if (from == null) return 0;
    final lat1 = from.latitude * math.pi / 180;
    final lon1 = from.longitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final lon2 = to.longitude * math.pi / 180;
    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  String _directionLabel(double bearing) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return dirs[index];
  }

  String _headingLabel(double heading, double bearing) {
    final diff = (bearing - heading + 360) % 360;
    if (diff < 10 || diff > 350) {
      return 'You are facing the ISS!  Turn your phone toward the sky ↑';
    } else if (diff < 45) {
      return 'ISS is slightly to your ${diff < 22.5 ? "right" : "right-front"}';
    } else if (diff < 135) {
      return 'ISS is to your right →';
    } else if (diff < 180) {
      return 'ISS is behind and to your right';
    } else if (diff < 225) {
      return 'ISS is behind you';
    } else if (diff < 315) {
      return 'ISS is to your left ←';
    } else {
      return 'ISS is slightly to your left';
    }
  }
}

class _CompassPainter extends CustomPainter {
  final double heading;
  final double bearing;

  _CompassPainter({
    required this.heading,
    required this.bearing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final headingRad = -heading * math.pi / 180;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    final ringPaint = Paint()
      ..color = const Color(0xFFD4F1F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset.zero, radius, ringPaint);

    final innerRingPaint = Paint()
      ..color = const Color(0xFFE8F5F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset.zero, radius * 0.85, innerRingPaint);

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
        ..color = isMajor
            ? const Color(0xFF3D5A52).withValues(alpha: 0.5)
            : const Color(0xFFD4F1F4)
        ..strokeWidth = isMajor ? 1.5 : 0.8;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);

      if (isMajor) {
        final labelR = radius * 0.68;
        final lx = math.sin(angle) * labelR;
        final ly = -math.cos(angle) * labelR;
        final label = _cardinalLabel(i ~/ 9);
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: i == 0
                  ? const Color(0xFF3B887A)
                  : const Color(0xFF88B8AE),
              fontSize: i == 0 ? 14 : 11,
              fontWeight: i == 0 ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(lx - textPainter.width / 2, ly - textPainter.height / 2),
        );
      }
    }

    final issAngle = (bearing - heading) * math.pi / 180;
    final issR = radius * 0.55;
    final issX = math.sin(issAngle) * issR;
    final issY = -math.cos(issAngle) * issR;

    final linePaint = Paint()
      ..color = const Color(0xFF3B887A).withValues(alpha: 0.3)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset.zero, Offset(issX, issY), linePaint);

    final dotPaint = Paint()..color = const Color(0xFF3B887A);
    canvas.drawCircle(Offset(issX, issY), 7, dotPaint);

    final innerDotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(issX, issY), 3, innerDotPaint);

    final issLabel = TextPainter(
      text: const TextSpan(
        text: 'ISS',
        style: TextStyle(
          color: Color(0xFF3B887A),
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    issLabel.paint(
      canvas,
      Offset(issX - issLabel.width / 2, issY + 10),
    );

    final triPaint = Paint()..color = Colors.redAccent;
    final path = ui.Path()
      ..moveTo(0, -radius + 2)
      ..lineTo(-6, -radius - 10)
      ..lineTo(6, -radius - 10)
      ..close();
    canvas.drawPath(path, triPaint);

    canvas.restore();
  }

  String _cardinalLabel(int index) {
    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return labels[index % 8];
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) {
    return oldDelegate.heading != heading || oldDelegate.bearing != bearing;
  }
}
