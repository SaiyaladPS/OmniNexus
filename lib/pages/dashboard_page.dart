import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_background.dart';
import '../services/notification_service.dart';
import '../services/voice_service.dart';
import 'apod_page.dart';
import 'iss_page.dart';
import 'weather_page.dart';
import 'health_mind_page.dart';
import 'recipe_page.dart';
import 'country_page.dart';
import 'currency_page.dart';
import 'earthquake_page.dart';
import 'portfolio_page.dart';
import 'worldtime_page.dart';
import 'smart_lens_page.dart';
import 'global_dashboard_page.dart';
import 'emergency_page.dart';
import 'recycle_page.dart';
import 'air_quality_page.dart';
import 'disease_tracker_page.dart';
import 'accessibility_helper_page.dart';
import 'safe_way_page.dart';
import 'magnifier_page.dart';
import 'emergency_hub_page.dart';

class _Menu {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget page;
  const _Menu({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
  });
}

class _Group {
  final String label;
  final IconData icon;
  final List<_Menu> items;
  const _Group({required this.label, required this.icon, required this.items});
}

const _groups = <_Group>[
  _Group(
    label: 'ອະວະກາດ ແລະ ຂໍ້ມູນໂລກ',
    icon: Icons.rocket_launch,
    items: [
      _Menu(
        title: 'ຮູບດາວເຄາະ',
        subtitle: 'NASA APOD',
        icon: Icons.rocket_launch,
        page: ApodPage(),
      ),
      _Menu(
        title: 'ຕິດຕາມ ISS',
        subtitle: 'ສະຖານີອາວະກາດ',
        icon: Icons.satellite_alt,
        page: IssPage(),
      ),
      _Menu(
        title: 'Global Dashboard',
        subtitle: 'ສະຖິຕິໂລກ',
        icon: Icons.dashboard,
        page: GlobalDashboardPage(),
      ),
    ],
  ),
  _Group(
    label: 'ສະພາບອາກາດ ແລະ ສິ່ງແວດລ້ອມ',
    icon: Icons.thunderstorm,
    items: [
      _Menu(
        title: 'ພະຍາກອນອາກາດ',
        subtitle: '7 ວັນ',
        icon: Icons.thunderstorm,
        page: WeatherPage(),
      ),
      _Menu(
        title: 'ຄຸນນະພາບອາກາດ',
        subtitle: 'AQI',
        icon: Icons.air,
        page: AirQualityPage(),
      ),
      _Menu(
        title: 'ແຜ່ນດິນໄຫວ',
        subtitle: 'USGS',
        icon: Icons.landslide,
        page: EarthquakePage(),
      ),
    ],
  ),
  _Group(
    label: 'ສຸຂະພາບ ແລະ ຄວາມປອດໄພ',
    icon: Icons.favorite,
    items: [
      _Menu(
        title: 'ສຸຂະພາບຈິດ',
        subtitle: 'BMI/BMR',
        icon: Icons.favorite,
        page: HealthMindPage(),
      ),
      _Menu(
        title: 'ເຫດສຸກເສີນ',
        subtitle: 'ປະຖົມພະຍາບານ',
        icon: Icons.warning_amber,
        page: EmergencyPage(),
      ),
      _Menu(
        title: 'ໂຣກລະບາດ',
        subtitle: 'Disease Tracker',
        icon: Icons.vaccines,
        page: DiseaseTrackerPage(),
      ),
      _Menu(
        title: 'ການເຂົ້າເຖິງ',
        subtitle: 'Accessibility',
        icon: Icons.accessibility_new,
        page: AccessibilityHelperPage(),
      ),
    ],
  ),
  _Group(
    label: 'ອາຫານ ແລະ ຊີວິດ',
    icon: Icons.menu_book,
    items: [
      _Menu(
        title: 'ສູດອາຫານ',
        subtitle: 'Edamam',
        icon: Icons.menu_book,
        page: RecipePage(),
      ),
      _Menu(
        title: 'ສະແກນດ້ວຍ AI',
        subtitle: 'Smart Lens',
        icon: Icons.document_scanner,
        page: SmartLensPage(),
      ),
      _Menu(
        title: 'ຄັດແຍກຂີ້ເຫຍື້ອ',
        subtitle: 'Recycle',
        icon: Icons.recycling,
        page: RecyclePage(),
      ),
    ],
  ),
  _Group(
    label: 'ເງິນ ແລະ ການເງິນ',
    icon: Icons.currency_exchange,
    items: [
      _Menu(
        title: 'ຂໍ້ມູນປະເທດ',
        subtitle: 'REST Countries',
        icon: Icons.public,
        page: CountryPage(),
      ),
      _Menu(
        title: 'ເວລາໂລກ',
        subtitle: 'World Clock',
        icon: Icons.schedule,
        page: WorldTimePage(),
      ),
      _Menu(
        title: 'ແປງສະກຸນເງິນ',
        subtitle: 'Currency',
        icon: Icons.currency_exchange,
        page: CurrencyPage(),
      ),
      _Menu(
        title: 'ຫຸ້ນ ແລະ ສະກຸນເງິນດິຈິຕອນ',
        subtitle: 'Portfolio',
        icon: Icons.trending_up,
        page: PortfolioPage(),
      ),
    ],
  ),
  _Group(
    label: 'ການເຂົ້າເຖິງ ແລະ ຄວາມປອດໄພ',
    icon: Icons.accessibility_new,
    items: [
      _Menu(
        title: 'SafeWay ນຳທາງ',
        subtitle: 'GPS Audio',
        icon: Icons.navigation,
        page: SafeWayPage(),
      ),
      _Menu(
        title: 'Super Magnifier',
        subtitle: 'ແວ່ນຂະຫຍາຍ',
        icon: Icons.zoom_in,
        page: MagnifierPage(),
      ),
      _Menu(
        title: 'Emergency Hub',
        subtitle: 'SOS ສຸກເສີນ',
        icon: Icons.sos,
        page: EmergencyHubPage(),
      ),
    ],
  ),
];

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProviderScope.of(context);
    final c = theme.colors;
    return AnimatedBackground(
      mode: theme.mode,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(theme, c),
              _buildSubHeader(theme, c, context),
              for (final g in _groups) ...[
                _buildSectionHeader(g, c),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final item = g.items[i];
                    return RepaintBoundary(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: i == g.items.length - 1 ? 4 : 6,
                        ),
                        child: _MenuItem(data: item, colors: c),
                      ),
                    );
                  }, childCount: g.items.length),
                ),
              ],
              SliverToBoxAdapter(child: _NotificationSettings(themeColors: c)),
              SliverToBoxAdapter(child: _VoiceControls(themeColors: c)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi, size: 13, color: Colors.white38),
                      SizedBox(width: 6),
                      Text(
                        'Live data via REST APIs',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white38,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AdaptiveThemeProvider theme, AppThemeColors c) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
        child: Row(
          children: [
            Icon(Icons.flutter_dash, color: c.text, size: 28),
            const SizedBox(width: 10),
            Text(
              'OmniNexus',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: c.text,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            _ThemeIndicator(mode: theme.mode),
          ],
        ),
      ),
    );
  }

  Widget _buildSubHeader(
    AdaptiveThemeProvider theme,
    AppThemeColors c,
    BuildContext context,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Row(
          children: [
            Text(
              'Space, satellite & weather data',
              style: TextStyle(
                fontSize: 14,
                color: c.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _showThemePicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  theme.mode.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: c.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(_Group g, AppThemeColors c) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
        child: Row(
          children: [
            Icon(g.icon, size: 16, color: c.accent),
            const SizedBox(width: 8),
            Text(
              g.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.accent,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    final theme = ThemeProviderScope.of(context);
    final c = theme.colors;
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
                'Select Theme',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: c.text,
                ),
              ),
              const SizedBox(height: 16),
              ...AppThemeMode.values.map((mode) {
                final colors = resolveTheme(mode);
                final isActive = theme.mode == mode;
                return GestureDetector(
                  onTap: () {
                    theme.setManual(mode);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isActive
                          ? colors.accent.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? colors.accent
                            : colors.textSecondary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: colors.gradientColors,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          mode.label,
                          style: TextStyle(
                            fontSize: 15,
                            color: isActive ? colors.accent : colors.text,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        const Spacer(),
                        if (isActive)
                          Icon(
                            Icons.check_circle,
                            color: colors.accent,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeIndicator extends StatelessWidget {
  final AppThemeMode mode;
  const _ThemeIndicator({required this.mode});

  @override
  Widget build(BuildContext context) {
    final provider = ThemeProviderScope.of(context);
    if (provider.highContrastMode) {
      return Icon(Icons.contrast, size: 22, color: provider.colors.accent);
    }
    final icon = switch (mode) {
      AppThemeMode.sunny => Icons.wb_sunny,
      AppThemeMode.cloudy => Icons.cloud,
      AppThemeMode.rainy => Icons.water_drop,
      AppThemeMode.night => Icons.nightlight_round,
    };
    return Icon(icon, size: 22, color: resolveTheme(mode).accent);
  }
}

class _MenuItem extends StatelessWidget {
  final _Menu data;
  final AppThemeColors colors;
  const _MenuItem({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Semantics(
      button: true,
      label: data.title,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => data.page),
        ),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14),
                  ),
                ),
                child: Icon(data.icon, color: c.accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      style: TextStyle(fontSize: 11, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: c.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationSettings extends StatelessWidget {
  final AppThemeColors themeColors;
  const _NotificationSettings({required this.themeColors});

  @override
  Widget build(BuildContext context) {
    final c = themeColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.accent.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_outlined, color: c.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ແຈ້ງເຕືອນດື່ມນ້ຳ',
                    style: TextStyle(
                      fontSize: 13,
                      color: c.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'ແຈ້ງເຕືອນທຸກໆ 1 ຊົ່ວໂມງ',
                    style: TextStyle(fontSize: 11, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            _WaterSwitch(c: c),
          ],
        ),
      ),
    );
  }
}

class _WaterSwitch extends StatefulWidget {
  final AppThemeColors c;
  const _WaterSwitch({required this.c});

  @override
  State<_WaterSwitch> createState() => _WaterSwitchState();
}

class _WaterSwitchState extends State<_WaterSwitch> {
  bool _enabled = false;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: _enabled,
      activeThumbColor: widget.c.accent,
      onChanged: (v) async {
        if (v) {
          final granted = await notificationService.requestPermission();
          if (!mounted) return;
          if (!granted) return;
        }
        setState(() => _enabled = v);
        if (v) {
          await notificationService.scheduleDrinkWaterReminder();
        } else {
          await notificationService.cancelDrinkWaterReminder();
        }
      },
    );
  }
}

class _VoiceControls extends StatefulWidget {
  final AppThemeColors themeColors;
  const _VoiceControls({required this.themeColors});

  @override
  State<_VoiceControls> createState() => _VoiceControlsState();
}

class _VoiceControlsState extends State<_VoiceControls> {
  @override
  void initState() {
    super.initState();
    voiceService.addListener(_onVoiceChanged);
  }

  @override
  void dispose() {
    voiceService.removeListener(_onVoiceChanged);
    super.dispose();
  }

  void _onVoiceChanged() {
    if (mounted) setState(() {});
  }

  void _handleCommand(VoiceCommand cmd) {
    if (!mounted) return;
    String label;
    Widget page;
    switch (cmd) {
      case VoiceCommand.apod:
        label = 'APOD';
        page = const ApodPage();
      case VoiceCommand.iss:
        label = 'ISS Tracker';
        page = const IssPage();
      case VoiceCommand.dashboard:
        label = 'Global Dashboard';
        page = const GlobalDashboardPage();
      case VoiceCommand.weather:
        label = 'Weather';
        page = const WeatherPage();
      case VoiceCommand.health:
        label = 'Health & Mind';
        page = const HealthMindPage();
      case VoiceCommand.emergency:
        label = 'Emergency & First Aid';
        page = const EmergencyPage();
      case VoiceCommand.recipe:
        label = 'Recipe Finder';
        page = const RecipePage();
      case VoiceCommand.smartlens:
        label = 'Smart Lens';
        page = const SmartLensPage();
      case VoiceCommand.country:
        label = 'Country Insight';
        page = const CountryPage();
      case VoiceCommand.worldtime:
        label = 'World Time & Events';
        page = const WorldTimePage();
      case VoiceCommand.currency:
        label = 'Currency Converter';
        page = const CurrencyPage();
      case VoiceCommand.earthquake:
        label = 'Earthquake Alerts';
        page = const EarthquakePage();
      case VoiceCommand.portfolio:
        label = 'Stock & Crypto Portfolio';
        page = const PortfolioPage();
      case VoiceCommand.recycle:
        label = 'Recycle Helper';
        page = const RecyclePage();
      case VoiceCommand.airquality:
        label = 'Air Quality';
        page = const AirQualityPage();
      case VoiceCommand.disease:
        label = 'Disease Tracker';
        page = const DiseaseTrackerPage();
      case VoiceCommand.accessibility:
        label = 'Accessibility Helper';
        page = const AccessibilityHelperPage();
      case VoiceCommand.safeway:
        label = 'SafeWay Navigator';
        page = const SafeWayPage();
      case VoiceCommand.magnifier:
        label = 'Super Magnifier';
        page = const MagnifierPage();
      case VoiceCommand.emergencyhub:
        label = 'Emergency Hub';
        page = const EmergencyHubPage();
      case VoiceCommand.stop:
      case VoiceCommand.unknown:
        return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $label'),
        duration: const Duration(seconds: 1),
      ),
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.themeColors;
    final isListening = voiceService.isListening;
    final isSpeaking = voiceService.isSpeaking;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.accent.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(
              isListening ? Icons.mic : Icons.mic_none,
              color: isListening ? Colors.redAccent : c.accent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isListening
                        ? 'Listening...'
                        : isSpeaking
                        ? 'Speaking...'
                        : 'Voice Commands',
                    style: TextStyle(
                      fontSize: 13,
                      color: c.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isListening
                        ? (voiceService.lastRecognized.isNotEmpty
                              ? '"${voiceService.lastRecognized}"'
                              : 'Say "Go to Space", "Weather", etc.')
                        : isSpeaking
                        ? 'Playing briefing...'
                        : 'Try "Go to Space" or "Health"',
                    style: TextStyle(fontSize: 11, color: c.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isListening || isSpeaking)
              IconButton(
                icon: const Icon(Icons.stop_circle, size: 22),
                color: Colors.redAccent,
                onPressed: () async {
                  await voiceService.stopListening();
                  await voiceService.stopSpeaking();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 18,
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.play_arrow, size: 22),
                color: c.accent,
                onPressed: _startBriefing,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 18,
                tooltip: 'Listen to briefing',
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.mic, size: 22),
                color: c.accent,
                onPressed: _startListening,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 18,
                tooltip: 'Voice navigation',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startBriefing() async {
    if (!voiceService.ttsAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Text-to-Speech not available. Install native pods first (cd ios && pod install)',
            ),
          ),
        );
      }
      return;
    }
    await voiceService.speak(await voiceService.buildBriefing());
  }

  Future<void> _startListening() async {
    if (!voiceService.sttAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Speech recognition not available. Install native pods first (cd ios && pod install)',
            ),
          ),
        );
      }
      return;
    }
    final started = await voiceService.startListening(
      onCommand: _handleCommand,
    );
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition failed to start')),
      );
    }
  }
}
