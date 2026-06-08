// Algorithms demonstrated in this module:
//
// 1. Mental Health Quiz Scoring (DASS-based):
//    Σ(category_score) = Σ(answer_value) for each category
//    Severity = piecewise classification:
//      Low (0-5), Moderate (6-10), High (11-15), Very High (16-20)
//
// 2. BMI (Body Mass Index):
//    BMI = weight(kg) / height(m)²
//    Classification: Underweight (<18.5), Normal (18.5-24.9),
//    Overweight (25-29.9), Obese (≥30)
//
// 3. BMR (Mifflin-St Jeor):
//    Male:   10 × weight(kg) + 6.25 × height(cm) - 5 × age + 5
//    Female: 10 × weight(kg) + 6.25 × height(cm) - 5 × age - 161
//
// 4. TDEE: BMR × Activity Factor (1.2–1.9)

import 'package:flutter/material.dart';
import '../models/quiz_question.dart';
import '../services/notification_service.dart';

// ─── BMI / BMR Calculator ───────────────────────────────────────────────

enum Gender { male, female }

enum ActivityLevel {
  sedentary(1.2, 'ອອກກຳລັງກາຍໜ້ອຍຫຼາຍ', 'ບໍ່ມີ ຫຼື ແທບບໍ່ໄດ້ອອກກຳລັງກາຍ'),
  light(1.375, 'ອອກກຳລັງກາຍເບົາໆ', '1-3 ວັນ/ອາທິດ'),
  moderate(1.55, 'ອອກກຳລັງກາຍປານກາງ', '3-5 ວັນ/ອາທິດ'),
  active(1.725, 'ອອກກຳລັງກາຍໜັກ', '6-7 ວັນ/ອາທິດ'),
  veryActive(1.9, 'ອອກກຳລັງກາຍໜັກຫຼາຍ', '2 ຄັ້ງຕໍ່ວັນ / ອອກກຳລັງກາຍຢ່າງໜັກ');

  final double factor;
  final String label;
  final String description;
  const ActivityLevel(this.factor, this.label, this.description);
}

class BmiResult {
  final double bmi;
  BmiResult(this.bmi);

  String get classification {
    if (bmi < 18.5) return 'ນ້ຳໜັກຕ່ຳກວ່າເກນ';
    if (bmi < 25) return 'ນ້ຳໜັກປົກກະຕິ';
    if (bmi < 30) return 'ນ້ຳໜັກເກີນເກນ';
    return 'ຕຸ້ຍ/ອ້ວນ';
  }

  Color get color {
    if (bmi < 18.5) return Colors.orangeAccent;
    if (bmi < 25) return const Color(0xFF5BA89A);
    if (bmi < 30) return Colors.orange;
    return Colors.redAccent;
  }
}

class BmrResult {
  final double bmr;
  final double tdee;
  final ActivityLevel activity;

  BmrResult({required this.bmr, required this.tdee, required this.activity});

  double get maintainCalories => tdee;
  double get loseCalories => tdee - 500;
  double get gainCalories => tdee + 300;
}

class CalculatorInputs {
  final double weightKg;
  final double heightCm;
  final int age;
  final Gender gender;
  final ActivityLevel activity;

  CalculatorInputs({
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.gender,
    required this.activity,
  });

  double get heightM => heightCm / 100.0;

  BmiResult calculateBmi() {
    return BmiResult(weightKg / (heightM * heightM));
  }

  BmrResult calculateBmr() {
    const double base = 10;
    const double weightCoeff = 6.25;
    const double ageCoeff = 5;
    const int maleOffset = 5;
    const int femaleOffset = -161;

    final double raw =
        base * weightKg + weightCoeff * heightCm - ageCoeff * age;
    final double bmrValue = gender == Gender.male
        ? raw + maleOffset
        : raw + femaleOffset;
    final double tdeeValue = bmrValue * activity.factor;

    return BmrResult(bmr: bmrValue, tdee: tdeeValue, activity: activity);
  }
}

// ─── Page ───────────────────────────────────────────────────────────────

class HealthMindPage extends StatefulWidget {
  const HealthMindPage({super.key});

  @override
  State<HealthMindPage> createState() => _HealthMindPageState();
}

class _HealthMindPageState extends State<HealthMindPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFCF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEFCF8),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF7B6F9F)),
        ),
        title: const Text(
          'ສຸຂະພາບກາຍ & ຈິດໃຈ',
          style: TextStyle(
            color: Color(0xFF4A4063),
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE8927A),
          indicatorWeight: 3,
          labelColor: const Color(0xFFE8927A),
          unselectedLabelColor: const Color(0xFFC8C0D8),
          tabs: const [
            Tab(icon: Icon(Icons.psychology), text: 'ແບບທົດສອບ'),
            Tab(icon: Icon(Icons.calculate), text: 'ເຄື່ອງຄິດໄລ່'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_QuizTab(), _CalculatorTab()],
      ),
    );
  }
}

// ─── Quiz Tab ───────────────────────────────────────────────────────────

class _QuizTab extends StatefulWidget {
  const _QuizTab();

  @override
  State<_QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<_QuizTab> {
  final List<int> _answers = List.filled(quizQuestions.length, -1);
  int _currentIndex = 0;
  QuizResult? _result;

  bool get _isComplete => _answers.every((a) => a >= 0);

  void _answer(int value) {
    setState(() {
      _answers[_currentIndex] = value;
      if (_currentIndex < quizQuestions.length - 1) {
        _currentIndex++;
      }
    });
  }

  void _goBack() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }

  void _submit() {
    setState(() => _result = calculateQuizResult(_answers));
    notificationService.showQuizReminder();
  }

  void _reset() {
    setState(() {
      for (int i = 0; i < _answers.length; i++) {
        _answers[i] = -1;
      }
      _currentIndex = 0;
      _result = null;
    });
  }

  Map<QuizCategory, ({int score, String level, String recommendation})>
  _buildCategoryData() {
    if (_result == null) return {};
    return {
      QuizCategory.stress: (
        score: _result!.stressScore,
        level: _result!.stressLevel,
        recommendation: _result!.stressRecommendation,
      ),
      QuizCategory.anxiety: (
        score: _result!.anxietyScore,
        level: _result!.anxietyLevel,
        recommendation: _result!.anxietyRecommendation,
      ),
      QuizCategory.depression: (
        score: _result!.depressionScore,
        level: _result!.depressionLevel,
        recommendation: _result!.depressionRecommendation,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) return _buildResults();

    final question = quizQuestions[_currentIndex];
    final progress = _answers.where((a) => a >= 0).length;
    final chosen = _answers[_currentIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress / quizQuestions.length,
            backgroundColor: const Color(0xFFF0E8F8),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9B6FBF)),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),
          Text(
            '$progress / ${quizQuestions.length}',
            style: const TextStyle(color: Color(0xFFA098B8), fontSize: 13),
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9B6FBF).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    question.category == QuizCategory.stress
                        ? 'ຄວາມຕຶງຄຽດ'
                        : question.category == QuizCategory.anxiety
                        ? 'ความວິຕົກກັງວົນ'
                        : 'ພາວະຊຶມເສົ້າ',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7B4FA3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  question.text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3D3555),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 24),
                ...List.generate(5, (i) {
                  final labels = [
                    'ບໍ່ເຄີຍ',
                    'ດົນໆຄັ້ງ',
                    'ບາງຄັ້ງ',
                    'ເລື້ອຍໆ',
                    'ຕະຫຼອດ/ຫຼາຍທີ່ສຸດ',
                  ];
                  final isSelected = chosen == i;
                  return GestureDetector(
                    onTap: () => _answer(i),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF3E8FF)
                            : const Color(0xFFF8F6FC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF9B6FBF)
                              : const Color(0xFFECE6F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? const Color(0xFF7B4FA3)
                                  : const Color(0xFFC8C0D8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 15,
                              color: isSelected
                                  ? const Color(0xFF3D3555)
                                  : const Color(0xFFA098B8),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF9B6FBF),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isComplete)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B6FBF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'ເບິ່ງຜົນການທົດສອບ',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          else
            Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _goBack,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF9B6FBF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFD4C8E0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('ກັບຄືນ'),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B6FBF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'ຕອບແລ້ວ: ${chosen >= 0 ? '${chosen + 1}/5' : 'ຍັງບໍ່ໄດ້ຕອບ'}',
                        style: const TextStyle(
                          color: Color(0xFF7B4FA3),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFECE6F0)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFECE6F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9B6FBF).withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF9B6FBF),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'ກ່ຽວກັບ ແລະ ວິທີໃຊ້ງານ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B4FA3),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '💡 ກ່ຽວກັບ:\nແບບປະເມີນສຸຂະພາບຈິດເບື້ອງຕົ້ນໂດຍອີງຕາມເກນ DASS (Depression, Anxiety, and Stress Scale) ເພື່ອວັດແທກລະດັບຄວາມຕຶງຄຽດ, ຄວາມວິຕົກກັງວົນ ແລະ ພາວະຊຶມເສົ້າ.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B6580),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '📱 ວິທີໃຊ້ງານ:\n1. ຕອບຄຳຖາມທັງ 15 ຂໍ້ ຕາມຄວາມຮູ້ສຶກຂອງທ່ານໃນໄລຍະຜ່ານມາ (ແຕ່ ບໍ່ເຄີຍ ຫາ ຕະຫຼອດ/ຫຼາຍທີ່ສຸດ).\n2. ເມື່ອຕອບຄົບແລ້ວ, ແຕະປຸ່ມ "ເບິ່ງຜົນການທົດສອບ" ເພື່ອເບິ່ງຄະແນນ ແລະ ຄຳແນະນຳໃນການເບິ່ງແຍງສຸຂະພາບຈິດ.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B6580),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final data = _buildCategoryData();
    final categoryColors = {
      QuizCategory.stress: const Color(0xFFE8927A),
      QuizCategory.anxiety: const Color(0xFF9B6FBF),
      QuizCategory.depression: const Color(0xFF5BA89A),
    };
    final categoryIcons = {
      QuizCategory.stress: Icons.bolt,
      QuizCategory.anxiety: Icons.favorite_border,
      QuizCategory.depression: Icons.wb_cloudy,
    };
    final categoryLabels = {
      QuizCategory.stress: 'ຄວາມຕຶງຄຽດ',
      QuizCategory.anxiety: 'ຄວາມວິຕົກກັງວົນ',
      QuizCategory.depression: 'ພາວະຊຶມເສົ້າ',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'ຜົນການທົດສອບຂອງທ່ານ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A4063),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'ຄະແນນລວມ: ${_result!.totalScore} / 60',
              style: const TextStyle(fontSize: 14, color: Color(0xFFA098B8)),
            ),
          ),
          const SizedBox(height: 24),
          ...QuizCategory.values.map((cat) {
            final d = data[cat]!;
            final color = categoryColors[cat]!;
            final maxScore = 20;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(categoryIcons[cat], color: color, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        categoryLabels[cat]!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${d.score} / $maxScore',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: d.score / maxScore,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      d.level,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    d.recommendation,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B6580),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6FC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFECE6F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFF9B6FBF),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'ເກນການຄິດໄລ່ຄະແນນ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A4063),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'ແຕ່ລະໝວດ (ຄວາມຕຶງຄຽດ, ຄວາມວິຕົກກັງວົນ, ພາວະຊຶມເສົ້າ) ລວມມີ 5 ຄຳຖາມ, ຄະແນນແຕ່ລະຂໍ້ແມ່ນ 0-4. ຊ່ວງຄະແນນລວມ: 0-20 ຄະແນນຕໍ່ໝວດ.\n\nເກນລະດັບຄວາມຮຸນແຮງ:\n• 0–5  → ຕ່ຳ\n• 6–10 → ປານກາງ\n• 11–15 → ສູງ\n• 16–20 → ສູງຫຼາຍ',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B6580),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF9B6FBF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFD4C8E0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('ເຮັດແບບທົດສອບຄືນໃໝ່'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Calculator Tab ─────────────────────────────────────────────────────

class _CalculatorTab extends StatefulWidget {
  const _CalculatorTab();

  @override
  State<_CalculatorTab> createState() => _CalculatorTabState();
}

class _CalculatorTabState extends State<_CalculatorTab> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  Gender _gender = Gender.male;
  ActivityLevel _activity = ActivityLevel.sedentary;

  BmiResult? _bmi;
  BmrResult? _bmr;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final weight = double.tryParse(_weightCtrl.text);
    final height = double.tryParse(_heightCtrl.text);
    final age = int.tryParse(_ageCtrl.text);

    if (weight == null || height == null || age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ກະລຸນາປ້ອນຂໍ້ມູນໃຫ້ຄົບຖ້ວນ ແລະ ຖືກຕ້ອງ')),
      );
      return;
    }

    final inputs = CalculatorInputs(
      weightKg: weight,
      heightCm: height,
      age: age,
      gender: _gender,
      activity: _activity,
    );

    setState(() {
      _bmi = inputs.calculateBmi();
      _bmr = inputs.calculateBmr();
    });
  }

  void _clear() {
    _weightCtrl.clear();
    _heightCtrl.clear();
    _ageCtrl.clear();
    setState(() {
      _bmi = null;
      _bmr = null;
      _gender = Gender.male;
      _activity = ActivityLevel.sedentary;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gender
          const Text(
            'ເພດ',
            style: TextStyle(fontSize: 13, color: Color(0xFFA098B8)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _GenderButton(
                  label: 'ເພດຊາຍ',
                  icon: Icons.male,
                  selected: _gender == Gender.male,
                  onTap: () => setState(() => _gender = Gender.male),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GenderButton(
                  label: 'ເພດຍິງ',
                  icon: Icons.female,
                  selected: _gender == Gender.female,
                  onTap: () => setState(() => _gender = Gender.female),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Inputs
          _InputRow(controller: _weightCtrl, label: 'ນ້ຳໜັກ', suffix: 'kg'),
          const SizedBox(height: 12),
          _InputRow(controller: _heightCtrl, label: 'ສ່ວນສູງ', suffix: 'cm'),
          const SizedBox(height: 12),
          _InputRow(controller: _ageCtrl, label: 'ອາຍຸ', suffix: 'ປີ'),
          const SizedBox(height: 20),

          // Activity
          const Text(
            'ລະດັບການເຮັດກິດຈະກຳ',
            style: TextStyle(fontSize: 13, color: Color(0xFFA098B8)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFECE6F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ActivityLevel>(
                value: _activity,
                isExpanded: true,
                icon: const Icon(Icons.expand_more, color: Color(0xFFC8C0D8)),
                style: const TextStyle(fontSize: 13, color: Color(0xFF3D3555)),
                items: ActivityLevel.values.map((a) {
                  return DropdownMenuItem(
                    value: a,
                    child: Text(
                      '${a.label} — ${a.description}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF3D3555),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _activity = v!),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Calculate
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8927A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('ຄິດໄລ່', style: TextStyle(fontSize: 16)),
            ),
          ),

          // Results
          if (_bmi != null && _bmr != null) ...[
            const SizedBox(height: 24),
            _buildResults(),
          ],
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFECE6F0)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFECE6F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE8927A).withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFFE8927A),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'ກ່ຽວກັບ ແລະ ວິທີໃຊ້ງານ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFCC725A),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '💡 ກ່ຽວກັບ:\nເຄື່ອງມືຄຳນວນດັດສະນີມວນກາຍ (BMI), ອັດຕາການເຜົາຜານພະລັງງານພື້ນຖານ (BMR) ແລະ ພະລັງງານທີ່ຕ້ອງການຕໍ່ວັນ (TDEE) ໂດຍໃຊ້ສູດ Mifflin-St Jeor ທີ່ໄດ້ມາດຕະຖານ.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B6580),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '📱 ວິທີໃຊ້ງານ:\n1. ເລືອກເພດ, ປ້ອນນ້ຳໜັກ (kg), ສ່ວນສູງ (cm) ແລະ ອາຍຸ (ປີ).\n2. ເລືອກລະດັບການເຮັດກິດຈະກຳຈາກລາຍການຕົວເລືອກ.\n3. ແຕະປຸ່ມ "ຄິດໄລ່" ເພື່ອຮັບຄຳແນະນຳເປົ້າໝາຍແຄລໍຣີ ແລະ ການຄວບຄຸມນ້ຳໜັກ.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B6580),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      children: [
        // BMI Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE8927A).withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.monitor_weight,
                      color: Color(0xFFCC725A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'BMI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A4063),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _bmi!.bmi.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4063),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_bmi!.bmi.clamp(12, 40) - 12) / 28,
                  backgroundColor: const Color(0xFFF0E8F8),
                  valueColor: AlwaysStoppedAnimation<Color>(_bmi!.color),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _bmi!.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _bmi!.classification,
                      style: TextStyle(
                        fontSize: 13,
                        color: _bmi!.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'ເກນປົກກະຕິ: 18.5–24.9',
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFFA098B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // BMR + TDEE Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE8927A).withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Color(0xFFE8927A),
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ຄ່າ BMR ແລະ TDEE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A4063),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _CalRow(
                label: 'ອັດຕາການເຜົາຜານພະລັງງານຂັ້ນພື້ນຖານ (BMR)',
                value: '${_bmr!.bmr.toStringAsFixed(0)} kcal/ວັນ',
              ),
              const SizedBox(height: 8),
              _CalRow(
                label: 'ຕົວຄູນການເຮັດກິດຈະກຳ',
                value: '× ${_bmr!.activity.factor}',
              ),
              const SizedBox(height: 8),
              _CalRow(
                label: 'ພະລັງງານທີ່ໃຊ້ທັງໝົດຕໍ່ວັນ (TDEE)',
                value: '${_bmr!.tdee.toStringAsFixed(0)} kcal/ວັນ',
                isBold: true,
              ),
              const Divider(height: 20),
              _CalRow(
                label: 'ຮັກສານ້ຳໜັກ',
                value: '${_bmr!.maintainCalories.toStringAsFixed(0)} kcal',
                color: const Color(0xFF5BA89A),
              ),
              const SizedBox(height: 6),
              _CalRow(
                label: 'ຫຼຸດນ້ຳໜັກ ( −500 )',
                value: '${_bmr!.loseCalories.toStringAsFixed(0)} kcal',
                color: const Color(0xFFE8927A),
              ),
              const SizedBox(height: 6),
              _CalRow(
                label: 'ເພີ່ມນ້ຳໜັກ ( +300 )',
                value: '${_bmr!.gainCalories.toStringAsFixed(0)} kcal',
                color: const Color(0xFF9B6FBF),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Algorithm Reference
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F6FC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECE6F0)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.code, color: Color(0xFFE8927A), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'ສູດທີ່ໃຊ້ໃນການຄິດໄລ່',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A4063),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'BMI = ນ້ຳໜັກ(kg) / ສ່ວນສູງ(m)²\n\n'
                'BMR (ສູດ Mifflin-St Jeor):\n'
                '• ເພດຊາຍ: 10 × ນ້ຳໜັກ(kg) + 6.25 × ສ່ວນສູງ(cm) − 5 × ອາຍຸ + 5\n'
                '• ເພດຍິງ: 10 × ນ້ຳໜັກ(kg) + 6.25 × ສ່ວນສູງ(cm) − 5 × ອາຍຸ − 161\n\n'
                'TDEE = BMR × ຕົວຄູນການເຮັດກິດຈະກຳ\n'
                '• ອອກກຳລັງກາຍໜ້ອຍຫຼາຍ ×1.2 • ອອກກຳລັງກາຍເບົາໆ ×1.375\n'
                '• ອອກກຳລັງກາຍປານກາງ ×1.55 • ອອກກຳລັງກາຍໜັກ ×1.725\n'
                '• ອອກກຳລັງກາຍໜັກຫຼາຍ ×1.9',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B6580),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Clear
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _clear,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE8927A),
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFFADBC4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('ລ້າງຂໍ້ມູນທັງໝົດ'),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────

class _GenderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF0E8) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFE8927A) : const Color(0xFFECE6F0),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFFE8927A)
                  : const Color(0xFFC8C0D8),
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: selected
                    ? const Color(0xFF3D3555)
                    : const Color(0xFFA098B8),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;

  const _InputRow({
    required this.controller,
    required this.label,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECE6F0)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFA098B8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF3D3555),
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Text(
            suffix,
            style: const TextStyle(fontSize: 13, color: Color(0xFFC8C0D8)),
          ),
        ],
      ),
    );
  }
}

class _CalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  const _CalRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? const Color(0xFF4A4063);
    return Row(
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              color: const Color(0xFF6B6580),
              fontWeight: isBold ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            color: textColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
