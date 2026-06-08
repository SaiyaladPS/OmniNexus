import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/country_service.dart';
import '../models/country.dart';
import 'country_detail_page.dart';

class CountryPage extends StatefulWidget {
  const CountryPage({super.key});

  @override
  State<CountryPage> createState() => _CountryPageState();
}

class _CountryPageState extends State<CountryPage> {
  final _controller = TextEditingController();
  List<Country> _results = [];
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });
    try {
      final results = await countryService.searchCountries(query);
      if (mounted) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeProviderScope.of(context).colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('ຂໍ້ມູນປະເທດທົ່ວໂລກ'),
        backgroundColor: c.appBar,
        foregroundColor: c.accentTertiary,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(c),
          Expanded(child: _buildBody(c)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppThemeColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: TextField(
        controller: _controller,
        style: TextStyle(color: c.text),
        decoration: InputDecoration(
          hintText: 'ຄົ້ນຫາປະເທດ... ຕ.ຍ. ໄທ, ຍີ່ປຸ່ນ',
          hintStyle: TextStyle(color: c.textSecondary, fontSize: 14),
          filled: true,
          fillColor: c.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(Icons.public, color: c.accent, size: 22),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: c.textSecondary, size: 18),
                  onPressed: () {
                    _controller.clear();
                    setState(() {});
                  },
                  splashRadius: 16,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _search(),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildBody(AppThemeColors c) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: c.accent));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: c.textSecondary),
            const SizedBox(height: 12),
            Text(
              'ການຄົ້ນຫາຫຼົ້ມເຫຼວ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
          ],
        ),
      );
    }
    if (!_searched) {
      return _buildEmptyState(
        c,
        icon: Icons.map,
        title: 'ສຳຫຼວດໂລກ',
        subtitle: 'ຄົ້ນຫາປະເທດໃດໜຶ່ງເພື່ອເບິ່ງ\nຂໍ້ມູນລະອຽດຂອງປະເທດນັ້ນ.',
      );
    }
    if (_results.isEmpty) {
      return _buildEmptyState(
        c,
        icon: Icons.sentiment_dissatisfied,
        title: 'ບໍ່ພົບປະເທດ',
        subtitle: 'ລອງຄົ້ນຫາຊື່ອື່ນ\nຕ.ຍ. ໄທ, ຍີ່ປຸ່ນ, ຝຣັ່ງ',
      );
    }
    return _buildList(c);
  }

  Widget _buildEmptyState(
    AppThemeColors c, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: c.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: c.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(AppThemeColors c) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final country = _results[index];
        return _CountryTile(country: country, c: c);
      },
    );
  }
}

class _CountryTile extends StatelessWidget {
  final Country country;
  final AppThemeColors c;

  const _CountryTile({required this.country, required this.c});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CountryDetailPage(country: country),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                country.flagPng,
                width: 44,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 44,
                  height: 32,
                  color: c.surface,
                  child: Center(
                    child: Text(
                      country.flagEmoji ?? '🏳️',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    country.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${country.capitalText} · ${country.region}',
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  country.populationFormatted,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.accent,
                  ),
                ),
                Text(
                  'ປະຊາກອນ',
                  style: TextStyle(fontSize: 10, color: c.textSecondary),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 18, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}
