import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../models/earthquake.dart';
import '../services/maps_config.dart';

class EarthquakeDetailPage extends StatelessWidget {
  final Earthquake eq;
  const EarthquakeDetailPage({super.key, required this.eq});

  @override
  Widget build(BuildContext context) {
    final c = ThemeProviderScope.of(context).colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: Text(eq.magFormatted, style: TextStyle(fontWeight: FontWeight.bold, color: c.accentTertiary)),
        backgroundColor: c.appBar,
        foregroundColor: c.accentTertiary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _share(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMagnitudeHeader(c),
          const SizedBox(height: 16),
          _buildBasicInfo(c),
          const SizedBox(height: 16),
          _buildDetailCards(c),
          const SizedBox(height: 16),
          _buildMap(c),
          const SizedBox(height: 16),
          if (eq.url != null) _buildUsgsButton(c),
        ],
      ),
    );
  }

  Widget _buildMagnitudeHeader(AppThemeColors c) {
    final color = _magColor;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), c.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color, width: 3),
            ),
            child: Center(
              child: Text(eq.magFormatted,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eq.place, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.text)),
                const SizedBox(height: 6),
                Text(eq.title, style: TextStyle(fontSize: 13, color: c.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(AppThemeColors c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.accent.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _infoRow(c, Icons.access_time, 'Time', eq.timeFormatted),
          const Divider(height: 20),
          _infoRow(c, Icons.explore, 'Depth', '${eq.depth.toStringAsFixed(1)} km'),
          const Divider(height: 20),
          _infoRow(c, Icons.location_on, 'Coordinates',
              '${eq.latitude.toStringAsFixed(3)}, ${eq.longitude.toStringAsFixed(3)}'),
          if (eq.hasTsunami) ...[
            const Divider(height: 20),
            _infoRow(c, Icons.warning, 'Tsunami', 'Yes - Take precautions',
                valueColor: Colors.red.shade400),
          ],
          if (eq.alert != null) ...[
            const Divider(height: 20),
            _infoRow(c, Icons.notifications_active, 'Alert Level', eq.alert!.toUpperCase(),
                valueColor: _alertColor(eq.alert!)),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(AppThemeColors c, IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: c.accent),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: c.textSecondary)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? c.text)),
      ],
    );
  }

  Widget _buildDetailCards(AppThemeColors c) {
    return Row(
      children: [
        _miniCard(c, 'Severity', eq.isSevere ? 'Severe' : eq.isModerate ? 'Moderate' : 'Minor', _magColor),
        const SizedBox(width: 10),
        _miniCard(c, 'Depth', eq.depth < 10 ? 'Shallow' : eq.depth < 30 ? 'Intermediate' : 'Deep', c.accent),
        const SizedBox(width: 10),
        _miniCard(c, 'Tsunami', eq.hasTsunami ? 'Yes' : 'No', eq.hasTsunami ? Colors.red : Colors.green),
      ],
    );
  }

  Widget _miniCard(AppThemeColors c, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: c.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(AppThemeColors c) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.accent.withValues(alpha: 0.15)),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(eq.latitude, eq.longitude),
          initialZoom: 5.0,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
        ),
        children: [
          TileLayer(
            urlTemplate: MapsConfig.tileUrl,
            userAgentPackageName: 'com.omninexus.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(eq.latitude, eq.longitude),
                width: 36,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _magColor.withValues(alpha: 0.25),
                    border: Border.all(color: _magColor, width: 2.5),
                  ),
                  child: Center(
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _magColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsgsButton(AppThemeColors c) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () async {
          final uri = Uri.tryParse(eq.url ?? '');
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        icon: const Icon(Icons.open_in_new, size: 18),
        label: const Text('View on USGS'),
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  void _share(BuildContext context) {
    final text = '${eq.title}\n'
        'Magnitude: ${eq.magFormatted}\n'
        'Depth: ${eq.depth.toStringAsFixed(1)} km\n'
        'Location: ${eq.latitude.toStringAsFixed(3)}, ${eq.longitude.toStringAsFixed(3)}\n'
        'Time: ${eq.time.toIso8601String()}\n'
        'Tsunami: ${eq.hasTsunami ? "Yes" : "No"}';
    Share.share(text);
  }

  Color get _magColor {
    if (eq.isSevere) return Colors.red.shade400;
    if (eq.isModerate) return Colors.orange.shade400;
    return Colors.green.shade400;
  }

  Color _alertColor(String alert) {
    switch (alert) {
      case 'green': return Colors.green;
      case 'yellow': return Colors.orange;
      case 'orange': return Colors.deepOrange;
      case 'red': return Colors.red;
      default: return Colors.grey;
    }
  }
}
