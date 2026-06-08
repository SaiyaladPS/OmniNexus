import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/iss_now.dart';
import '../services/iss_service.dart';
import '../theme/app_theme.dart';
import '../services/maps_config.dart';
import '../widgets/iss_compass.dart';
import 'ar_iss_page.dart';

class IssPage extends StatefulWidget {
  const IssPage({super.key});

  @override
  State<IssPage> createState() => _IssPageState();
}

class _IssPageState extends State<IssPage> {
  final _service = IssService();
  Timer? _timer;
  IssNow? _issNow;
  bool _isLoading = true;
  String? _error;
  LatLng? _userPosition;
  bool _isLocating = false;
  bool _autoCenter = true;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;
  IssNow? _lastIss;

  @override
  void initState() {
    super.initState();
    _fetchIssPosition(isInitial: true);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchIssPosition(isInitial: false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchIssPosition({required bool isInitial}) async {
    if (isInitial) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final iss = await _service.fetchIssPosition();
      if (!mounted) return;
      setState(() {
        _issNow = iss;
        _isLoading = false;
        _error = null;
      });

      if (_autoCenter && !isInitial) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final issPos = LatLng(iss.position.latitude, iss.position.longitude);
          _mapController.move(issPos, _mapController.camera.zoom);
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (isInitial || _issNow == null) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      } else {
        debugPrint('Periodic ISS fetch failed: $e');
      }
    }
  }

  Future<void> _findMe() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) _showSnack('ບໍລິການລະບຸຕຳແໜ່ງຖືກປິດໃຊ້ງານ');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        if (mounted) _showSnack('ການອະນຸຍາດເຂົ້າເຖິງຕຳແໜ່ງຖືກປະຕິເສດ');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) _showSnack('การອະນຸຍາດເຂົ້າເຖິງຕຳແໜ່ງຖືກປະຕິເສດຖາວອນ');
        return;
      }

      _positionSubscription?.cancel();
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              distanceFilter: 10,
            ),
          ).listen((pos) {
            if (!mounted) return;
            setState(() {
              _userPosition = LatLng(pos.latitude, pos.longitude);
              _isLocating = false;
            });
          });

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      if (mounted) {
        setState(() => _userPosition = LatLng(pos.latitude, pos.longitude));
      }
    } catch (e) {
      if (mounted) _showSnack('ບໍ່ສາມາດດຶງຂໍ້ມູນຕຳແໜ່ງໄດ້: $e');
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF3D5A52),
      ),
    );
  }

  void _reload() {
    _fetchIssPosition(isInitial: true);
    _startTimer();
  }

  Widget _buildBody() {
    if (_isLoading && _issNow == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF5BA89A)),
            SizedBox(height: 16),
            Text(
              'ກຳລັງເຊື່ອມຕໍ່ກັບ ISS...',
              style: TextStyle(color: Color(0xFF88B8AE)),
            ),
          ],
        ),
      );
    }

    if (_error != null && _issNow == null) {
      return _ErrorContent(message: _error!, onRetry: _reload);
    }

    final iss = _issNow!;
    _lastIss = iss;
    final lat = iss.position.latitude;
    final lon = iss.position.longitude;
    final issPos = LatLng(lat, lon);

    double? distance;
    if (_userPosition != null) {
      distance = Geolocator.distanceBetween(
        _userPosition!.latitude,
        _userPosition!.longitude,
        lat,
        lon,
      );
    }

    final markers = <Marker>[
      Marker(
        point: issPos,
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF3B887A),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B887A).withValues(alpha: 0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.satellite_alt, color: Colors.white, size: 22),
        ),
      ),
    ];

    if (_userPosition != null) {
      markers.add(
        Marker(
          point: _userPosition!,
          width: 36,
          height: 36,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6C63FF),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.near_me, color: Colors.white, size: 18),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 300,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: issPos,
                  initialZoom: 3,
                  minZoom: 1,
                  maxZoom: 8,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapsConfig.tileUrl,
                    userAgentPackageName: 'com.example.omninexus',
                  ),
                  if (_userPosition != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [_userPosition!, issPos],
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                          strokeWidth: 1.5,
                        ),
                      ],
                    ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD4F1F4)),
            ),
            child: Row(
              children: [
                _LegendDot(color: const Color(0xFF3B887A), label: 'ສະຖານີ ISS'),
                const SizedBox(width: 20),
                _LegendDot(
                  color: const Color(0xFF6C63FF),
                  label: 'ຕຳແໜ່ງຂອງທ່ານ',
                ),
                if (distance != null) ...[
                  const Spacer(),
                  const Icon(
                    Icons.straighten,
                    size: 16,
                    color: Color(0xFF88B8AE),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDistance(distance),
                    style: const TextStyle(
                      color: Color(0xFF3D5A52),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_userPosition == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLocating ? null : _findMe,
                  icon: _isLocating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF5BA89A),
                          ),
                        )
                      : const Icon(Icons.my_location, color: Color(0xFF5BA89A)),
                  label: Text(
                    _isLocating
                        ? 'ກຳລັງຄົ້ນຫາຕຳແໜ່ງຂອງທ່ານ...'
                        : ' ຄົ້ນຫາຕຳແໜ່ງຂອງຂ້ອຍເທິງແຜນທີ່',
                    style: const TextStyle(
                      color: Color(0xFF3B887A),
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD4F1F4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          if (_userPosition != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: IssCompass(
                userPosition: _userPosition,
                issPosition: issPos,
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _CoordCard(
                  label: 'ລະຕິຈູດ ISS',
                  value: lat.toStringAsFixed(4),
                  suffix: '°',
                  icon: Icons.satellite_alt,
                  detail: _dms(lat, true),
                  iconColor: const Color(0xFF3B887A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CoordCard(
                  label: 'ລອງຈິຈູດ ISS',
                  value: lon.toStringAsFixed(4),
                  suffix: '°',
                  icon: Icons.satellite_alt,
                  detail: _dms(lon, false),
                  iconColor: const Color(0xFF3B887A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_userPosition != null)
            Row(
              children: [
                Expanded(
                  child: _CoordCard(
                    label: 'ລະຕິຈູດຂອງທ່ານ',
                    value: _userPosition!.latitude.toStringAsFixed(4),
                    suffix: '°',
                    icon: Icons.near_me,
                    detail: _dms(_userPosition!.latitude, true),
                    iconColor: const Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CoordCard(
                    label: 'ລອງຈິຈູດຂອງທ່ານ',
                    value: _userPosition!.longitude.toStringAsFixed(4),
                    suffix: '°',
                    icon: Icons.near_me,
                    detail: _dms(_userPosition!.longitude, false),
                    iconColor: const Color(0xFF6C63FF),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniCard(
                  icon: Icons.public,
                  label: 'ຊີກໂລກ',
                  value: _hemisphere(lat, lon),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniCard(
                  icon: Icons.map,
                  label: 'ພາກພື້ນ',
                  value: _relativePosition(lat),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniCard(
                  icon: Icons.access_time,
                  label: 'ອັບເດດແລ້ວ',
                  value:
                      '${_pad(iss.timestamp.hour)}:${_pad(iss.timestamp.minute)}:${_pad(iss.timestamp.second)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8F5F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ເຈົ້າຮູ້ຫຼືບໍ່?',
                        style: TextStyle(
                          color: Color(0xFF3B887A),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _issFacts[iss.timestamp.second % _issFacts.length],
                        style: const TextStyle(
                          color: Color(0xFF5A7A72),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              _userPosition != null
                  ? 'ແຕະໄອຄອນຕຳແໜ່ງເພື່ອອັບເດດຕຳແໜ່ງຂອງທ່ານ'
                  : 'ແຕະ "ຄົ້ນຫາຕຳແໜ່ງຂອງຂ້ອຍ" ເພື່ອເບິ່ງວ່າເຈົ້າຢູ່ໃສ',
              style: const TextStyle(color: Color(0xFFB8D8D0), fontSize: 11),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD4F1F4)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF3B887A),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'ກ່ຽວກັບ ແລະ ວິທີໃຊ້ງານ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D5A52),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '💡 ກ່ຽວກັບ:\nຕິດຕາມຕຳແໜ່ງປັດຈຸບັນຂອງສະຖານີອາວະກາດສາກົນ (ISS) ເທິງວົງໂຄຈອນໂລກ ທີ່ມີຄວາມສູງປະມານ 400 ກິໂລແມັດ ດ້ວຍຄວາມໄວປະມານ 28,000 ກມ/ຊມ.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5A7A72),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '📱 ວິທີໃຊ້ງານ:\n1. ແຜນທີ່ຈະສະແດງຕຳແໜ່ງປັດຈຸບັນຂອງ ISS (ໄອຄອນສີຂຽວ) ແບບອັດຕະໂນມັດ.\n2. ແຕະປຸ່ມ "ຄົ້ນຫາຕຳແໜ່ງຂອງຂ້ອຍເທິງແຜນທີ່" ຫຼື ໄອຄອນ GPS ຢູ່ມຸມຂວາເທິງເພື່ອລະບຸຕຳແໜ່ງຂອງທ່ານ (ໄອຄອນສີມ່ວງ).\n3. ລະບົບຈະຄຳນວນ ແລະ ສະແດງເສັ້ນໄລຍະທາງຫ່າງລະຫວ່າງທ່ານກັບສະຖານີ ISS ເປັນກິໂລແມັດ.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5A7A72),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _hemisphere(double lat, double lon) {
    final ns = lat >= 0 ? 'ເໜືອ' : 'ໃຕ້';
    final ew = lon >= 0 ? 'ຕາເວັນອອກ' : 'ຕາເວັນຕົກ';
    return '$ns / $ew';
  }

  String _relativePosition(double lat) {
    final a = lat.abs();
    if (a < 10) return 'ໃກ້ເສັ້ນສູນສູດ';
    if (a > 60) return 'ໃກ້ເຂດຂົ້ວໂລກ';
    return 'ເຂດລະຕິຈູດປານກາງ';
  }

  String _dms(double value, bool isLat) {
    final dir = isLat
        ? (value >= 0 ? 'ເໜືອ' : 'ໃຕ້')
        : (value >= 0 ? 'ຕາເວັນອອກ' : 'ຕາເວັນຕົກ');
    final abs = value.abs();
    final deg = abs.floor();
    final min = ((abs - deg) * 60).floor();
    final sec = ((abs - deg - min / 60) * 3600).toStringAsFixed(1);
    return '$deg°$min\'$sec" $dir';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    final km = meters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  static const _issFacts = [
    'ISS ໂຄຈອນອ້ອມໂລກດ້ວຍຄວາມໄວປະມານ 28,000 ກມ/ຊມ (17,500 ໄມລ໌/ຊມ).',
    'ມັນໃຊ້ເວລາປະມານ 90 ນາທີໃນການໂຄຈອນຄົບ 1 ຮອບ.',
    'ISS ເດີນທາງເປັນໄລຍະທາງທຽບເທົ່າກັບການໄປ-ກັບດວງຈັນທຸກໆວັນ.',
    'ມີຄົນອາໄສຢູ່ຢ່າງຕໍ່ເນື່ອງຕັ້ງແຕ່ເດືອນພະຈິກ ປີ 2000.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProviderScope.of(context);
    final c = theme.colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('ລະບົບຕິດຕາມ ISS ແບບລຽວທາມ'),
        backgroundColor: c.appBar,
        foregroundColor: c.accentSecondary,
        elevation: 0,
        actions: [
          IconButton(
            icon: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _userPosition != null
                      ? const Color(0xFF3B887A)
                      : Colors.transparent,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.view_in_ar,
                  size: 20,
                  color: Color(0xFF3B887A),
                ),
              ),
            ),
            onPressed: _userPosition != null ? _openAr : null,
            tooltip: _userPosition != null
                ? 'AR View'
                : 'Find your location first',
          ),
          IconButton(icon: const Icon(Icons.my_location), onPressed: _findMe),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: _buildBody(),
    );
  }

  void _openAr() {
    if (_userPosition == null || _lastIss == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArIssPage(
          userPosition: _userPosition!,
          issPosition: LatLng(
            _lastIss!.position.latitude,
            _lastIss!.position.longitude,
          ),
          distance: Geolocator.distanceBetween(
            _userPosition!.latitude,
            _userPosition!.longitude,
            _lastIss!.position.latitude,
            _lastIss!.position.longitude,
          ),
        ),
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF88B8AE), fontSize: 12),
        ),
      ],
    );
  }
}

class _CoordCard extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final IconData icon;
  final String detail;
  final Color iconColor;

  const _CoordCard({
    required this.label,
    required this.value,
    required this.suffix,
    required this.icon,
    required this.detail,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4F1F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Color(0xFF88B8AE), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$value$suffix',
            style: const TextStyle(
              color: Color(0xFF3D5A52),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: const TextStyle(color: Color(0xFF88B8AE), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4F1F4)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF5BA89A), size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF88B8AE), fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF3D5A52),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorContent extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorContent({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Color(0xFFB8D8D0)),
            const SizedBox(height: 16),
            const Text(
              'ບໍ່ສາມາດຕິດຕາມ ISS ໄດ້',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF3D5A52),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF88B8AE), fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('ລອງໃໝ່'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5BA89A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
