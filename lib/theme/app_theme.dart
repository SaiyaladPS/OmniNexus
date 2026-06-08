import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ─── Theme Modes ──────────────────────────────────────────────────────────

enum AppThemeMode {
  sunny,
  cloudy,
  rainy,
  night,
}

extension AppThemeModeX on AppThemeMode {
  String get label {
    switch (this) {
      case AppThemeMode.sunny: return '☀️ Sunny';
      case AppThemeMode.cloudy: return '☁️ Cloudy';
      case AppThemeMode.rainy: return '🌧️ Rainy';
      case AppThemeMode.night: return '🌙 Night';
    }
  }
}

// ─── Color Scheme ─────────────────────────────────────────────────────────

class AppThemeColors {
  final Color bg;
  final Color surface;
  final Color card;
  final Color text;
  final Color textSecondary;
  final Color accent;
  final Color accentSecondary;
  final Color accentTertiary;
  final Color appBar;
  final Color navIconActive;
  final Color navIconInactive;
  final List<Color> gradientColors;
  final Brightness brightness;

  const AppThemeColors({
    required this.bg,
    required this.surface,
    required this.card,
    required this.text,
    required this.textSecondary,
    required this.accent,
    required this.accentSecondary,
    required this.accentTertiary,
    required this.appBar,
    required this.navIconActive,
    required this.navIconInactive,
    required this.gradientColors,
    required this.brightness,
  });

  ThemeData get themeData => ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      surface: bg,
    ),
    scaffoldBackgroundColor: bg,
    appBarTheme: AppBarTheme(
      backgroundColor: appBar,
      foregroundColor: text,
      elevation: 0,
    ),
    cardColor: card,
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: text),
      bodyMedium: TextStyle(color: text),
      titleLarge: TextStyle(color: text),
    ),
  );
}

// ─── Theme Definitions ────────────────────────────────────────────────────

const sunnyTheme = AppThemeColors(
  bg: Color(0xFFFEFCF8),
  surface: Color(0xFFF8F6FC),
  card: Colors.white,
  text: Color(0xFF3D3555),
  textSecondary: Color(0xFFA098B8),
  accent: Color(0xFF9B6FBF),
  accentSecondary: Color(0xFF5BA89A),
  accentTertiary: Color(0xFFE8927A),
  appBar: Color(0xFFFEFCF8),
  navIconActive: Color(0xFF9B6FBF),
  navIconInactive: Color(0xFFC8C0D8),
  gradientColors: [
    Color(0xFFFEFCF8),
    Color(0xFFF8F0FF),
    Color(0xFFF0F8F6),
  ],
  brightness: Brightness.light,
);

const cloudyTheme = AppThemeColors(
  bg: Color(0xFFF0F2F5),
  surface: Color(0xFFE8ECF0),
  card: Color(0xFFFAFBFD),
  text: Color(0xFF2D3748),
  textSecondary: Color(0xFF8A9BB0),
  accent: Color(0xFF6B8FA3),
  accentSecondary: Color(0xFF88AAB5),
  accentTertiary: Color(0xFFA0B8C8),
  appBar: Color(0xFFF0F2F5),
  navIconActive: Color(0xFF6B8FA3),
  navIconInactive: Color(0xFFB0C0D0),
  gradientColors: [
    Color(0xFFF0F2F5),
    Color(0xFFE0E8F0),
    Color(0xFFD8E0E8),
  ],
  brightness: Brightness.light,
);

const rainyTheme = AppThemeColors(
  bg: Color(0xFF1A1E2E),
  surface: Color(0xFF232840),
  card: Color(0xFF2A3050),
  text: Color(0xFFE0E6F0),
  textSecondary: Color(0xFF98A8C0),
  accent: Color(0xFF5B8FBF),
  accentSecondary: Color(0xFF4A7BA8),
  accentTertiary: Color(0xFF6BA0D0),
  appBar: Color(0xFF1A1E2E),
  navIconActive: Color(0xFF7BB8E0),
  navIconInactive: Color(0xFF4A5A78),
  gradientColors: [
    Color(0xFF1A1E2E),
    Color(0xFF1E2840),
    Color(0xFF223050),
  ],
  brightness: Brightness.dark,
);

const nightTheme = AppThemeColors(
  bg: Color(0xFF0D0A1A),
  surface: Color(0xFF151030),
  card: Color(0xFF1D1840),
  text: Color(0xFFD8D0E8),
  textSecondary: Color(0xFF8878A8),
  accent: Color(0xFF7B5FB0),
  accentSecondary: Color(0xFF6B4FA0),
  accentTertiary: Color(0xFF8B70C0),
  appBar: Color(0xFF0D0A1A),
  navIconActive: Color(0xFF9B7FD0),
  navIconInactive: Color(0xFF3A3060),
  gradientColors: [
    Color(0xFF0D0A1A),
    Color(0xFF100828),
    Color(0xFF140D30),
  ],
  brightness: Brightness.dark,
);

const highContrastTheme = AppThemeColors(
  bg: Color(0xFF000000),
  surface: Color(0xFF111111),
  card: Color(0xFF000000),
  text: Color(0xFFFFFFFF),
  textSecondary: Color(0xFFE6E6E6),
  accent: Color(0xFFFFFF00),
  accentSecondary: Color(0xFF00FFFF),
  accentTertiary: Color(0xFFFF66FF),
  appBar: Color(0xFF000000),
  navIconActive: Color(0xFFFFFF00),
  navIconInactive: Color(0xFFFFFFFF),
  gradientColors: [
    Color(0xFF000000),
    Color(0xFF1A1A1A),
    Color(0xFF333333),
  ],
  brightness: Brightness.dark,
);

// ─── Resolver ──────────────────────────────────────────────────────────────

AppThemeColors resolveTheme(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.sunny: return sunnyTheme;
    case AppThemeMode.cloudy: return cloudyTheme;
    case AppThemeMode.rainy: return rainyTheme;
    case AppThemeMode.night: return nightTheme;
  }
}

AppThemeMode themeFromWeatherCode(int wmoCode) {
  if (wmoCode == 0) return AppThemeMode.sunny;
  if (wmoCode <= 3) return AppThemeMode.cloudy;
  if (wmoCode == 45 || wmoCode == 48) return AppThemeMode.cloudy;
  if (wmoCode <= 57) return AppThemeMode.rainy;
  if (wmoCode <= 67) return AppThemeMode.rainy;
  if (wmoCode <= 77) return AppThemeMode.rainy;
  if (wmoCode <= 82) return AppThemeMode.rainy;
  if (wmoCode <= 86) return AppThemeMode.rainy;
  return AppThemeMode.rainy;
}

AppThemeMode themeFromTimeOfDay(DateTime now) {
  final hour = now.hour;
  if (hour >= 6 && hour < 18) return AppThemeMode.sunny;
  return AppThemeMode.night;
}

// ─── Provider ──────────────────────────────────────────────────────────────

class AdaptiveThemeProvider extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.sunny;
  bool _highContrastMode = false;
  bool _visualAlertsEnabled = true;
  double _textScale = 1.0;
  bool _reduceMotion = false;

  AppThemeColors get colors =>
      _highContrastMode ? highContrastTheme : resolveTheme(_mode);
  AppThemeMode get mode => _mode;
  bool get highContrastMode => _highContrastMode;
  bool get visualAlertsEnabled => _visualAlertsEnabled;
  double get textScale => _textScale;
  bool get reduceMotion => _reduceMotion;

  Future<void> init() async {
    try {
      final box = await Hive.openBox<String>('accessibility');
      _highContrastMode = box.get('highContrast', defaultValue: 'false') == 'true';
      _visualAlertsEnabled = box.get('visualAlerts', defaultValue: 'true') == 'true';
      _textScale = double.tryParse(box.get('textScale', defaultValue: '1.0') ?? '1.0') ?? 1.0;
      _reduceMotion = box.get('reduceMotion', defaultValue: 'false') == 'true';
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final box = await Hive.openBox<String>('accessibility');
      await box.put('highContrast', _highContrastMode.toString());
      await box.put('visualAlerts', _visualAlertsEnabled.toString());
      await box.put('textScale', _textScale.toString());
      await box.put('reduceMotion', _reduceMotion.toString());
    } catch (_) {}
  }

  void setFromWeather(int? wmoCode, {DateTime? now}) {
    final nowVal = now ?? DateTime.now();
    final isNight = nowVal.hour < 6 || nowVal.hour >= 18;

    AppThemeMode newMode;
    if (wmoCode != null) {
      newMode = themeFromWeatherCode(wmoCode);
      if (newMode == AppThemeMode.sunny && isNight) {
        newMode = AppThemeMode.night;
      }
    } else {
      newMode = isNight ? AppThemeMode.night : AppThemeMode.sunny;
    }
    _mode = newMode;
    notifyListeners();
  }

  void setManual(AppThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void setHighContrast(bool value) {
    _highContrastMode = value;
    notifyListeners();
    _save();
  }

  void setVisualAlerts(bool value) {
    _visualAlertsEnabled = value;
    notifyListeners();
    _save();
  }

  void setTextScale(double value) {
    _textScale = value;
    notifyListeners();
    _save();
  }

  void setReduceMotion(bool value) {
    _reduceMotion = value;
    notifyListeners();
    _save();
  }
}

// ─── InheritedWidget ───────────────────────────────────────────────────────

class ThemeProviderScope extends InheritedNotifier<AdaptiveThemeProvider> {
  const ThemeProviderScope({
    super.key,
    required AdaptiveThemeProvider notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AdaptiveThemeProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeProviderScope>();
    assert(scope != null, 'No ThemeProviderScope found in context');
    return scope!.notifier!;
  }
}
