import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/app_theme.dart';
import '../services/maps_config.dart';

class _Checkpoint {
  final String id;
  final double lat;
  final double lng;
  final String label;
  final String instruction;
  final double radiusMeters;

  const _Checkpoint({
    required this.id,
    required this.lat,
    required this.lng,
    required this.label,
    required this.instruction,
    this.radiusMeters = 20,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': lat,
        'lng': lng,
        'label': label,
        'instruction': instruction,
        'radiusMeters': radiusMeters,
      };

  factory _Checkpoint.fromJson(Map<String, dynamic> json) => _Checkpoint(
        id: json['id'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        label: json['label'] as String,
        instruction: json['instruction'] as String,
        radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 20,
      );
}

class SafeWayPage extends StatefulWidget {
  const SafeWayPage({super.key});

  @override
  State<SafeWayPage> createState() => _SafeWayPageState();
}

class _SafeWayPageState extends State<SafeWayPage> {
  final _mapController = MapController();
  final _tts = FlutterTts();
  final _announced = <String, DateTime>{};

  Box<String>? _box;
  List<_Checkpoint> _checkpoints = [];
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _initTts();
    await _loadCheckpoints();
    await _startListening();
    if (mounted) setState(() => _initialized = true);
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('th-TH');
    } catch (_) {
      try {
        await _tts.setLanguage('en-US');
      } catch (_) {}
    }
    await _tts.setVolume(1.0);
  }

  Future<void> _loadCheckpoints() async {
    try {
      _box = await Hive.openBox<String>('safe_way');
      final data = _box!.get('checkpoints');
      if (data != null) {
        final list = jsonDecode(data) as List;
        _checkpoints = list
            .map((e) => _Checkpoint.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      _checkpoints = [];
    }
  }

  Future<void> _saveCheckpoints() async {
    try {
      _box ??= await Hive.openBox<String>('safe_way');
      final data = jsonEncode(_checkpoints.map((e) => e.toJson()).toList());
      await _box!.put('checkpoints', data);
    } catch (_) {}
  }

  Future<void> _startListening() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) setState(() => _currentPosition = pos);

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((p) {
        if (mounted) {
          setState(() => _currentPosition = p);
          _checkProximity(p);
        }
      });
    } catch (_) {}
  }

  void _checkProximity(Position pos) {
    final now = DateTime.now();
    for (final cp in _checkpoints) {
      final dist = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        cp.lat,
        cp.lng,
      );
      if (dist <= cp.radiusMeters) {
        final last = _announced[cp.id];
        if (last == null || now.difference(last).inSeconds >= 30) {
          _announced[cp.id] = now;
          _speak(cp.instruction);
        }
      }
    }
  }

  Future<void> _speak(String text) async {
    try {
      if (text.isNotEmpty) {
        await _tts.setVolume(1.0);
        await _tts.speak(text);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _tts.stop();
    _saveCheckpoints();
    super.dispose();
  }

  void _showAddCheckpointDialog() {
    final labelCtrl = TextEditingController();
    final instructionCtrl = TextEditingController();
    final c = ThemeProviderScope.of(context).colors;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: c.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Add Checkpoint',
            style: TextStyle(color: c.text),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: InputDecoration(
                  labelText: 'Label (e.g. ຮ້ານຂາຍເຂົ້າ)',
                  filled: true,
                  fillColor: c.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: instructionCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Instruction (e.g. ລະວັງຂັ້ນໄດ)',
                  filled: true,
                  fillColor: c.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final label = labelCtrl.text.trim();
                final instruction = instructionCtrl.text.trim();
                if (label.isEmpty || instruction.isEmpty) return;
                if (_currentPosition == null) {
                  Navigator.pop(ctx);
                  return;
                }
                final cp = _Checkpoint(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  lat: _currentPosition!.latitude,
                  lng: _currentPosition!.longitude,
                  label: label,
                  instruction: instruction,
                );
                setState(() => _checkpoints.add(cp));
                await _saveCheckpoints();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showCheckpointSheet(_Checkpoint cp) {
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
              Row(
                children: [
                  Icon(Icons.flag, color: cp == _checkpoints.first
                      ? Colors.redAccent
                      : c.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cp.label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: c.text,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  cp.instruction,
                  style: TextStyle(color: c.text, fontSize: 15, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _speak(cp.instruction),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: c.accent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.volume_up, color: Colors.white, size: 20),
                            SizedBox(width: 6),
                            Text(
                              'Play',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEditCheckpointDialog(cp);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.accentSecondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.edit, color: c.accentSecondary, size: 22),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _deleteCheckpoint(cp);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.delete, color: Colors.red.shade400, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showEditCheckpointDialog(_Checkpoint cp) {
    final labelCtrl = TextEditingController(text: cp.label);
    final instructionCtrl = TextEditingController(text: cp.instruction);
    final c = ThemeProviderScope.of(context).colors;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: c.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Edit Checkpoint',
            style: TextStyle(color: c.text),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: InputDecoration(
                  labelText: 'Label',
                  filled: true,
                  fillColor: c.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: instructionCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Instruction',
                  filled: true,
                  fillColor: c.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final label = labelCtrl.text.trim();
                final instruction = instructionCtrl.text.trim();
                if (label.isEmpty || instruction.isEmpty) return;
                final idx = _checkpoints.indexWhere((e) => e.id == cp.id);
                if (idx == -1) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  return;
                }
                final updated = _Checkpoint(
                  id: cp.id,
                  lat: cp.lat,
                  lng: cp.lng,
                  label: label,
                  instruction: instruction,
                  radiusMeters: cp.radiusMeters,
                );
                setState(() => _checkpoints[idx] = updated);
                await _saveCheckpoints();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCheckpoint(_Checkpoint cp) async {
    setState(() => _checkpoints.removeWhere((e) => e.id == cp.id));
    await _saveCheckpoints();
  }

  List<Marker> _buildMarkers(AppThemeColors c) {
    final markers = <Marker>[];
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.my_location, color: Colors.white, size: 16),
          ),
        ),
      );
    }
    final colors = [c.accent, c.accentSecondary, c.accentTertiary];
    for (var i = 0; i < _checkpoints.length; i++) {
      final cp = _checkpoints[i];
      final color = colors[i % colors.length];
      markers.add(
        Marker(
          point: LatLng(cp.lat, cp.lng),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showCheckpointSheet(cp),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.flag, color: Colors.white, size: 20),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  Widget _buildStatusBar(AppThemeColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Listening...',
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
          const Spacer(),
          Text(
            '${_checkpoints.length} checkpoint${_checkpoints.length == 1 ? '' : 's'}',
            style: TextStyle(
              color: c.accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeProviderScope.of(context).colors;
    final mapCenter = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(17.9757, 102.6331);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('SafeWay Audio Navigator'),
        backgroundColor: c.card,
        foregroundColor: c.text,
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (_initialized)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: mapCenter,
                initialZoom: 16.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: MapsConfig.tileUrl,
                  userAgentPackageName: 'com.omninexus.app',
                ),
                MarkerLayer(markers: _buildMarkers(c)),
              ],
            )
          else
            const Center(child: CircularProgressIndicator()),
          if (_checkpoints.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildStatusBar(c),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: c.accent,
        foregroundColor: Colors.white,
        onPressed: _showAddCheckpointDialog,
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }
}
