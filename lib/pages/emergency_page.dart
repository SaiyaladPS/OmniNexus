import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../data/first_aid_data.dart';
import '../services/medicine_service.dart';
import '../services/maps_config.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sosStop();
    _tabController.dispose();
    _medNameCtrl.dispose();
    _medDosageCtrl.dispose();
    _iceNameCtrl.dispose();
    _icePhoneCtrl.dispose();
    _iceRelCtrl.dispose();
    super.dispose();
  }

  // --- SOS ---
  Timer? _strobeTimer;
  bool _strobeOn = false;
  Timer? _sirenTimer;
  FlutterTts? _tts;
  bool _sosActive = false;
  int? _sosCountdown;
  Position? _sosPosition;

  void _sosStartWithCountdown() {
    _sosCountdown = 3;
    HapticFeedback.heavyImpact();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sosCountdown == null || _sosCountdown! <= 1) {
        timer.cancel();
        _sosCountdown = null;
        _sosStart();
        return;
      }
      _sosCountdown = _sosCountdown! - 1;
      HapticFeedback.heavyImpact();
      if (mounted) setState(() {});
    });
    if (mounted) setState(() {});
  }

  Future<void> _sosStart() async {
    _sosActive = true;
    _sosPosition = await _getPosition();
    HapticFeedback.heavyImpact();

    _strobeTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      _strobeOn = !_strobeOn;
      if (mounted) setState(() {});
    });

    _tts = FlutterTts();
    _sirenTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        await _tts?.setVolume(1.0);
        await _tts?.speak('Emergency! Help! Emergency!');
      } catch (_) {}
      HapticFeedback.heavyImpact();
    });
    if (mounted) setState(() {});
  }

  void _sosStop() {
    _sosActive = false;
    _sosCountdown = null;
    _strobeTimer?.cancel();
    _strobeTimer = null;
    _sirenTimer?.cancel();
    _sirenTimer = null;
    _tts?.stop();
    _tts = null;
    _strobeOn = false;
    _sosPosition = null;
    if (mounted) setState(() {});
  }

  Future<Position?> _getPosition() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever)
        return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareLocation(Position pos) async {
    final msg =
        'Emergency! My location: ${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}. '
        'https://www.google.com/maps?q=${pos.latitude},${pos.longitude}';
    await Share.share(msg);
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) _showSnack('Cannot make calls on this device');
    }
  }

  // --- Hospital Finder ---
  LatLng? _hospitalMapCenter;
  bool _hospitalMapLoading = false;
  List<_Hospital> _nearbyHospitals = [];
  bool _hospitalFetching = false;

  Future<void> _initHospitalMap() async {
    if (_hospitalMapCenter != null) return;
    setState(() => _hospitalMapLoading = true);
    final pos = await _getPosition();
    if (pos != null) {
      _hospitalMapCenter = LatLng(pos.latitude, pos.longitude);
    } else {
      _hospitalMapCenter = const LatLng(13.736717, 100.523186);
    }
    if (mounted) setState(() => _hospitalMapLoading = false);
    _fetchNearbyHospitals();
  }

  Future<void> _fetchNearbyHospitals() async {
    if (_hospitalMapCenter == null || _hospitalFetching) return;
    setState(() => _hospitalFetching = true);
    try {
      final lat = _hospitalMapCenter!.latitude;
      final lng = _hospitalMapCenter!.longitude;
      final query = '''
        [out:json];
        node["amenity"="hospital"](around:5000,$lat,$lng);
        out body;
      ''';
      final url = 'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map;
        final elements = data['elements'] as List;
        final hospitals = <_Hospital>[];
        for (final el in elements) {
          final tags = el['tags'] as Map? ?? {};
          hospitals.add(_Hospital(
            name: tags['name'] ?? 'Hospital',
            lat: (el['lat'] as num).toDouble(),
            lng: (el['lon'] as num).toDouble(),
            address: tags['addr:full'] ?? tags['addr:street'] ?? '',
          ));
        }
        hospitals.sort((a, b) => a.name.compareTo(b.name));
        if (mounted) setState(() => _nearbyHospitals = hospitals);
      }
    } catch (_) {}
    if (mounted) setState(() => _hospitalFetching = false);
  }

  Future<void> _openHospitalMap() async {
    final pos = await _getPosition();
    if (pos == null) {
      if (mounted) _showSnack('Could not get location. Please enable GPS.');
      return;
    }
    final url =
        'https://www.google.com/maps/search/hospital+near/@${pos.latitude},${pos.longitude},14z';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) _showSnack('Could not open Google Maps');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // --- Medicine ---
  final _medNameCtrl = TextEditingController();
  final _medDosageCtrl = TextEditingController();
  TimeOfDay _medTime = const TimeOfDay(hour: 8, minute: 0);
  List<int> _medDays = [1, 2, 3, 4, 5, 6, 7];

  void _showAddMedicine() {
    _medNameCtrl.clear();
    _medDosageCtrl.clear();
    _medTime = const TimeOfDay(hour: 8, minute: 0);
    _medDays = [1, 2, 3, 4, 5, 6, 7];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _buildAddMedicineSheet(ctx),
    );
  }

  Widget _buildAddMedicineSheet(BuildContext ctx) {
    final theme = ThemeProviderScope.of(context);
    final c = theme.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(ctx).viewInsets.bottom + 20,
      ),
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
            'Add Medicine',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: c.text,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _medNameCtrl,
            decoration: InputDecoration(
              labelText: 'Medicine name',
              filled: true,
              fillColor: c.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _medDosageCtrl,
            decoration: InputDecoration(
              labelText: 'Dosage (e.g. 1 tablet, 5ml)',
              filled: true,
              fillColor: c.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final t = await showTimePicker(
                context: ctx,
                initialTime: _medTime,
              );
              if (t != null) setState(() => _medTime = t);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: c.accent, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Time: ${_medTime.format(ctx)}',
                    style: TextStyle(color: c.text),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Repeat:',
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: List.generate(7, (i) {
              final day = i + 1;
              final sel = _medDays.contains(day);
              const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              return FilterChip(
                label: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    color: sel ? Colors.white : c.text,
                  ),
                ),
                selected: sel,
                selectedColor: c.accent,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _medDays.add(day);
                    } else {
                      _medDays.remove(day);
                    }
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _addMedicine,
              child: const Text('Save Reminder'),
            ),
          ),
        ],
      ),
    );
  }

  void _addMedicine() {
    final name = _medNameCtrl.text.trim();
    if (name.isEmpty) return;
    if (_medDays.isEmpty) return;
    medicineService.add(
      Medicine(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        dosage: _medDosageCtrl.text.trim(),
        hour: _medTime.hour,
        minute: _medTime.minute,
        daysOfWeek: List.from(_medDays),
      ),
    );
    Navigator.pop(context);
    setState(() {});
  }

  void _deleteMedicine(String id) {
    medicineService.remove(id);
    setState(() {});
  }

  // --- ICE Contacts ---
  final _iceNameCtrl = TextEditingController();
  final _icePhoneCtrl = TextEditingController();
  final _iceRelCtrl = TextEditingController();

  void _showAddIceContact() {
    _iceNameCtrl.clear();
    _icePhoneCtrl.clear();
    _iceRelCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) {
        final tc = ThemeProviderScope.of(context).colors;
        return AlertDialog(
          backgroundColor: tc.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Add Emergency Contact',
            style: TextStyle(color: tc.text),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _iceNameCtrl,
                decoration: InputDecoration(
                  labelText: 'Name',
                  filled: true,
                  fillColor: tc.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _icePhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone number',
                  filled: true,
                  fillColor: tc.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _iceRelCtrl,
                decoration: InputDecoration(
                  labelText: 'Relationship (e.g. Spouse, Parent)',
                  filled: true,
                  fillColor: tc.surface,
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
              onPressed: () {
                final name = _iceNameCtrl.text.trim();
                final phone = _icePhoneCtrl.text.trim();
                if (name.isEmpty || phone.isEmpty) return;
                iceService.addContact(
                  IceContact(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    phone: phone,
                    relationship: _iceRelCtrl.text.trim(),
                  ),
                );
                Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // --- Medical ID ---
  void _showEditMedicalId() {
    final mid = iceService.medicalId;
    final bloodCtrl = TextEditingController(text: mid.bloodType ?? '');
    final allerCtrl = TextEditingController(text: mid.allergies ?? '');
    final condCtrl = TextEditingController(text: mid.conditions ?? '');
    final notesCtrl = TextEditingController(text: mid.notes ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        final tc = ThemeProviderScope.of(context).colors;
        return AlertDialog(
          backgroundColor: tc.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Medical ID', style: TextStyle(color: tc.text)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: bloodCtrl.text.isNotEmpty
                      ? bloodCtrl.text
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Blood Type',
                    filled: true,
                    fillColor: tc.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items:
                      [
                            'A+',
                            'A-',
                            'B+',
                            'B-',
                            'AB+',
                            'AB-',
                            'O+',
                            'O-',
                            'Unknown',
                          ]
                          .map(
                            (b) => DropdownMenuItem(value: b, child: Text(b)),
                          )
                          .toList(),
                  onChanged: (v) => bloodCtrl.text = v ?? '',
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: allerCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Allergies',
                    hintText: 'e.g. Penicillin, Peanuts',
                    filled: true,
                    fillColor: tc.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: condCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Medical Conditions',
                    hintText: 'e.g. Diabetes, Asthma',
                    filled: true,
                    fillColor: tc.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Additional Notes',
                    hintText: 'e.g. Organ donor, Medications',
                    filled: true,
                    fillColor: tc.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                iceService.updateMedicalId(
                  MedicalId(
                    bloodType: bloodCtrl.text.isNotEmpty
                        ? bloodCtrl.text
                        : null,
                    allergies: allerCtrl.text.isNotEmpty
                        ? allerCtrl.text
                        : null,
                    conditions: condCtrl.text.isNotEmpty ? condCtrl.text : null,
                    notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                  ),
                );
                Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProviderScope.of(context);
    final c = theme.colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Emergency & First Aid'),
        backgroundColor: c.card,
        foregroundColor: c.text,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: c.accent,
          labelColor: c.accent,
          unselectedLabelColor: c.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.warning_amber), text: 'SOS'),
            Tab(icon: Icon(Icons.healing), text: 'First Aid'),
            Tab(icon: Icon(Icons.local_hospital), text: 'Hospital'),
            Tab(icon: Icon(Icons.medication), text: 'Medicine'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildSosTab(c),
              _buildFirstAidTab(c),
              _buildHospitalTab(c),
              _buildMedicineTab(c),
            ],
          ),
          if (_sosActive && _strobeOn)
            IgnorePointer(
              child: Container(color: Colors.white.withValues(alpha: 0.85)),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SOS Tab
  // ===========================================================================
  Widget _buildSosTab(AppThemeColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          if (_sosCountdown != null) ...[
            const SizedBox(height: 40),
            Text(
              'Activating in',
              style: TextStyle(color: Colors.red.shade200, fontSize: 18),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                '${_sosCountdown!}',
                key: ValueKey(_sosCountdown),
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      color: Colors.redAccent.withValues(alpha: 0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap again to cancel',
              style: TextStyle(color: Colors.red.shade200, fontSize: 13),
            ),
            const SizedBox(height: 40),
          ] else ...[
            _buildSosButton(c),
            const SizedBox(height: 20),
            _sosActive ? _buildSosActiveInfo(c) : _buildSosInactiveInfo(c),
          ],
        ],
      ),
    );
  }

  Widget _buildSosButton(AppThemeColors c) {
    final container = _sosActive
        ? Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.redAccent,
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.6),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stop_circle, color: Colors.white, size: 48),
                const SizedBox(height: 8),
                const Text(
                  'TAP TO STOP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          )
        : Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.red.shade500, Colors.red.shade800],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.shade700.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber, color: Colors.white, size: 48),
                const SizedBox(height: 8),
                const Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          );
    return GestureDetector(
      onTap: () {
        if (_sosActive) {
          _sosStop();
        } else if (_sosCountdown != null) {
          _sosStop();
        } else {
          _sosStartWithCountdown();
        }
      },
      child: container,
    );
  }

  Widget _buildSosInactiveInfo(AppThemeColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'Tap the SOS button for\nemergency assistance',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textSecondary, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade700,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'SOS activates: Strobe light, voice siren, and vibration. '
                    'A 3-second countdown prevents accidental activation.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade800,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSosActiveInfo(AppThemeColors c) {
    final pos = _sosPosition;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.volume_up, color: Colors.white60, size: 20),
            const SizedBox(width: 6),
            const Text(
              'Siren + Strobe Active',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
        if (pos != null) ...[
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  'My Location',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Text(
                  '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionBtn(
                        icon: Icons.share,
                        label: 'Share Location',
                        color: Colors.blue.shade300,
                        onTap: () => _shareLocation(pos),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickActionBtn(
                        icon: Icons.content_copy,
                        label: 'Copy Coords',
                        color: Colors.teal.shade300,
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(
                              text:
                                  '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}',
                            ),
                          );
                          _showSnack('Coordinates copied');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildSpeedDial(c, isSos: true),
      ],
    );
  }

  // ===========================================================================
  // Speed Dial
  // ===========================================================================
  Widget _buildSpeedDial(AppThemeColors c, {bool isSos = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSos ? 24 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSos) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade400, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'For life-threatening emergencies, call the appropriate number immediately.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Emergency Numbers',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.text,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _EmergencyCallBtn(
                  label: 'Police',
                  number: '191',
                  icon: Icons.local_police,
                  color: Colors.blue.shade600,
                  onTap: () => _callNumber('191'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EmergencyCallBtn(
                  label: 'Ambulance',
                  number: '1669',
                  icon: Icons.local_hospital,
                  color: Colors.red.shade600,
                  onTap: () => _callNumber('1669'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EmergencyCallBtn(
                  label: 'Fire',
                  number: '199',
                  icon: Icons.fire_extinguisher,
                  color: Colors.orange.shade600,
                  onTap: () => _callNumber('199'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // First Aid Tab
  // ===========================================================================
  Widget _buildFirstAidTab(AppThemeColors c) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade500, Colors.red.shade700],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emergency, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Emergency Numbers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SmallCallBtn(
                      label: 'Police',
                      number: '191',
                      onTap: () => _callNumber('191'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SmallCallBtn(
                      label: 'Ambulance',
                      number: '1669',
                      onTap: () => _callNumber('1669'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SmallCallBtn(
                      label: 'Fire',
                      number: '199',
                      onTap: () => _callNumber('199'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(firstAidTopics.length, (i) {
          final topic = firstAidTopics[i];
          final severityColor = topic.severity == 'Critical'
              ? Colors.redAccent
              : Colors.orangeAccent;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: c.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ExpansionTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    topic.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              title: Text(
                topic.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: c.text,
                ),
              ),
              subtitle: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      topic.severity,
                      style: TextStyle(
                        fontSize: 10,
                        color: severityColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      topic.overview,
                      style: TextStyle(fontSize: 11, color: c.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      ...List.generate(topic.steps.length, (j) {
                        final step = topic.steps[j];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: severityColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${j + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: severityColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  step.text,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: c.text,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (topic.warning != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning,
                                color: Colors.red.shade400,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  topic.warning!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade700,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // Hospital Tab
  // ===========================================================================
  Widget _buildHospitalTab(AppThemeColors c) {
    _initHospitalMap();
    final markers = <Marker>[
      if (_hospitalMapCenter != null)
        Marker(
          point: _hospitalMapCenter!,
          width: 40,
          height: 40,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 28),
        ),
      ..._nearbyHospitals.map((h) => Marker(
            point: LatLng(h.lat, h.lng),
            width: 34,
            height: 34,
            child: GestureDetector(
              onTap: () => _openHospitalDirections(h),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.local_hospital, color: Colors.white, size: 18),
              ),
            ),
          )),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hospitalMapCenter != null)
            Container(
              height: 340,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.accent.withValues(alpha: 0.2)),
              ),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _hospitalMapCenter!,
                  initialZoom: 14.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapsConfig.tileUrl,
                    userAgentPackageName: 'com.omninexus.app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
            )
          else if (_hospitalMapLoading)
            const SizedBox(
              height: 340,
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _openHospitalMap,
              icon: const Icon(Icons.directions),
              label: const Text(
                'Open in Google Maps',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_hospitalFetching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Searching nearby hospitals...', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          if (!_hospitalFetching && _nearbyHospitals.isNotEmpty) ...[
            Text(
              '${_nearbyHospitals.length} hospital${_nearbyHospitals.length == 1 ? '' : 's'} found nearby',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text),
            ),
            const SizedBox(height: 8),
            ...List.generate(_nearbyHospitals.length, (i) {
              final h = _nearbyHospitals[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _openHospitalDirections(h),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.accent.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.local_hospital, color: Colors.red.shade500, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                h.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: c.text,
                                ),
                              ),
                              if (h.address.isNotEmpty)
                                Text(
                                  h.address,
                                  style: TextStyle(fontSize: 11, color: c.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Icon(Icons.navigation, color: Colors.red.shade400, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
          if (!_hospitalFetching && _nearbyHospitals.isEmpty && _hospitalMapCenter != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No hospitals found nearby. Try searching on Google Maps.',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          _buildSpeedDial(c),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'First aid guides are available offline on the First Aid tab — no internet needed.',
                    style: TextStyle(fontSize: 11, color: Colors.green.shade700, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openHospitalDirections(_Hospital h) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${h.lat},${h.lng}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) _showSnack('Could not open Google Maps');
    }
  }

  // ===========================================================================
  // Medicine Tab (with ICE Contacts + Medical ID)
  // ===========================================================================
  Widget _buildMedicineTab(AppThemeColors c) {
    final meds = medicineService.medicines;
    final contacts = iceService.contacts;
    final mid = iceService.medicalId;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Medical ID Card ---
        _buildSectionHeader(
          c,
          'Medical ID',
          Icons.assignment_ind,
          onEdit: _showEditMedicalId,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showEditMedicalId,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      mid.bloodType ?? '?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mid.allergies != null)
                        _medIdTag(
                          c,
                          'Allergies: ${mid.allergies}',
                          Icons.warning_amber,
                        ),
                      if (mid.conditions != null)
                        _medIdTag(
                          c,
                          'Conditions: ${mid.conditions}',
                          Icons.healing,
                        ),
                      if (mid.bloodType == null &&
                          mid.allergies == null &&
                          mid.conditions == null)
                        Text(
                          'Tap to add medical info',
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.edit, color: c.textSecondary, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // --- ICE Contacts ---
        _buildSectionHeader(
          c,
          'ICE Contacts',
          Icons.contacts,
          onAdd: _showAddIceContact,
        ),
        const SizedBox(height: 8),
        if (contacts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.accent.withValues(alpha: 0.15)),
            ),
            child: Center(
              child: Text(
                'No emergency contacts yet.\nTap + to add someone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 13),
              ),
            ),
          )
        else
          ...List.generate(contacts.length, (i) {
            final contact = contacts[i];
            return Dismissible(
              key: ValueKey(contact.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) {
                iceService.removeContact(contact.id);
                setState(() {});
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.accent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.blue.shade400,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: c.text,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            contact.phone,
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          if (contact.relationship.isNotEmpty)
                            Text(
                              contact.relationship,
                              style: TextStyle(
                                color: c.textSecondary.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _callNumber(contact.phone),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.phone,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 20),

        // --- Medicine Reminders ---
        _buildSectionHeader(
          c,
          'Medicine Reminders',
          Icons.medication,
          onAdd: _showAddMedicine,
          subtitle: '${meds.length} reminder${meds.length == 1 ? '' : 's'}',
        ),
        const SizedBox(height: 8),
        if (meds.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.accent.withValues(alpha: 0.15)),
            ),
            child: Center(
              child: Text(
                'No medicine reminders.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 13),
              ),
            ),
          )
        else
          ...List.generate(meds.length, (i) {
            final med = meds[i];
            return Dismissible(
              key: ValueKey(med.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => _deleteMedicine(med.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: med.enabled
                        ? c.accent.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => medicineService.toggle(med.id),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: med.enabled
                              ? c.accent.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.medication,
                          color: med.enabled ? c.accent : Colors.grey,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: med.enabled ? c.text : Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          if (med.dosage.isNotEmpty)
                            Text(
                              med.dosage,
                              style: TextStyle(
                                fontSize: 12,
                                color: c.textSecondary,
                              ),
                            ),
                          Text(
                            '${med.timeFormatted} • ${med.daysFormatted}',
                            style: TextStyle(
                              fontSize: 11,
                              color: c.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: med.enabled,
                      activeThumbColor: c.accent,
                      onChanged: (_) {
                        medicineService.toggle(med.id);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(
    AppThemeColors c,
    String title,
    IconData icon, {
    VoidCallback? onAdd,
    VoidCallback? onEdit,
    String? subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: c.accent, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: c.text,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: c.textSecondary),
          ),
        ],
        const Spacer(),
        if (onAdd != null)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add, color: c.accent, size: 18),
            ),
          ),
        if (onEdit != null)
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.edit, color: c.accent, size: 18),
            ),
          ),
      ],
    );
  }

  Widget _medIdTag(AppThemeColors c, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: c.textSecondary),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: c.textSecondary)),
        ],
      ),
    );
  }
}

// ===========================================================================
// Reusable Widgets
// ===========================================================================
class _EmergencyCallBtn extends StatelessWidget {
  final String label;
  final String number;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _EmergencyCallBtn({
    required this.label,
    required this.number,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              number,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }
}

class _SmallCallBtn extends StatelessWidget {
  final String label;
  final String number;
  final VoidCallback onTap;

  const _SmallCallBtn({
    required this.label,
    required this.number,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hospital {
  final String name;
  final double lat;
  final double lng;
  final String address;
  const _Hospital({
    required this.name,
    required this.lat,
    required this.lng,
    this.address = '',
  });
}
