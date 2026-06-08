import 'package:flutter/material.dart';
import '../models/apod.dart';
import '../services/apod_service.dart';

class ApodPage extends StatefulWidget {
  const ApodPage({super.key});

  @override
  State<ApodPage> createState() => _ApodPageState();
}

class _ApodPageState extends State<ApodPage> {
  final _service = ApodService();
  late Future<Apod> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchApod();
  }

  void _reload() {
    setState(() {
      _future = _service.fetchApod();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4FC),
      appBar: AppBar(
        title: const Text('ຮູບພາບດາລາສາດປະຈຳວັນ'),
        backgroundColor: const Color(0xFFF3E8FF),
        foregroundColor: const Color(0xFF6B4F8B),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: FutureBuilder<Apod>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF9B6FBF)),
                  SizedBox(height: 16),
                  Text('ກຳລັງດຶງຂໍ້ມູນຈາກຫ້ວງອາວະກາດ...', style: TextStyle(color: Color(0xFFA098B8))),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return _ErrorView(message: snapshot.error.toString(), onRetry: _reload);
          } else if (!snapshot.hasData) {
            return const Center(child: Text('ບໍ່ມີຂໍ້ມູນ', style: TextStyle(color: Color(0xFFA098B8))));
          }

          final apod = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      child: Image.network(
                        apod.hdurl ?? apod.url,
                        height: 350,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 350,
                            color: const Color(0xFFF0E8F8),
                            child: const Center(
                              child: CircularProgressIndicator(color: Color(0xFF9B6FBF)),
                            ),
                          );
                        },
                        errorBuilder: (_, _, _) => Container(
                          height: 350,
                          color: const Color(0xFFF0E8F8),
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 64, color: Color(0xFFC8B8D8)),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          apod.date,
                          style: const TextStyle(color: Color(0xFF6B4F8B), fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        apod.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D3555),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          apod.mediaType == 'image' ? 'ຮູບພາບ' : 'ວິດີໂອ',
                          style: const TextStyle(color: Color(0xFF9B6FBF), fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        apod.explanation,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF5A5270),
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFE6D8F5)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF9FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFECE2F8)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Color(0xFF9B6FBF), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'ກ່ຽວກັບ ແລະ ວິທີໃຊ້ງານ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6B4F8B),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              '💡 ກ່ຽວກັບ:\nສະແດງຮູບພາບ ຫຼື ວິດີໂອອາວະກາດທີ່ຖືກຄັດເລືອກໂດຍ NASA ໃນແຕ່ລະມື້ ພ້ອມກັບຄຳອະທິບາຍໂດຍນັກດາລາສາດມືອາຊີບ ເພື່ອໃຫ້ຄວາມຮູ້ກ່ຽວກັບຄວາມອັດສະຈັນຂອງຈັກກະວານ.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF7B6F9F), height: 1.5),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '📱 ວິທີໃຊ້ງານ:\n1. ເບິ່ງຮູບພາບ ແລະ ອ່ານຄຳອະທິບາຍລະອຽດດ້ານລຸ່ມ.\n2. ແຕະໄອຄອນ ໂຫຼດໃໝ່ (Refresh) ຢູ່ມຸມຂວາເທິງເພື່ອອັບເດດຂໍ້ມູນຫຼ້າສຸດ.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF7B6F9F), height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F4FC),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Color(0xFFC8B8D8)),
              const SizedBox(height: 16),
              const Text(
                'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນໄດ້',
                style: TextStyle(fontSize: 18, color: Color(0xFF4A4063), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFA098B8), fontSize: 13),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('ລອງໃໝ່ອີກຄັ້ງ'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9B6FBF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
