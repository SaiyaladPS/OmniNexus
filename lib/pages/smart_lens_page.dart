import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

const _labelMap = {
  'food': 'ອາຫານ',
  'fruit': 'ໝາກໄມ້',
  'vegetable': 'ຜັກ',
  'meat': 'ຊີ້ນ',
  'seafood': 'ອາຫານທະເລ',
  'fish': 'ປາ',
  'chicken': 'ໄກ່',
  'pork': 'ຊີ້ນໝູ',
  'beef': 'ຊີ້ນງົວ',
  'egg': 'ໄຂ່',
  'rice': 'ເຂົ້າ',
  'noodle': 'ເສັ້ນເຝີ',
  'bread': 'ເຂົ້າຈີ່',
  'cake': 'ເຄັກ',
  'dessert': 'ຂອງຫວານ',
  'drink': 'ເຄື່ອງດື່ມ',
  'juice': 'ນ້ຳໝາກໄມ້',
  'water': 'ນ້ຳ',
  'milk': 'ນົມ',
  'coffee': 'ກາເຟ',
  'tea': 'ຊາ',
  'soup': 'ແກງ',
  'salad': 'ສະຫຼັດ',
  'sauce': 'ຊອດ',
  'plant': 'ຕົ້ນໄມ້',
  'flower': 'ດອກໄມ້',
  'leaf': 'ໃບໄມ້',
  'animal': 'ສັດ',
  'dog': 'ໝາ',
  'cat': 'ແມວ',
  'book': 'ປຶ້ມ',
  'phone': 'ໂທລະສັບ',
  'bottle': 'ຂວດ',
  'cup': 'ຈອກ',
  'plate': 'ຈານ',
  'bowl': 'ໂຖ',
  'table': 'ໂຕະ',
  'chair': 'ຕັ່ງ',
  'car': 'ລົດ',
  'bicycle': 'ລົດຖີບ',
  'clothing': 'ເສື້ອຜ້າ',
  'shoe': 'ເກີບ',
  'bag': 'ກະເປົາ',
  'watch': 'ໂມງ',
  'glasses': 'ແວ່ນຕາ',
  'electronics': 'ເຄື່ອງໄຟຟ້າ',
  'tool': 'ເຄື່ອງມື',
  'toy': 'ຂອງຫຼິ້ນ',
  'furniture': 'ເຟີນີເຈີ',
};

String _translate(String label) {
  final key = label.toLowerCase().trim();
  if (_labelMap.containsKey(key)) return _labelMap[key]!;
  for (final entry in _labelMap.entries) {
    if (key.contains(entry.key)) return '${entry.value} ($label)';
  }
  return label;
}

class SmartLensPage extends StatefulWidget {
  const SmartLensPage({super.key});

  @override
  State<SmartLensPage> createState() => _SmartLensPageState();
}

class _SmartLensPageState extends State<SmartLensPage> {
  final _picker = ImagePicker();
  ImageLabeler? _labeler;
  bool _processing = false;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initLabeler();
  }

  @override
  void dispose() {
    _labeler?.close();
    super.dispose();
  }

  void _initLabeler() {
    try {
      _labeler = ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: 0.3),
      );
      _ready = true;
    } catch (e) {
      _error = 'ເກີດຂໍ້ຜິດພາດ: $e';
    }
  }

  Future<void> _pickAndLabel({required bool useCamera}) async {
    if (_processing || !_ready) return;
    if (_labeler == null) {
      if (mounted) _showResult(null, 'AI ຍັງບໍ່ພ້ອມ, ກະລຸນາລອງໃໝ່');
      return;
    }
    setState(() => _processing = true);
    try {
      final xFile = await _picker.pickImage(
        source: useCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 800,
      );
      if (xFile == null) {
        if (mounted) setState(() => _processing = false);
        return;
      }
      final inputImage = InputImage.fromFilePath(xFile.path);
      final labels = await _labeler!.processImage(inputImage);
      if (!mounted) return;

      if (labels.isEmpty) {
        _showResult(null, 'ບໍ່ພົບວັດຖຸ ລອງຖ່າຍມຸມໃໝ່ ຫຼື ແສງໃຫ້ດີກວ່າ');
      } else {
        _showResult(labels, null);
      }
    } catch (e) {
      if (mounted) _showResult(null, 'ເກີດຂໍ້ຜິດພາດ: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showResult(List<ImageLabel>? labels, String? errorMsg) {
    if (!mounted) return;
    final c = ThemeProviderScope.of(context).colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                labels != null ? 'ວັດຖຸທີ່ກວດພົບ' : 'ຜົນການກວດ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: c.text,
                ),
              ),
              const SizedBox(height: 12),
              if (errorMsg != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 40,
                        color: c.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        errorMsg,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: c.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                ...labels!.map((label) => _buildLabelTile(label, c, ctx)),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabelTile(ImageLabel label, AppThemeColors c, BuildContext ctx) {
    final pct = (label.confidence * 100).toStringAsFixed(0);
    final lao = _translate(label.label);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.search, size: 18, color: c.accent),
        ),
        title: Text(
          lao,
          style: TextStyle(
            color: c.text,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: label.label != lao
            ? Text(
                label.label,
                style: TextStyle(color: c.textSecondary, fontSize: 11),
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$pct%',
            style: TextStyle(
              fontSize: 11,
              color: c.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () {
          Navigator.pop(ctx);
          _showImageSearch(label.label, lao);
        },
      ),
    );
  }

  void _showImageSearch(String english, String lao) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ImageSearchPage(label: english, labelLao: lao),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeProviderScope.of(context).colors;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Smart Lens'),
        backgroundColor: c.card,
        foregroundColor: c.text,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(child: _buildHero(c)),
          _buildBottomBar(c),
        ],
      ),
    );
  }

  Widget _buildHero(AppThemeColors c) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                'AI Model Error',
                style: TextStyle(
                  fontSize: 16,
                  color: c.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.document_scanner, size: 48, color: c.accent),
          ),
          const SizedBox(height: 24),
          Text(
            'ຖ່າຍຮູບອາຫານ ຫຼື ວັດຖຸ\nເພື່ອໃຫ້ AI ຈຳແນກ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: c.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            'ກົດທີ່ຊື່ວັດຖຸ ເພື່ອເບິ່ງຮູບຕົວຢ່າງ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: c.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AppThemeColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _processing || !_ready
                      ? null
                      : () => _pickAndLabel(useCamera: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _processing
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 28,
                              ),
                        const SizedBox(height: 6),
                        Text(
                          _processing ? 'ກຳລັງປະມວນຜົນ...' : 'ຖ່າຍຮູບ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: _processing || !_ready
                      ? null
                      : () => _pickAndLabel(useCamera: false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: c.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.photo_library, color: c.accent, size: 28),
                        const SizedBox(height: 6),
                        Text(
                          'ເລືອກຈາກຄັງຮູບ',
                          style: TextStyle(color: c.accent, fontSize: 12),
                        ),
                      ],
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
}

class _ImageSearchPage extends StatefulWidget {
  final String label;
  final String labelLao;
  const _ImageSearchPage({required this.label, required this.labelLao});

  @override
  State<_ImageSearchPage> createState() => _ImageSearchPageState();
}

class _ImageSearchPageState extends State<_ImageSearchPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final url = Uri.parse(
        'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(widget.label)}',
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        if (mounted)
          setState(() {
            _data = jsonDecode(res.body) as Map<String, dynamic>;
            _loading = false;
          });
      } else {
        if (mounted)
          setState(() {
            _error = 'ບໍ່ພົບຂໍ້ມູນ';
            _loading = false;
          });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = 'ເກີດຂໍ້ຜິດພາດ: $e';
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
        title: Text(widget.labelLao),
        backgroundColor: c.card,
        foregroundColor: c.text,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError(c)
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_data?['thumbnail']?['source'] != null)
                    Image.network(
                      _data!['thumbnail']['source'],
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildImageFallback(c),
                    )
                  else
                    _buildImageFallback(c),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.labelLao,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 14,
                            color: c.textSecondary,
                          ),
                        ),
                        if (_data?['extract'] != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _data!['extract'] as String,
                            style: TextStyle(
                              fontSize: 15,
                              color: c.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: () async {
                              final uri = Uri.parse(
                                'https://en.wikipedia.org/wiki/${Uri.encodeComponent(widget.label)}',
                              );
                              await _launchUrl(uri);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: c.accent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.open_in_new,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'ເບິ່ງເພີ່ມເຕີມ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  Widget _buildImageFallback(AppThemeColors c) {
    return Container(
      width: double.infinity,
      height: 280,
      color: c.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_search,
            size: 64,
            color: c.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text('ບໍ່ມີຮູບຕົວຢ່າງ', style: TextStyle(color: c.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildError(AppThemeColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: c.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
