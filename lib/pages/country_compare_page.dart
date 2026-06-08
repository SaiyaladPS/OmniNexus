import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/country.dart';

class CountryComparePage extends StatelessWidget {
  final Country country1;
  final Country country2;
  const CountryComparePage({
    super.key,
    required this.country1,
    required this.country2,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeProviderScope.of(context).colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: Text('ປຽບທຽບ: ${country1.name} ກັບ ${country2.name}'),
        backgroundColor: c.appBar,
        foregroundColor: c.accentTertiary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _flagsRow(c),
          const SizedBox(height: 20),
          _compareRow(c, 'ເມືອງຫຼວງ', country1.capitalText, country2.capitalText),
          _compareRow(c, 'ປະຊາກອນ', country1.populationFormatted, country2.populationFormatted,
              highlight: country1.population != country2.population),
          _compareRow(c, 'ເນື້ອທີ່', country1.areaFormatted, country2.areaFormatted),
          _compareRow(c, 'ຄວາມໜາແໜ້ນ', country1.densityFormatted, country2.densityFormatted),
          _compareRow(c, 'ພາສາ', country1.languageList, country2.languageList),
          _compareRow(c, 'ສະກຸນເງິນ', country1.currencyList, country2.currencyList),
          _compareRow(c, 'ພູມິພາກ', country1.region, country2.region),
          _compareRow(c, 'ພູມິພາກຍ່ອຍ', country1.subregion ?? 'N/A', country2.subregion ?? 'N/A'),
          _compareRow(c, 'ເຂດເວລາ', country1.timezoneList, country2.timezoneList),
          _compareRow(c, 'ທະວີບ', country1.continentList, country2.continentList),
          _compareRow(c, 'ຊາຍແດນ', country1.borderList, country2.borderList),
          if (country1.callingCode != null || country2.callingCode != null)
            _compareRow(c, 'ລະຫັດໂທລະສັບ', country1.callingCode ?? 'N/A', country2.callingCode ?? 'N/A'),
          if (country1.carSide != null || country2.carSide != null)
            _compareRow(c, 'ຂ້າງຂັບລົດ', country1.carSide ?? 'N/A', country2.carSide ?? 'N/A'),
          _compareRow(c, 'ສະມາຊິກ ສປຊ', country1.unMember ? 'ແມ່ນ' : 'ບໍ່', country2.unMember ? 'ແມ່ນ' : 'ບໍ່'),
          _compareRow(c, 'ບໍ່ມີທາງອອກສູ່ທະເລ', country1.landlocked ? 'ແມ່ນ' : 'ບໍ່', country2.landlocked ? 'ແມ່ນ' : 'ບໍ່'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _flagsRow(AppThemeColors c) {
    return Row(
      children: [
        Expanded(child: _flagCard(c, country1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.compare_arrows, size: 28, color: c.accent),
        ),
        Expanded(child: _flagCard(c, country2)),
      ],
    );
  }

  Widget _flagCard(AppThemeColors c, Country country) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              country.flagPng,
              width: double.infinity,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 80,
                color: c.surface,
                child: Center(child: Text(country.flagEmoji ?? '🏳️', style: const TextStyle(fontSize: 48))),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(country.name, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.text)),
          if (country.cca2.isNotEmpty)
            Text(country.cca2, style: TextStyle(fontSize: 11, color: c.textSecondary)),
        ],
      ),
    );
  }

  Widget _compareRow(AppThemeColors c, String label, String val1, String val2, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight ? c.accent.withValues(alpha: 0.25) : c.accent.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.textSecondary)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(val1, style: TextStyle(fontSize: 13, color: c.text)),
                ),
                Container(width: 1, height: 24, color: c.accent.withValues(alpha: 0.2)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(val2, style: TextStyle(fontSize: 13, color: c.text)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
