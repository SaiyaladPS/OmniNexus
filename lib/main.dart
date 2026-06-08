import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';
import 'pages/dashboard_page.dart';
import 'services/notification_service.dart';
import 'services/voice_service.dart';
import 'services/favorite_service.dart';
import 'services/currency_history_service.dart';
import 'services/portfolio_service.dart';
import 'services/event_service.dart';
import 'services/medicine_service.dart';
import 'services/green_points_service.dart';
import 'services/aqi_history_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Hive.initFlutter();
    await favoriteService.init();
    await currencyHistoryService.init();
    await portfolioStorage.init();
    await priceAlertService.init();
    await eventService.init();
    await medicineService.init();
    await iceService.init();
    await greenPointsService.init();
    await aqiHistoryService.init();
  } on MissingPluginException {
    // Native path_provider not registered — local storage will be unavailable
  }
  await notificationService.init();
  await voiceService.init();
  runApp(const OmniNexusApp());
}

class OmniNexusApp extends StatefulWidget {
  const OmniNexusApp({super.key});

  @override
  State<OmniNexusApp> createState() => _OmniNexusAppState();
}

class _OmniNexusAppState extends State<OmniNexusApp> {
  final _themeProvider = AdaptiveThemeProvider();

  @override
  void initState() {
    super.initState();
    _themeProvider.init().then((_) => _themeProvider.setFromWeather(null));
  }

  @override
  void dispose() {
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProviderScope(
      notifier: _themeProvider,
      child: ListenableBuilder(
        listenable: _themeProvider,
        builder: (context, _) {
          final tp = _themeProvider;
          return MaterialApp(
            title: 'OmniNexus',
            debugShowCheckedModeBanner: false,
            theme: tp.colors.themeData,
            home: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(tp.textScale),
                accessibleNavigation: false,
                disableAnimations: tp.reduceMotion,
              ),
              child: const DashboardPage(),
            ),
          );
        },
      ),
    );
  }
}
