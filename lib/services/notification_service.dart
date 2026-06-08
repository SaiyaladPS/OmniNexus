import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  FlutterLocalNotificationsPlugin? _plugin;
  bool _initialized = false;

  static const _healthChannelId = 'health_reminders';
  static const _weatherChannelId = 'weather_alerts';
  static const _medicineChannelId = 'medicine_reminders';
  static const _healthChannelName = 'Health Reminders';
  static const _weatherChannelName = 'Weather Alerts';
  static const _medicineChannelName = 'Medicine Reminders';
  static const _healthChannelDesc = 'Drink water & quiz reminders';
  static const _weatherChannelDesc = 'Rain & severe weather alerts';
  static const _medicineChannelDesc = 'Medication reminders';

  static const _drinkWaterId = 1001;
  static const _quizReminderId = 1002;
  static const _rainAlertId = 2001;
  static const _priceAlertId = 3001;

  Future<void> init() async {
    if (_initialized) return;
    try {
      _plugin = FlutterLocalNotificationsPlugin();

      const androidSettings = AndroidInitializationSettings('notification_icon');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      await _createChannels();
      _initialized = true;
    } catch (e) {
      debugPrint('[NotificationService] init failed (plugin not available on this platform): $e');
      _plugin = null;
    }
  }

  Future<void> _createChannels() async {
    final android = _plugin!
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _healthChannelId,
        _healthChannelName,
        description: _healthChannelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _weatherChannelId,
        _weatherChannelName,
        description: _weatherChannelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _medicineChannelId,
        _medicineChannelName,
        description: _medicineChannelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  Future<bool> requestPermission() async {
    if (_plugin == null) return false;

    final android = _plugin!
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _plugin!
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  AndroidNotificationDetails _androidDetails(String channelId) {
    return AndroidNotificationDetails(
      channelId,
      channelId == _healthChannelId ? _healthChannelName : _weatherChannelName,
      channelDescription: channelId == _healthChannelId
          ? _healthChannelDesc
          : _weatherChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: 'notification_icon',
    );
  }

  DarwinNotificationDetails _iosDetails() {
    return const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
  }

  NotificationDetails _details(String channelId) {
    return NotificationDetails(
      android: _androidDetails(channelId),
      iOS: _iosDetails(),
    );
  }

  Future<void> showDrinkWaterReminder() async {
    if (_plugin == null) return;
    await _plugin!.show(
      _drinkWaterId,
      '💧 ເຖິງເວລາດື່ມນ້ຳແລ້ວ!',
      'ຢ່າລືມດື່ມນ້ຳເພື່ອສຸຂະພາບທີ່ດີ  — ດື່ມນ້ຳຢ່າງໜ້ອຍ 8 ຈອກຕໍ່ວັນ',
      _details(_healthChannelId),
    );
  }

  Future<void> scheduleDrinkWaterReminder() async {
    if (_plugin == null) return;
    await _plugin!.periodicallyShow(
      _drinkWaterId,
      '💧 ເຖິງເວລາດື່ມນ້ຳແລ້ວ!',
      'ຢ່າລືມດື່ມນ້ຳເພື່ອສຸຂະພາບທີ່ດີ — ດື່ມນ້ຳຢ່າງໜ້ອຍ 8 ຈອກຕໍ່ວັນ',
      RepeatInterval.hourly,
      _details(_healthChannelId),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelDrinkWaterReminder() async {
    if (_plugin == null) return;
    await _plugin!.cancel(_drinkWaterId);
  }

  Future<void> showRainAlert() async {
    if (_plugin == null) return;
    await _plugin!.show(
      _rainAlertId,
      '🌧 ຝົນຕົກໃນພື້ນທີ່ຂອງທ່ານ!',
      'ກະລຸນາກຽມຮົ່ມ ແລະ ລະວັງຜົນກະທົບຈາກສະພາບອາກາດ',
      _details(_weatherChannelId),
    );
  }

  Future<void> showQuizReminder() async {
    if (_plugin == null) return;
    await _plugin!.show(
      _quizReminderId,
      '🧠 ກວດສຸຂະພາບຈິດປະຈຳວັນ',
      'ລອງເຮັດແບບປະເມີນສຸຂະພາບຈິດເບິ່ງ  — ໃຊ້ເວລາພຽງ 5 ນາທີເທົ່ານັ້ນ',
      _details(_healthChannelId),
    );
  }

  Future<void> showPriceAlert(String symbol, double price, double target) async {
    if (_plugin == null) return;
    await _plugin!.show(
      _priceAlertId + symbol.hashCode,
      '💰 Price Alert: $symbol',
      '$symbol hit \$${price.toStringAsFixed(2)} (target: \$${target.toStringAsFixed(2)})',
      _details(_weatherChannelId),
    );
  }

  Future<void> showMedicineReminder(String name, String dosage) async {
    if (_plugin == null) return;
    await _plugin!.show(
      _medicineChannelId.hashCode + name.hashCode,
      '💊 Medicine Reminder: $name',
      dosage.isNotEmpty ? 'Time to take $name ($dosage)' : 'Time to take $name',
      _details(_medicineChannelId),
    );
  }
}

final notificationService = NotificationService();
