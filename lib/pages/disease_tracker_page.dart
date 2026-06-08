import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/disease_tracker.dart';
import '../services/disease_tracker_service.dart';
import '../theme/app_theme.dart';

class DiseaseTrackerPage extends StatefulWidget {
  const DiseaseTrackerPage({super.key});

  @override
  State<DiseaseTrackerPage> createState() => _DiseaseTrackerPageState();
}

class _DiseaseTrackerPageState extends State<DiseaseTrackerPage> {
  final _service = DiseaseTrackerService();
  DiseaseDashboardData? _data;
  CountryDiseaseStats? _selectedCountry;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchDashboard();
      final selected = data.countries.firstWhere(
        (c) => c.country == (_selectedCountry?.country ?? 'Thailand'),
        orElse: () => data.countries.isNotEmpty
            ? data.countries.first
            : const CountryDiseaseStats(
                country: 'Unknown',
                iso2: '',
                continent: '',
                flagUrl: '',
                latitude: 0,
                longitude: 0,
                cases: 0,
                todayCases: 0,
                deaths: 0,
                todayDeaths: 0,
                recovered: 0,
                active: 0,
                critical: 0,
                tests: 0,
                population: 0,
                activePerOneMillion: 0,
                casesPerOneMillion: 0,
                deathsPerOneMillion: 0,
              ),
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _selectedCountry = selected.country == 'Unknown' ? null : selected;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeProviderScope.of(context).colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Disease Tracker'),
        backgroundColor: c.card,
        foregroundColor: c.text,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading && _data == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _data == null
          ? _buildError(c)
          : RefreshIndicator(onRefresh: _load, child: _buildContent(c)),
    );
  }

  Widget _buildError(AppThemeColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              size: 54,
              color: c.textSecondary,
            ),
            const SizedBox(height: 14),
            Text(
              'Could not load disease data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppThemeColors c) {
    final data = _data!;
    final selected = _selectedCountry;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHero(c, data),
        const SizedBox(height: 14),
        _buildGlobalStats(c, data.global),
        const SizedBox(height: 14),
        _buildVaccineCard(c, data),
        const SizedBox(height: 14),
        _buildTravelCheck(c, data, selected),
        const SizedBox(height: 14),
        _buildTopActiveChart(c, data),
        const SizedBox(height: 14),
        _buildCountryTable(c, data),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'Data: disease.sh COVID-19 global API',
            style: TextStyle(
              fontSize: 11,
              color: c.textSecondary.withValues(alpha: 0.65),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHero(AppThemeColors c, DiseaseDashboardData data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.accentSecondary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.vaccines, color: c.accentSecondary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Global Vaccine & Disease Tracker',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Epidemiology data analysis across ${data.global.affectedCountries} affected countries.',
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
    );
  }

  Widget _buildGlobalStats(AppThemeColors c, GlobalDiseaseStats g) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Global Outbreak Snapshot', style: _sectionTitle(c)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.85,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _statTile(
              c,
              'Total Cases',
              _fmt(g.cases),
              Icons.coronavirus,
              Colors.redAccent,
            ),
            _statTile(
              c,
              'Active Cases',
              _fmt(g.active),
              Icons.monitor_heart,
              Colors.orange,
            ),
            _statTile(
              c,
              'Recovered',
              _fmt(g.recovered),
              Icons.healing,
              Colors.green,
            ),
            _statTile(c, 'Tests', _fmt(g.tests), Icons.science, c.accent),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _metricPill(
                c,
                'Fatality',
                '${g.caseFatalityRate.toStringAsFixed(2)}%',
                Icons.insights,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _metricPill(
                c,
                'Today',
                '+${_fmt(g.todayCases)} cases',
                Icons.today,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVaccineCard(AppThemeColors c, DiseaseDashboardData data) {
    final coveredCountries = data.countries
        .where((c) => c.vaccineDoses > 0)
        .length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.accentSecondary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.vaccines, color: c.accentSecondary, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vaccine Coverage Signal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fmt(data.totalVaccineDoses)} administered doses reported across $coveredCountries countries.',
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
    );
  }

  Widget _buildTravelCheck(
    AppThemeColors c,
    DiseaseDashboardData data,
    CountryDiseaseStats? selected,
  ) {
    final risk = selected?.travelRisk ?? TravelRiskLevel.low;
    final riskColor = _riskColor(risk);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.travel_explore, color: riskColor, size: 22),
              const SizedBox(width: 8),
              Text('Health Travel Check', style: _sectionTitle(c)),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<CountryDiseaseStats>(
            initialValue: selected,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: c.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.public, color: c.textSecondary),
            ),
            items: data.countries
                .map(
                  (country) => DropdownMenuItem(
                    value: country,
                    child: Text(
                      country.country,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedCountry = value),
          ),
          if (selected != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    risk.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: riskColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  selected.continent,
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              selected.travelSummary,
              style: TextStyle(
                fontSize: 13,
                color: c.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  c,
                  'Active ${_fmt(selected.active)}',
                  Icons.monitor_heart,
                ),
                _chip(c, 'Today +${_fmt(selected.todayCases)}', Icons.today),
                _chip(
                  c,
                  'Critical ${_fmt(selected.critical)}',
                  Icons.local_hospital,
                ),
                _chip(
                  c,
                  'Vaccine ${selected.vaccineDosesPer100.toStringAsFixed(1)}/100',
                  Icons.vaccines,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopActiveChart(AppThemeColors c, DiseaseDashboardData data) {
    final countries = data.topActiveCountries;
    final maxActive = countries.isEmpty
        ? 1.0
        : countries
              .map((e) => e.active)
              .reduce((a, b) => a > b ? a : b)
              .toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Big Data Epidemiology: Active Case Hotspots',
            style: _sectionTitle(c),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= countries.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _shortCountryCode(countries[i]),
                            style: TextStyle(
                              fontSize: 10,
                              color: c.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                maxY: maxActive * 1.15,
                barGroups: List.generate(countries.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: countries[i].active.toDouble(),
                        color: _riskColor(countries[i].travelRisk),
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryTable(AppThemeColors c, DiseaseDashboardData data) {
    final countries = data.countries.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Countries With Highest Active Cases', style: _sectionTitle(c)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.accent.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: countries
                .map(
                  (country) => Column(
                    children: [
                      ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: _riskColor(
                            country.travelRisk,
                          ).withValues(alpha: 0.14),
                          child: Text(
                            _shortCountryCode(country),
                            style: TextStyle(
                              color: _riskColor(country.travelRisk),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        title: Text(
                          country.country,
                          style: TextStyle(
                            color: c.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          'Active ${_fmt(country.active)} • Today +${_fmt(country.todayCases)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: c.textSecondary,
                          ),
                        ),
                        trailing: Text(
                          country.travelRisk.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: _riskColor(country.travelRisk),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (country != countries.last)
                        Divider(height: 1, color: c.surface),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _statTile(
    AppThemeColors c,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricPill(
    AppThemeColors c,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: c.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: c.textSecondary),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: c.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(AppThemeColors c, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c.textSecondary),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, color: c.textSecondary)),
        ],
      ),
    );
  }

  TextStyle _sectionTitle(AppThemeColors c) {
    return TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: c.text);
  }

  Color _riskColor(TravelRiskLevel risk) {
    switch (risk) {
      case TravelRiskLevel.low:
        return Colors.green;
      case TravelRiskLevel.moderate:
        return Colors.orange;
      case TravelRiskLevel.high:
        return Colors.redAccent;
    }
  }

  String _fmt(int value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }

  String _shortCountryCode(CountryDiseaseStats country) {
    if (country.iso2.isNotEmpty) return country.iso2;
    if (country.country.length <= 2) return country.country;
    return country.country.substring(0, 2).toUpperCase();
  }
}
