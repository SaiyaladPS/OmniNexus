import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import '../theme/app_theme.dart';
import '../data/recycle_data.dart';
import '../models/recycle_item.dart';
import '../services/green_points_service.dart';

final _keywordMap = <String, List<String>>{
  'bottle': ['plastic bottle', 'glass bottle', 'detergent bottle', 'reusable bottle', 'shampoo bottle', 'bottle cap'],
  'container': ['yogurt container', 'paint can', 'food container', 'takeout container'],
  'can': ['aluminum can', 'tin can', 'aerosol can', 'paint can'],
  'paper': ['office paper', 'newspaper', 'cardboard box', 'shredded paper', 'wrapping paper', 'paper towel', 'envelope', 'pizza box'],
  'cardboard': ['cardboard box', 'pizza box'],
  'glass': ['glass bottle', 'glass jar', 'broken glass'],
  'plastic': ['plastic bottle', 'plastic bag', 'plastic straw', 'plastic cup', 'plastic wrap', 'plastic cutlery', 'bottle cap', 'shampoo bottle', 'yogurt container', 'detergent bottle', 'styrofoam cup', 'packing peanuts'],
  'metal': ['aluminum can', 'tin can', 'aluminum foil', 'aerosol can', 'wire hanger', 'copper wire', 'metal bottle cap'],
  'food': ['food scraps', 'leftovers', 'coffee grounds', 'eggshells', 'meat bones'],
  'organic': ['food scraps', 'garden waste', 'coffee grounds', 'eggshells', 'meat bones', 'fruit scraps', 'vegetable scraps'],
  'electronic': ['mobile phone', 'laptop computer', 'television', 'charger cable', 'printer cartridge'],
  'battery': ['battery', 'li-ion battery'],
  'light': ['light bulb', 'fluorescent tube'],
  'oil': ['motor oil'],
  'medicine': ['expired medicine'],
  'paint': ['paint can'],
  'cloth': ['used clothing'],
  'clothing': ['used clothing'],
  'textile': ['used clothing'],
  'shoe': ['used clothing'],
  'book': ['books'],
  'cork': ['wine cork'],
  'gum': ['chewing gum'],
  'mask': ['face mask'],
  'diaper': ['disposable diaper'],
  'cigarette': ['cigarette butt'],
  'rubber': ['rubber band'],
  'pizza': ['pizza box'],
  'newspaper': ['newspaper'],
  'magazine': ['newspaper'],
  'jar': ['glass jar'],
  'foil': ['aluminum foil'],
  'cup': ['styrofoam cup', 'plastic cup', 'yogurt container'],
  'straw': ['plastic straw'],
  'bag': ['plastic bag'],
  'wrap': ['plastic wrap'],
  'fork': ['plastic cutlery'],
  'spoon': ['plastic cutlery'],
  'knife': ['plastic cutlery'],
  'cutlery': ['plastic cutlery'],
  'phone': ['mobile phone'],
  'laptop': ['laptop computer'],
  'computer': ['laptop computer'],
  'tv': ['television'],
  'monitor': ['television'],
  'cable': ['charger cable'],
  'charger': ['charger cable'],
  'cartridge': ['printer cartridge'],
  'printer': ['printer cartridge'],
  'light bulb': ['light bulb'],
  'bulb': ['light bulb'],
  'fluorescent': ['fluorescent tube'],
  'egg': ['eggshells'],
  'coffee': ['coffee grounds'],
  'tea': ['coffee grounds'],
  'garden': ['garden waste'],
  'leaf': ['garden waste'],
  'grass': ['garden waste'],
  'meat': ['meat bones'],
  'bone': ['meat bones'],
  'fish': ['meat bones'],
  'leftover': ['leftovers'],
  'cooked': ['leftovers'],
};

final _labeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.3));

Set<RecycleItem> _matchLabels(List<ImageLabel> labels) {
  final matched = <RecycleItem>{};
  final seen = <String>{};

  for (final label in labels) {
    final q = label.label.toLowerCase().trim();
    if (q.isEmpty || seen.contains(q)) continue;
    seen.add(q);

    for (final item in recycleItems) {
      if (item.nameEn.toLowerCase().contains(q) ||
          item.name.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q)) {
        matched.add(item);
      }
    }

    if (_keywordMap.containsKey(q)) {
      for (final alias in _keywordMap[q]!) {
        for (final item in recycleItems) {
          if (item.nameEn.toLowerCase() == alias ||
              item.name.toLowerCase() == alias) {
            matched.add(item);
          }
        }
      }
    }
  }

  return matched;
}

class RecyclePage extends StatefulWidget {
  const RecyclePage({super.key});

  @override
  State<RecyclePage> createState() => _RecyclePageState();
}

class _RecyclePageState extends State<RecyclePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  RecycleCategory? _selectedCategory;

  final _picker = ImagePicker();
  bool _scanProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() { if (mounted) setState(() {}); });
    _searchCtrl.addListener(() => setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<RecycleItem> get _filteredItems {
    var items = recycleItems;
    if (_selectedCategory != null) {
      items = items.where((i) => i.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      items = items.where((i) =>
        i.name.toLowerCase().contains(_searchQuery) ||
        i.nameEn.toLowerCase().contains(_searchQuery) ||
        i.description.toLowerCase().contains(_searchQuery) ||
        i.categoryLabel.toLowerCase().contains(_searchQuery)
      ).toList();
    }
    return items;
  }

  void _logRecycling(RecycleItem item) {
    greenPointsService.addRecord(item.nameEn, item.categoryLabel);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+10 ຄະແນນ ສຳລັບການຄັດແຍກ ${item.nameEn}!'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.green.shade600),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeProviderScope.of(context).colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Recycle Helper'),
        backgroundColor: c.card,
        foregroundColor: c.text,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          labelColor: Colors.green,
          unselectedLabelColor: c.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'ຄົ້ນຫາ'),
            Tab(icon: Icon(Icons.document_scanner), text: 'ສະແກນ'),
            Tab(icon: Icon(Icons.eco), text: 'ຄະແນນ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(c),
          _buildScanTab(c),
          _buildPointsTab(c),
        ],
      ),
    );
  }

  Widget _buildSearchTab(AppThemeColors c) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'ຄົ້ນຫາຂີ້ເຫຍື້ອ...',
              prefixIcon: Icon(Icons.search, color: c.textSecondary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => _searchCtrl.clear())
                  : null,
              filled: true, fillColor: c.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _categoryChip(c, null, 'ທັງໝົດ', Icons.all_inclusive),
              for (final cat in RecycleCategory.values)
                _categoryChip(c, cat, '${cat.emoji} ${cat.label}', null),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _filteredItems.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isNotEmpty ? 'ບໍ່ພົບ "$_searchQuery"' : 'ເລືອກປະເພດເພື່ອເບິ່ງ',
                    style: TextStyle(color: c.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, i) => _buildItemCard(c, _filteredItems[i]),
                ),
        ),
      ],
    );
  }

  Widget _categoryChip(AppThemeColors c, RecycleCategory? cat, String label, IconData? icon) {
    final active = _selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = active ? null : cat),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.green : c.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? Colors.green : c.textSecondary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 16, color: active ? Colors.white : c.text),
              if (label.isNotEmpty) ...[
                if (icon != null) const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.white : c.text)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(AppThemeColors c, RecycleItem item) {
    final color = item.recyclable ? Colors.green : Colors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.accent.withValues(alpha: 0.12))),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: item.recyclable ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 22))),
        ),
        title: Text(item.nameEn, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(
                item.recyclable ? 'ຣີໄຊເຄິນໄດ້' : 'ຣີໄຊເຄິນບໍ່ໄດ້',
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 6),
            Text('${item.categoryEmoji} ${item.categoryLabel}', style: TextStyle(fontSize: 10, color: c.textSecondary)),
          ],
        ),
        children: [
          const Divider(),
          _infoRow(c, 'ປະເພດ', '${item.categoryEmoji} ${item.categoryLabel}'),
          _infoRow(c, item.recyclable ? 'ວິທີຣີໄຊເຄິນ' : 'ວິທີຖິ້ມ', item.instruction),
          if (item.decomposeYears != null) _infoRow(c, 'ເນົ່າໃຊ້ເວລາ', item.decomposeYears!),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _logRecycling(item),
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('ບັນທຶກວ່າຣີໄຊເຄິນ +10pts', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(AppThemeColors c, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 11, color: c.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: c.text, height: 1.3))),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Scan Tab
  // ═══════════════════════════════════════════════════════════════
  Widget _buildScanTab(AppThemeColors c) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.document_scanner, size: 48, color: Colors.green.shade500),
                ),
                const SizedBox(height: 24),
                Text('ຖ່າຍຮູບຂີ້ເຫຍື້ອ ເພື່ອໃຫ້ AI ຈຳແນກ', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: c.textSecondary, height: 1.4)),
                const SizedBox(height: 8),
                Text('AI ຈະບອກວ່າຣີໄຊເຄິນໄດ້ບໍ່ ແລະ ວິທີຖິ້ມ', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: c.textSecondary.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ),
        _buildScanBottomBar(c),
      ],
    );
  }

  Widget _buildScanBottomBar(AppThemeColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
      decoration: BoxDecoration(color: c.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _scanProcessing ? null : () => _scanWaste(useCamera: true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _scanProcessing
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                    const SizedBox(height: 6),
                    Text(_scanProcessing ? 'ກຳລັງວິເຄາະ...' : 'ຖ່າຍຮູບ', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: _scanProcessing ? null : () => _scanWaste(useCamera: false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: c.surface, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  children: [
                    Icon(Icons.photo_library, color: Colors.green.shade600, size: 28),
                    const SizedBox(height: 6),
                    Text('ເລືອກຈາກຄັງຮູບ', style: TextStyle(color: Colors.green.shade600, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanWaste({required bool useCamera}) async {
    if (_scanProcessing) return;
    setState(() => _scanProcessing = true);
    try {
      final xFile = await _picker.pickImage(
        source: useCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 800,
      );
      if (xFile == null) { if (mounted) setState(() => _scanProcessing = false); return; }
      final inputImage = InputImage.fromFilePath(xFile.path);
      final labels = await _labeler.processImage(inputImage);
      if (!mounted) return;
      _showScanResults(labels);
    } catch (e) {
      if (mounted) _showScanError('ເກີດຂໍ້ຜິດພາດ: $e');
    } finally {
      if (mounted) setState(() => _scanProcessing = false);
    }
  }

  void _showScanResults(List<ImageLabel> labels) {
    final sorted = _matchLabels(labels).toList();

    if (!mounted) return;
    final c = ThemeProviderScope.of(context).colors;

    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: c.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(sorted.isEmpty ? 'ບໍ່ພົບລາຍການທີ່ກົງກັນ' : 'ພົບ ${sorted.length} ລາຍການ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c.text)),
              const SizedBox(height: 4),
              Text(
                sorted.isEmpty
                  ? 'AI ກວດພົບ: ${labels.map((l) => l.label).join(", ")}'
                  : 'AI ຈັບຄູ່ກັບຖານຂໍ້ມູນຂີ້ເຫຍື້ອ',
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
              const SizedBox(height: 12),
              if (sorted.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 40, color: c.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      Text('ລອງຖ່າຍຮູບຂີ້ເຫຍື້ອທົ່ວໄປ ເຊັ່ນ ຂວດພລາສຕິກ ຫຼື ກະປ໋ອງ', style: TextStyle(color: c.textSecondary)),
                    ],
                  ),
                )
              else
                ...sorted.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: c.surface, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: item.recyclable ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Text(item.emoji, style: const TextStyle(fontSize: 24)),
                    title: Text(item.nameEn, style: TextStyle(fontWeight: FontWeight.w600, color: c.text, fontSize: 14)),
                    subtitle: Text(
                      item.recyclable ? 'ຣີໄຊເຄິນໄດ້' : 'ຣີໄຊເຄິນບໍ່ໄດ້',
                      style: TextStyle(color: item.recyclable ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    trailing: FilledButton(
                      onPressed: () { Navigator.pop(ctx); _logRecycling(item); },
                      style: FilledButton.styleFrom(backgroundColor: Colors.green.shade600, padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(0, 32)),
                      child: const Text('+10', style: TextStyle(fontSize: 12)),
                    ),
                    onTap: () => Navigator.pop(ctx),
                  ),
                )),
            ],
          ),
        );
      },
    );
  }

  void _showScanError(String msg) {
    if (!mounted) return;
    final c = ThemeProviderScope.of(context).colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: c.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Icon(Icons.error_outline, size: 40, color: Colors.red.shade400),
              const SizedBox(height: 12),
              Text(msg, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary)),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Points Tab
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPointsTab(AppThemeColors c) {
    final pts = greenPointsService.totalPoints;
    final level = greenPointsService.level;
    final count = greenPointsService.recyclingCount;
    final progress = greenPointsService.nextLevelProgress;
    final history = greenPointsService.history;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.green.shade600, Colors.teal.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(level, style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('$pts', style: const TextStyle(fontSize: 56, color: Colors.white, fontWeight: FontWeight.w900)),
              const Text('Green Points', style: TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 6),
              Text('${greenPointsService.currentLevelThreshold} → ${greenPointsService.nextLevelThreshold} pts',
                style: const TextStyle(fontSize: 11, color: Colors.white60)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _statCard(c, Icons.recycling, '$count', 'ຣີໄຊເຄິນແລ້ວ', Colors.blue),
            const SizedBox(width: 12),
            _statCard(c, Icons.stars, '$pts', 'ຄະແນນທັງໝົດ', Colors.amber),
            const SizedBox(width: 12),
            _statCard(c, Icons.eco, level.split(' ').last, 'ຕຳແໜ່ງ', Colors.green),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ປະຫວັດການໃຊ້ງານ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.text)),
            TextButton(onPressed: () => greenPointsService.reset(),
              child: Text('ຣີເຊັດ', style: TextStyle(fontSize: 12, color: Colors.red.shade400))),
          ],
        ),
        if (history.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.textSecondary.withValues(alpha: 0.15))),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.eco, size: 48, color: Colors.green.shade200),
                  const SizedBox(height: 12),
                  Text('ຍັງບໍ່ທັນມີການບັນທຶກ', style: TextStyle(color: c.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('ຄົ້ນຫາ ຫຼື ສະແກນຂີ້ເຫຍື້ອ ເພື່ອສະສົມຄະແນນ!',
                    style: TextStyle(color: c.textSecondary.withValues(alpha: 0.7), fontSize: 11)),
                ],
              ),
            ),
          )
        else
          ...List.generate(history.length, (i) {
            final rec = history[i];
            final diff = DateTime.now().difference(rec.date);
            final timeStr = diff.inDays > 0 ? '${diff.inDays}d' : diff.inHours > 0 ? '${diff.inHours}h' : '${diff.inMinutes}m';
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.accent.withValues(alpha: 0.1))),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rec.itemName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text)),
                        Text('${rec.category} • $timeStr', style: TextStyle(fontSize: 11, color: c.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Text('+${rec.points}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _statCard(AppThemeColors c, IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c.text)),
            Text(label, style: TextStyle(fontSize: 10, color: c.textSecondary), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
