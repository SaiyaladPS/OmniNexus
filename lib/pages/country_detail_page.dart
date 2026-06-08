import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/country_service.dart';
import '../models/country.dart';
import 'country_compare_page.dart';

class CountryDetailPage extends StatelessWidget {
  final Country country;
  const CountryDetailPage({super.key, required this.country});

  @override
  Widget build(BuildContext context) {
    final c = ThemeProviderScope.of(context).colors;
    return Scaffold(
      backgroundColor: c.bg,
      body: CustomScrollView(
        slivers: [
          _DetailAppBar(c: c, country: country),
          SliverToBoxAdapter(child: _header(c)),
          SliverToBoxAdapter(child: _quickInfo(c)),
          SliverToBoxAdapter(child: _section(c, 'ພາສາ', country.languageList, Icons.translate)),
          SliverToBoxAdapter(child: _section(c, 'ສະກຸນເງິນ', country.currencyList, Icons.monetization_on)),
          SliverToBoxAdapter(child: _section(c, 'ເຂດເວລາ', country.timezoneList, Icons.access_time)),
          SliverToBoxAdapter(child: _section(c, 'ຊາຍແດນ', country.borderList, Icons.flag)),
          if (country.callingCode != null)
            SliverToBoxAdapter(child: _section(c, 'ລະຫັດໂທລະສັບ', country.callingCode!, Icons.phone)),
          if (country.carSide != null)
            SliverToBoxAdapter(child: _section(c, 'ຂ້າງຂັບລົດ', country.carSide!, Icons.directions_car)),
          SliverToBoxAdapter(child: _section(c, 'ທະວີບ', country.continentList, Icons.public)),
          SliverToBoxAdapter(child: _mapsSection(c)),
          SliverToBoxAdapter(child: _compareButton(c, context)),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _header(AppThemeColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              country.flagPng,
              width: 72,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 72, height: 48,
                color: c.surface,
                child: Center(child: Text(country.flagEmoji ?? '🏳️', style: const TextStyle(fontSize: 32))),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(country.name,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: c.text)),
                const SizedBox(height: 2),
                Text(country.officialName,
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickInfo(AppThemeColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _chip(c, Icons.location_city, country.capitalText),
          _chip(c, Icons.public, country.region),
          _chip(c, Icons.people, country.populationFormatted),
          _chip(c, Icons.straighten, country.areaFormatted),
          _chip(c, Icons.density_small, country.densityFormatted),
          if (country.unMember)
            _chip(c, Icons.check_circle, 'ສະມາຊິກ ສປຊ'),
          if (country.landlocked)
            _chip(c, Icons.landscape, 'ບໍ່ມີທາງອອກສູ່ທະເລ'),
        ],
      ),
    );
  }

  Widget _chip(AppThemeColors c, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c.accent),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: c.text)),
        ],
      ),
    );
  }

  Widget _section(AppThemeColors c, String title, String content, IconData icon) {
    if (content.isEmpty || content == 'N/A') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.accent.withValues(alpha: 0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: c.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textSecondary)),
                  const SizedBox(height: 4),
                  Text(content, style: TextStyle(fontSize: 14, color: c.text)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapsSection(AppThemeColors c) {
    if (country.googleMapsUrl == null && country.openStreetMapsUrl == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.map, size: 18, color: c.accent),
                const SizedBox(width: 8),
                Text('ແຜນທີ່', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text)),
              ],
            ),
          ),
          if (country.googleMapsUrl != null)
            _mapButton(c, 'ເປີດໃນ Google Maps', country.googleMapsUrl!, Icons.map),
          if (country.openStreetMapsUrl != null) const SizedBox(height: 8),
          if (country.openStreetMapsUrl != null)
            _mapButton(c, 'ເປີດໃນ OpenStreetMap', country.openStreetMapsUrl!, Icons.explore),
        ],
      ),
    );
  }

  Widget _mapButton(AppThemeColors c, String label, String url, IconData icon) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final uri = Uri.tryParse(url);
          if (uri == null) return;
          try {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } on MissingPluginException {
            // Native url_launcher not available — silently degrade
          }
        },
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: OutlinedButton.styleFrom(
          foregroundColor: c.accent,
          side: BorderSide(color: c.accent.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _compareButton(AppThemeColors c, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () => _showCompareSearch(context),
          icon: const Icon(Icons.compare_arrows, size: 20),
          label: const Text('ປຽບທຽບກັບປະເທດອື່ນ'),
          style: ElevatedButton.styleFrom(
            backgroundColor: c.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  void _showCompareSearch(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final sheetC = ThemeProviderScope.of(context).colors;
        return Container(
          height: MediaQuery.of(context).size.height * 0.45,
          decoration: BoxDecoration(
            color: sheetC.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _CompareSearchSheet(country: country, controller: controller),
        );
      },
    );
  }
}

class _DetailAppBar extends StatelessWidget {
  final AppThemeColors c;
  final Country country;
  const _DetailAppBar({required this.c, required this.country});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: c.appBar,
      foregroundColor: c.accentTertiary,
      elevation: 0,
      pinned: true,
      title: Text(country.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.accentTertiary)),
    );
  }
}

class _CompareSearchSheet extends StatefulWidget {
  final Country country;
  final TextEditingController controller;
  const _CompareSearchSheet({required this.country, required this.controller});

  @override
  State<_CompareSearchSheet> createState() => _CompareSearchSheetState();
}

class _CompareSearchSheetState extends State<_CompareSearchSheet> {
  List<Country> _results = [];
  bool _loading = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final results = await countryService.searchCountries(query);
    if (mounted) {
      setState(() {
        _results = results.where((c) => c.cca2 != widget.country.cca2).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeProviderScope.of(context).colors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  style: TextStyle(color: c.text),
                  decoration: InputDecoration(
                    hintText: 'ຄົ້ນຫາປະເທດເພື່ອປຽບທຽບ...',
                    hintStyle: TextStyle(color: c.textSecondary, fontSize: 14),
                    filled: true,
                    fillColor: c.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.search, color: c.accent, size: 22),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: _search,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: c.accent))
              : _results.isEmpty
                  ? Center(child: Text('ພິມຊື່ປະເທດ', style: TextStyle(color: c.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final other = _results[i];
                        return InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CountryComparePage(
                                  country1: widget.country,
                                  country2: other,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(other.flagPng, width: 32, height: 24, fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Text(other.flagEmoji ?? '🏳️', style: const TextStyle(fontSize: 18))),
                                ),
                                const SizedBox(width: 12),
                                Text(other.name, style: TextStyle(color: c.text, fontSize: 15)),
                                const Spacer(),
                                Text(other.capitalText, style: TextStyle(fontSize: 12, color: c.textSecondary)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
