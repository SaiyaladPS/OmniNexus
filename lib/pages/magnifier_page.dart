import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MagnifierPage extends StatefulWidget {
  const MagnifierPage({super.key});

  @override
  State<MagnifierPage> createState() => _MagnifierPageState();
}

class _MagnifierPageState extends State<MagnifierPage> {
  CameraController? _camera;
  bool _initialized = false;
  bool _torchOn = false;
  bool _contrastMode = false;
  bool _showGrid = false;
  bool _frozen = false;
  String? _frozenImagePath;
  double _zoomLevel = 1.0;
  double _baseZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  double _brightness = 1.0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final camera = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _camera = camera;
      await camera.initialize();
      final maxZoom = await camera.getMaxZoomLevel();
      if (mounted) {
        setState(() {
          _initialized = true;
          _zoomLevel = 1.0;
          _baseZoomLevel = 1.0;
          _maxZoomLevel = maxZoom;
        });
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _toggleTorch() async {
    if (_camera == null || !_initialized) return;
    final mode = _torchOn ? FlashMode.off : FlashMode.torch;
    await _camera!.setFlashMode(mode);
    if (mounted) setState(() => _torchOn = !_torchOn);
  }

  void _toggleContrast() => setState(() => _contrastMode = !_contrastMode);

  void _toggleGrid() => setState(() => _showGrid = !_showGrid);

  Future<void> _toggleFreeze() async {
    if (_frozen) {
      setState(() {
        _frozen = false;
        _frozenImagePath = null;
      });
      return;
    }
    if (_camera == null || !_initialized) return;
    try {
      final xFile = await _camera!.takePicture();
      if (mounted) {
        setState(() {
          _frozen = true;
          _frozenImagePath = xFile.path;
        });
      }
    } catch (e) {
      debugPrint('Freeze error: $e');
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseZoomLevel = _zoomLevel;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_camera == null || !_initialized) return;
    final newZoom = (_baseZoomLevel * details.scale).clamp(1.0, _maxZoomLevel);
    if (newZoom != _zoomLevel) {
      _zoomLevel = newZoom;
      _camera!.setZoomLevel(newZoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeProviderScope.of(context).colors;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Super Magnifier'),
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildPreview(c),
          if (!_frozen) ...[
            Positioned(
              top: 8,
              left: 16,
              child: _ZoomIndicator(zoom: _zoomLevel),
            ),
            if (_showGrid)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _GridPainter()),
                ),
              ),
          ],
          if (_brightness < 1.0)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(alpha: (1.0 - _brightness) * 0.7),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomControls(
              torchOn: _torchOn,
              contrastMode: _contrastMode,
              showGrid: _showGrid,
              frozen: _frozen,
              onTorchToggle: _toggleTorch,
              onContrastToggle: _toggleContrast,
              onGridToggle: _toggleGrid,
              onFreezeToggle: _toggleFreeze,
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 96,
            child: _BrightnessSlider(
              value: _brightness,
              onChanged: (v) => setState(() => _brightness = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(AppThemeColors c) {
    if (_frozen && _frozenImagePath != null) {
      return GestureDetector(
        onTap: _toggleFreeze,
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 10.0,
          child: Center(
            child: Image.file(
              File(_frozenImagePath!),
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    if (!_initialized || _camera == null) {
      return Center(
        child: CircularProgressIndicator(color: c.accent),
      );
    }

    Widget preview = GestureDetector(
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      child: CameraPreview(_camera!),
    );

    if (_contrastMode) {
      preview = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: preview,
      );
    }

    return preview;
  }
}

class _ZoomIndicator extends StatelessWidget {
  final double zoom;
  const _ZoomIndicator({required this.zoom});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${zoom.toStringAsFixed(1)}x',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1;

    final w = size.width;
    final h = size.height;

    for (var i = 1; i < 3; i++) {
      final x = w / 3 * i;
      canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
      final y = h / 3 * i;
      canvas.drawLine(Offset(0, y), Offset(w, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomControls extends StatelessWidget {
  final bool torchOn;
  final bool contrastMode;
  final bool showGrid;
  final bool frozen;
  final VoidCallback onTorchToggle;
  final VoidCallback onContrastToggle;
  final VoidCallback onGridToggle;
  final VoidCallback onFreezeToggle;

  const _BottomControls({
    required this.torchOn,
    required this.contrastMode,
    required this.showGrid,
    required this.frozen,
    required this.onTorchToggle,
    required this.onContrastToggle,
    required this.onGridToggle,
    required this.onFreezeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 36, left: 4, right: 4),
      decoration: const BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: torchOn ? Icons.flash_on : Icons.flash_off,
            label: 'Flash',
            active: torchOn,
            onTap: onTorchToggle,
          ),
          _ControlButton(
            icon: Icons.contrast,
            label: 'Contrast',
            active: contrastMode,
            onTap: onContrastToggle,
          ),
          _ControlButton(
            icon: Icons.grid_on,
            label: 'Grid',
            active: showGrid,
            onTap: onGridToggle,
          ),
          _ControlButton(
            icon: frozen ? Icons.live_tv : Icons.photo_camera,
            label: frozen ? 'Live' : 'Freeze',
            active: frozen,
            onTap: onFreezeToggle,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: active ? Colors.white24 : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _BrightnessSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _BrightnessSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.brightness_low, color: Colors.white70, size: 18),
        Expanded(
          child: SliderTheme(
            data: const SliderThemeData(
              activeTrackColor: Colors.white70,
              inactiveTrackColor: Colors.white30,
              thumbColor: Colors.white,
              overlayColor: Colors.white24,
              trackHeight: 3,
            ),
            child: Slider(
              value: value,
              min: 0.3,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ),
        const Icon(Icons.brightness_high, color: Colors.white70, size: 18),
      ],
    );
  }
}
