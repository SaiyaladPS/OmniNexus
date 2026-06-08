import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class EmergencyContact {
  final String id;
  final String name;
  final String phone;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
  };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
      );
}

class EmergencyHubPage extends StatefulWidget {
  const EmergencyHubPage({super.key});

  @override
  State<EmergencyHubPage> createState() => _EmergencyHubPageState();
}

class _EmergencyHubPageState extends State<EmergencyHubPage> {
  Box<String>? _contactsBox;
  List<EmergencyContact> _contacts = [];

  FlutterTts? _tts;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  DateTime _lastShakeTime = DateTime.now().subtract(const Duration(seconds: 4));
  bool _shakeDetected = false;
  static const double _shakeThresholdSquared = 625.0;
  static const Duration _shakeDebounce = Duration(seconds: 3);

  static const List<Map<String, String>> _defaultContacts = [
    {'name': 'ພໍ່', 'phone': ''},
    {'name': 'ແມ່', 'phone': ''},
    {'name': 'ອ້າຍ', 'phone': ''},
    {'name': 'ເອື້ອຍ', 'phone': ''},
    {'name': 'ຕຳຫຼວດ 191', 'phone': '191'},
    {'name': 'ໂຮງໝໍ 1669', 'phone': '1669'},
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _initHive().then((_) => _initAccelerometer());
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _tts?.stop();
    _tts = null;
    super.dispose();
  }

  // ─── Hive ────────────────────────────────────────────────────────────────

  Future<void> _initHive() async {
    try {
      _contactsBox = await Hive.openBox<String>('emergency_contacts');
      _loadContacts();
    } catch (_) {}
  }

  void _loadContacts() {
    final raw = _contactsBox?.get('contacts');
    if (raw != null) {
      final list = json.decode(raw) as List;
      _contacts = list
          .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (_contacts.isEmpty) {
      _contacts = _defaultContacts.asMap().entries.map((e) {
        final i = e.key;
        return EmergencyContact(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          name: e.value['name']!,
          phone: e.value['phone']!,
        );
      }).toList();
      _saveContacts();
    }
    if (mounted) setState(() {});
  }

  void _saveContacts() {
    _contactsBox?.put(
      'contacts',
      json.encode(_contacts.map((c) => c.toJson()).toList()),
    );
  }

  void _addContact(EmergencyContact contact) {
    _contacts.add(contact);
    _saveContacts();
    if (mounted) setState(() {});
  }

  void _removeContact(String id) {
    _contacts.removeWhere((c) => c.id == id);
    _saveContacts();
    if (mounted) setState(() {});
  }

  void _updateContact(String id, String name, String phone) {
    final i = _contacts.indexWhere((c) => c.id == id);
    if (i >= 0) {
      _contacts[i] = EmergencyContact(id: id, name: name, phone: phone);
      _saveContacts();
      if (mounted) setState(() {});
    }
  }

  // ─── TTS ─────────────────────────────────────────────────────────────────

  Future<void> _initTts() async {
    _tts = FlutterTts();
    try {
      await _tts?.setLanguage('th-TH');
    } catch (_) {}
  }

  Future<void> _speak(String text) async {
    try {
      await _tts?.stop();
      await _tts?.setVolume(1.0);
      await _tts?.setLanguage('th-TH');
      await _tts?.speak(text);
    } catch (_) {}
  }

  // ─── Accelerometer ───────────────────────────────────────────────────────

  void _initAccelerometer() {
    try {
      _accelSub = accelerometerEventStream().listen(_onAccelerometerEvent);
    } catch (_) {}
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    final magnitudeSquared =
        event.x * event.x + event.y * event.y + event.z * event.z;
    if (magnitudeSquared > _shakeThresholdSquared) {
      final now = DateTime.now();
      if (now.difference(_lastShakeTime) >= _shakeDebounce) {
        _lastShakeTime = now;
        _onShakeDetected();
      }
    }
  }

  Future<void> _onShakeDetected() async {
    setState(() => _shakeDetected = true);
    await _speak('ເຂຍ່າເພື່ອຂໍຄວາມຊ່ວຍເຫຼືອ');
    HapticFeedback.heavyImpact();

    final pos = await _getPosition();
    if (pos != null) {
      final primary = _contacts.cast<EmergencyContact?>().firstWhere(
        (c) => c!.phone.isNotEmpty,
        orElse: () => null,
      );
      if (primary != null) {
        final message =
            'SOS! ຂ້ອຍຕ້ອງການຄວາມຊ່ວຍເຫຼືອ! '
            'ສະຖານທີ່: https://www.google.com/maps?q=${pos.latitude},${pos.longitude}';
        final uri = Uri.parse(
          'sms:${primary.phone}?body=${Uri.encodeComponent(message)}',
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _shakeDetected = false);
    });
  }

  // ─── GPS ─────────────────────────────────────────────────────────────────

  Future<Position?> _getPosition() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied ||
            req == LocationPermission.deniedForever) {
          return null;
        }
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // ─── SMS / Call ──────────────────────────────────────────────────────────

  Future<void> _sendSms(String number, String message) async {
    final uri = Uri.parse(
      'sms:$number?body=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) _showSnack('Cannot make calls on this device');
    }
  }

  Future<void> _sendSosToAllContacts() async {
    final pos = await _getPosition();
    final locationText = pos != null
        ? 'https://www.google.com/maps?q=${pos.latitude},${pos.longitude}'
        : 'Location unavailable';
    final message = 'SOS! ຂ້ອຍຕ້ອງການຄວາມຊ່ວຍເຫຼືອ! $locationText';

    final validContacts = _contacts.where((c) => c.phone.isNotEmpty);
    for (final contact in validContacts) {
      await _sendSms(contact.phone, message);
    }
    if (mounted) {
      _showSnack('SOS sent to ${validContacts.length} contact(s)');
    }
  }

  // ─── UI Helpers ──────────────────────────────────────────────────────────

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _showSosOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final c = ThemeProviderScope.of(context).colors;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'SOS Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: c.text,
                ),
              ),
              const SizedBox(height: 20),
              _SosOptionTile(
                icon: Icons.sms,
                label: 'Send SMS to all contacts',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(ctx);
                  _sendSosToAllContacts();
                },
              ),
              const SizedBox(height: 8),
              _SosOptionTile(
                icon: Icons.phone,
                label: 'Call 191 (Police)',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(ctx);
                  _callNumber('191');
                },
              ),
              const SizedBox(height: 8),
              _SosOptionTile(
                icon: Icons.local_hospital,
                label: 'Call 1669 (Ambulance)',
                color: Colors.red.shade700,
                onTap: () {
                  Navigator.pop(ctx);
                  _callNumber('1669');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showContactManager() {
    final c = ThemeProviderScope.of(context).colors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (ctx, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: c.textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'Manage Contacts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: c.text,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            color: c.accent,
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showContactEditor();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _contacts.isEmpty
                            ? Center(
                                child: Text(
                                  'No contacts yet.',
                                  style: TextStyle(color: c.textSecondary),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: _contacts.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, i) {
                                  final contact = _contacts[i];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: c.card,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color:
                                            c.accent.withValues(alpha: 0.15),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            color: Colors.red,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                contact.name,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: c.text,
                                                ),
                                              ),
                                              if (contact.phone.isNotEmpty)
                                                Text(
                                                  contact.phone,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: c.textSecondary,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 20,
                                          ),
                                          color: c.textSecondary,
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _showContactEditor(
                                              existing: contact,
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 20,
                                          ),
                                          color: Colors.red.shade400,
                                          onPressed: () {
                                            _removeContact(contact.id);
                                            setSheetState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showContactEditor({EmergencyContact? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final isNew = existing == null;
    showDialog(
      context: context,
      builder: (ctx) {
        final c = ThemeProviderScope.of(context).colors;
        return AlertDialog(
          backgroundColor: c.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isNew ? 'Add Contact' : 'Edit Contact',
            style: TextStyle(color: c.text),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Name',
                  filled: true,
                  fillColor: c.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone',
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
            if (!isNew)
              TextButton(
                onPressed: () {
                  _removeContact(existing.id);
                  Navigator.pop(ctx);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                if (name.isEmpty) return;
                if (isNew) {
                  _addContact(
                    EmergencyContact(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      phone: phone,
                    ),
                  );
                } else {
                  _updateContact(existing.id, name, phone);
                }
                Navigator.pop(ctx);
              },
              child: Text(isNew ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = ThemeProviderScope.of(context).colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Vocalized Emergency Hub'),
        backgroundColor: c.card,
        foregroundColor: c.text,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showContactManager,
            tooltip: 'Manage contacts',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(flex: 4, child: _buildSosButton(c)),
          _buildShakeIndicator(c),
          Expanded(flex: 4, child: _buildContactList(c)),
        ],
      ),
    );
  }

  Widget _buildSosButton(AppThemeColors c) {
    return GestureDetector(
      onTap: () {
        _speak('SOS');
        _showSosOptions();
      },
      onLongPress: () {
        HapticFeedback.heavyImpact();
        _speak('SOS');
        _sendSosToAllContacts();
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade700.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber, color: Colors.white, size: 48),
              const SizedBox(height: 8),
              const Text(
                'SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap for options \u2022 Long press for SMS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShakeIndicator(AppThemeColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            _shakeDetected ? Icons.warning : Icons.vibration,
            color: _shakeDetected ? Colors.red : c.textSecondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _shakeDetected
                  ? 'Shake detected!'
                  : 'ເຂຍ່າເພື່ອຂໍຄວາມຊ່ວຍເຫຼືອ',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    _shakeDetected ? FontWeight.bold : FontWeight.normal,
                color: _shakeDetected ? Colors.red : c.text,
              ),
            ),
          ),
          if (_shakeDetected)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ACTIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactList(AppThemeColors c) {
    if (_contacts.isEmpty) {
      return Center(
        child: Text(
          'No contacts. Tap settings to add.',
          style: TextStyle(color: c.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _contacts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final contact = _contacts[i];
        return _ContactTile(
          contact: contact,
          cardColor: c.card,
          surfaceColor: c.surface,
          textColor: c.text,
          textSecondaryColor: c.textSecondary,
          accentColor: c.accent,
          onTap: () => _speak(contact.name),
          onCall: contact.phone.isNotEmpty
              ? () => _callNumber(contact.phone)
              : null,
          onEdit: () => _showContactEditor(existing: contact),
        );
      },
    );
  }
}

// ─── Widgets ───────────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  final EmergencyContact contact;
  final Color cardColor;
  final Color surfaceColor;
  final Color textColor;
  final Color textSecondaryColor;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback? onCall;
  final VoidCallback onEdit;

  const _ContactTile({
    required this.contact,
    required this.cardColor,
    required this.surfaceColor,
    required this.textColor,
    required this.textSecondaryColor,
    required this.accentColor,
    required this.onTap,
    required this.onCall,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onCall,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  const Icon(Icons.person, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (contact.phone.isNotEmpty)
                    Text(
                      contact.phone,
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondaryColor,
                      ),
                    ),
                ],
              ),
            ),
            if (onCall != null)
              GestureDetector(
                onTap: onCall,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.phone,
                    color: Colors.green.shade600,
                    size: 24,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.edit, color: textSecondaryColor, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SosOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SosOptionTile({
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
