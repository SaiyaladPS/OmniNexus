import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

class Medicine {
  final String id;
  final String name;
  final String dosage;
  final int hour;
  final int minute;
  final bool enabled;
  final List<int> daysOfWeek;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.hour,
    required this.minute,
    this.enabled = true,
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
  });

  Medicine copyWith({
    String? name,
    String? dosage,
    int? hour,
    int? minute,
    bool? enabled,
    List<int>? daysOfWeek,
  }) {
    return Medicine(
      id: id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'dosage': dosage,
    'hour': hour, 'minute': minute,
    'enabled': enabled, 'days': daysOfWeek,
  };

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    dosage: json['dosage'] as String? ?? '',
    hour: json['hour'] as int? ?? 0,
    minute: json['minute'] as int? ?? 0,
    enabled: json['enabled'] as bool? ?? true,
    daysOfWeek: (json['days'] as List?)?.cast<int>() ?? [1,2,3,4,5,6,7],
  );

  String get timeFormatted {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get daysFormatted {
    if (daysOfWeek.length >= 7) return 'Every day';
    const labels = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return daysOfWeek.map((d) => labels[d]).join(', ');
  }

  bool isDueToday() {
    final today = DateTime.now().weekday;
    return daysOfWeek.contains(today);
  }
}

class MedicineService extends ChangeNotifier {
  static const _boxName = 'medicine_reminders';
  Box<String>? _box;
  bool _ready = false;
  List<Medicine> _medicines = [];

  bool get ready => _ready;
  List<Medicine> get medicines => _medicines;

  Future<void> init() async {
    try {
      _box = await Hive.openBox<String>(_boxName);
      _load();
      _ready = true;
    } catch (_) {}
  }

  void _load() {
    final raw = _box?.get('list');
    if (raw == null) { _medicines = []; return; }
    final list = json.decode(raw) as List;
    _medicines = list.map((e) => Medicine.fromJson(e as Map<String, dynamic>)).toList();
    notifyListeners();
  }

  void _save() {
    final raw = json.encode(_medicines.map((m) => m.toJson()).toList());
    _box?.put('list', raw);
    notifyListeners();
  }

  void add(Medicine medicine) {
    _medicines.add(medicine);
    _save();
  }

  void update(Medicine medicine) {
    final i = _medicines.indexWhere((m) => m.id == medicine.id);
    if (i >= 0) {
      _medicines[i] = medicine;
      _save();
    }
  }

  void remove(String id) {
    _medicines.removeWhere((m) => m.id == id);
    _save();
  }

  void toggle(String id) {
    final i = _medicines.indexWhere((m) => m.id == id);
    if (i >= 0) {
      _medicines[i] = _medicines[i].copyWith(enabled: !_medicines[i].enabled);
      _save();
    }
  }

  List<Medicine> getDueNow() {
    final now = DateTime.now();
    return _medicines.where((m) =>
      m.enabled &&
      m.hour == now.hour &&
      m.minute == now.minute &&
      m.isDueToday()
    ).toList();
  }
}

class IceContact {
  final String id;
  final String name;
  final String phone;
  final String relationship;

  const IceContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'phone': phone, 'relationship': relationship,
  };

  factory IceContact.fromJson(Map<String, dynamic> json) => IceContact(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    relationship: json['relationship']?.toString() ?? '',
  );
}

class MedicalId {
  final String? bloodType;
  final String? allergies;
  final String? conditions;
  final String? notes;

  const MedicalId({this.bloodType, this.allergies, this.conditions, this.notes});

  Map<String, dynamic> toJson() => {
    'bloodType': bloodType, 'allergies': allergies,
    'conditions': conditions, 'notes': notes,
  };

  factory MedicalId.fromJson(Map<String, dynamic> json) => MedicalId(
    bloodType: json['bloodType']?.toString(),
    allergies: json['allergies']?.toString(),
    conditions: json['conditions']?.toString(),
    notes: json['notes']?.toString(),
  );
}

class IceService extends ChangeNotifier {
  static const _boxName = 'ice_data';
  Box<String>? _box;
  bool _ready = false;
  List<IceContact> _contacts = [];
  MedicalId _medicalId = const MedicalId();

  bool get ready => _ready;
  List<IceContact> get contacts => _contacts;
  MedicalId get medicalId => _medicalId;

  Future<void> init() async {
    try {
      _box = await Hive.openBox<String>(_boxName);
      _load();
      _ready = true;
    } catch (_) {}
  }

  void _load() {
    final cRaw = _box?.get('contacts');
    if (cRaw != null) {
      final list = json.decode(cRaw) as List;
      _contacts = list.map((e) => IceContact.fromJson(e as Map<String, dynamic>)).toList();
    }
    final mRaw = _box?.get('medical');
    if (mRaw != null) {
      _medicalId = MedicalId.fromJson(json.decode(mRaw) as Map<String, dynamic>);
    }
    notifyListeners();
  }

  void _saveContacts() {
    _box?.put('contacts', json.encode(_contacts.map((c) => c.toJson()).toList()));
    notifyListeners();
  }

  void _saveMedical() {
    _box?.put('medical', json.encode(_medicalId.toJson()));
    notifyListeners();
  }

  void addContact(IceContact contact) {
    _contacts.add(contact);
    _saveContacts();
  }

  void removeContact(String id) {
    _contacts.removeWhere((c) => c.id == id);
    _saveContacts();
  }

  void updateMedicalId(MedicalId id) {
    _medicalId = id;
    _saveMedical();
  }
}

final iceService = IceService();
final medicineService = MedicineService();
