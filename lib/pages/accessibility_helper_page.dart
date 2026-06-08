import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class AccessibilityHelperPage extends StatefulWidget {
  const AccessibilityHelperPage({super.key});

  @override
  State<AccessibilityHelperPage> createState() =>
      _AccessibilityHelperPageState();
}

class _AccessibilityHelperPageState extends State<AccessibilityHelperPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flashController;
  late final Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _flashAnimation = CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  Future<void> _testVisualAlert() async {
    final theme = ThemeProviderScope.of(context);
    if (theme.visualAlertsEnabled) {
      await HapticFeedback.heavyImpact();
    }
    await _flashController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProviderScope.of(context);
    final c = theme.colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('ຕົວຊ່ວຍເຂົ້າເຖິງ'),
        backgroundColor: c.card,
        foregroundColor: c.text,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _hero(c),
              const SizedBox(height: 14),
              _settingsCard(context, theme, c),
              const SizedBox(height: 14),
              _textScaleCard(c, theme),
              const SizedBox(height: 14),
              _screenReaderCard(c),
              const SizedBox(height: 14),
              _visualAlertCard(context, theme, c),
              const SizedBox(height: 14),
              _inclusiveReportCard(c),
            ],
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _flashAnimation,
              builder: (context, child) {
                final opacity = (1 - _flashAnimation.value) * 0.55;
                return opacity <= 0
                    ? const SizedBox.shrink()
                    : Container(color: c.accent.withValues(alpha: opacity));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(AppThemeColors c) {
    return Semantics(
      header: true,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.accent.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.accessibility_new, color: c.accent, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ສູນການອອກແບບທີ່ທຸກຄົນເຂົ້າເຖິງໄດ້',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'ເຄື່ອງມືສຳລັບວິໄສທັດທີ່ຊັດເຈນຂຶ້ນ, ການໄຫຼຂອງໂປຣແກຣມອ່ານໜ້າຈໍທີ່ດີຂຶ້ນ, ແລະ ການແຈ້ງເຕືອນທີ່ສຳຄັນແບບບໍ່ມີສຽງ.',
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsCard(
    BuildContext context,
    AdaptiveThemeProvider theme,
    AppThemeColors c,
  ) {
    return _card(
      c,
      children: [
        _switchRow(
          c,
          label: 'ໂໝດຄອນທຣາສສູງ',
          detail:
              'ສີດຳ, ສີຂາວ, ແລະ ສີເນັ້ນສົດໃສ ເພື່ອການເບິ່ງເຫັນທີ່ຊັດເຈນຂຶ້ນ.',
          icon: Icons.contrast,
          value: theme.highContrastMode,
          onChanged: theme.setHighContrast,
        ),
        const Divider(height: 18),
        _switchRow(
          c,
          label: 'ການແຈ້ງເຕືອນແບບເຫັນ ແລະ ສຳຜັດ',
          detail: 'ການແຈ້ງເຕືອນທີ່ສຳຄັນສາມາດສັ່ນ ແລະ ກະພິບໜ້າຈໍໄດ້.',
          icon: Icons.vibration,
          value: theme.visualAlertsEnabled,
          onChanged: theme.setVisualAlerts,
        ),
        const Divider(height: 18),
        _switchRow(
          c,
          label: 'ຫຼຸດການເຄື່ອນໄຫວ',
          detail:
              'ປິດການເຄື່ອນໄຫວ ແລະ ແອນິເມຊັນຕ່າງໆ ເພື່ອຜູ້ທີ່ມີອາການວິນຫົວ.',
          icon: Icons.animation,
          value: theme.reduceMotion,
          onChanged: theme.setReduceMotion,
        ),
      ],
    );
  }

  Widget _textScaleCard(AppThemeColors c, AdaptiveThemeProvider theme) {
    return _card(
      c,
      children: [
        Row(
          children: [
            Icon(Icons.text_fields, color: c.accentTertiary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ຂະໜາດຕົວອັກສອນ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: c.text,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'ປັບຂະໜາດຕົວອັກສອນໃຫ້ໃຫຍ່ຂຶ້ນ ຫຼື ນ້ອຍລົງຕາມຄວາມຕ້ອງການ.',
          style: TextStyle(fontSize: 12, color: c.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text('A', style: TextStyle(fontSize: 12)),
            Expanded(
              child: Slider(
                value: theme.textScale,
                min: 0.8,
                max: 1.5,
                divisions: 7,
                activeColor: c.accent,
                onChanged: theme.setTextScale,
              ),
            ),
            const Text('A', style: TextStyle(fontSize: 20)),
          ],
        ),
        Center(
          child: Text(
            '${(theme.textScale * 100).toInt()}%',
            style: TextStyle(fontSize: 12, color: c.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _screenReaderCard(AppThemeColors c) {
    return _card(
      c,
      children: [
        Row(
          children: [
            Icon(Icons.record_voice_over, color: c.accentSecondary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ການເພີ່ມປະສິດທິພາບສຳລັບໂປຣແກຣມອ່ານໜ້າຈໍ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: c.text,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _checkLine(c, 'ກະດານຫຼັກສະແດງປ້າຍ ແລະ ການດຳເນີນການທີ່ຊັດເຈນ.'),
        _checkLine(c, 'ໄອຄອນຕົກແຕ່ງຖືກຊ່ອນຈາກການນຳທາງດ້ວຍສຽງ.'),
        _checkLine(c, 'ປຸ່ມຄວບຄຸມທີ່ສຳຄັນໃຊ້ບົດບາດສະວິດ ແລະ ປຸ່ມແບບຄວາມໝາຍ.'),
      ],
    );
  }

  Widget _visualAlertCard(
    BuildContext context,
    AdaptiveThemeProvider theme,
    AppThemeColors c,
  ) {
    return Semantics(
      button: true,
      label: 'ທົດສອບການແຈ້ງເຕືອນແບບເຫັນ ແລະ ສຳຜັດ',
      hint: 'ແຕະສອງເທື່ອເພື່ອສັ່ນອຸປະກອນ ແລະ ກະພິບໜ້າຈໍ.',
      child: _card(
        c,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: c.accentTertiary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ທົດສອບການແຈ້ງເຕືອນແບບເຫັນ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: c.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            theme.visualAlertsEnabled
                ? 'ແຕະທົດສອບເພື່ອໃຫ້ສັ່ນ ແລະ ກະພິບແສງທີ່ເຫັນໄດ້ຊັດເຈນ.'
                : 'ແຕະທົດສອບເພື່ອໃຫ້ກະພິບແສງເທົ່ານັ້ນ.',
            style: TextStyle(fontSize: 12, color: c.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _testVisualAlert,
              icon: const Icon(Icons.flash_on),
              label: const Text('ທົດສອບການແຈ້ງເຕືອນ'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inclusiveReportCard(AppThemeColors c) {
    return _card(
      c,
      children: [
        Row(
          children: [
            Icon(Icons.diversity_3, color: c.accent, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ລາຍງານການອອກແບບທີ່ທຸກຄົນເຂົ້າເຖິງໄດ້',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: c.text,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'ໂໝດນີ້ສະແດງການເຂົ້າເຖິງເປັນຄຸນສົມບັດຂອງລະບົບ: ຄອນທຣາສສີທີ່ເຂັ້ມຂຶ້ນ, ປ້າຍກຳກັບເທັກໂນໂລຊີຊ່ວຍເຫຼືອ, ແລະ ການແຈ້ງເຕືອນທີ່ບໍ່ມີສຽງສຳລັບສຸຂະພາບ, ຄວາມປອດໄພ, ສະພາບອາກາດ, ຫຸ້ນ, ແລະ ຂັ້ນຕອນສຸກເສີນ.',
          style: TextStyle(fontSize: 12, color: c.textSecondary, height: 1.45),
        ),
      ],
    );
  }

  Widget _card(AppThemeColors c, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _switchRow(
    AppThemeColors c, {
    required String label,
    required String detail,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Semantics(
      toggled: value,
      label: label,
      hint: detail,
      child: Row(
        children: [
          Icon(icon, color: c.accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 11,
                    color: c.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: c.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _checkLine(AppThemeColors c, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: c.accentSecondary, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: c.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
