enum QuizCategory { stress, anxiety, depression }

class QuizQuestion {
  final String text;
  final QuizCategory category;

  const QuizQuestion({required this.text, required this.category});
}

class QuizResult {
  final int stressScore;
  final int anxietyScore;
  final int depressionScore;

  const QuizResult({
    required this.stressScore,
    required this.anxietyScore,
    required this.depressionScore,
  });

  int get totalScore => stressScore + anxietyScore + depressionScore;
  double get averagePerCategory => totalScore / 3.0;

  String get stressLevel {
    if (stressScore <= 5) return 'ຕ່ຳ';
    if (stressScore <= 10) return 'ປານກາງ';
    if (stressScore <= 15) return 'ສູງ';
    return 'ສູງຫຼາຍ';
  }

  String get anxietyLevel {
    if (anxietyScore <= 4) return 'ຕ່ຳ';
    if (anxietyScore <= 8) return 'ປານກາງ';
    if (anxietyScore <= 12) return 'ສູງ';
    return 'ສູງຫຼາຍ';
  }

  String get depressionLevel {
    if (depressionScore <= 5) return 'ຕ່ຳ';
    if (depressionScore <= 10) return 'ປານກາງ';
    if (depressionScore <= 15) return 'ສູງ';
    return 'ສູງຫຼາຍ';
  }

  static const _recommendations = {
    'ຕ່ຳ': 'ຜົນການທົດສອບສະແດງໃຫ້ເຫັນວ່າມີອາການໜ້ອຍທີ່ສຸດ. ຄວນຮັກສາພຶດຕິກຳການເບິ່ງແຍງຕົນເອງທີ່ດີນີ້ຕໍ່ໄປ.',
    'ປານກາງ': 'ລອງປຶກສາ ຫຼື ລົມກັບຄົນທີ່ທ່ານໄວ້ໃຈ. ການອອກກຳລັງກາຍເບົາໆ ແລະ ການຝຶກສະມາທິສາມາດຊ່ວຍໄດ້.',
    'ສູງ': 'ພວກເຮົາແນະນຳໃຫ້ປຶກສາກັບຜູ້ຊ່ຽວຊານດ້ານສຸຂະພາບຈິດເພື່ອຮັບຄຳແນະນຳທີ່ເໝາະສົມ.',
    'ສູງຫຼາຍ': 'ກະລຸນາຂໍຄວາມຊ່ວຍເຫຼືອຈາກຜູ້ຊ່ຽວຊານດ້ານສຸຂະພາບຈິດ ຫຼື ສາຍດ່ວນຊ່ວຍເຫຼືອທັນທີ.',
  };

  String get stressRecommendation => _recommendations[stressLevel]!;
  String get anxietyRecommendation => _recommendations[anxietyLevel]!;
  String get depressionRecommendation => _recommendations[depressionLevel]!;
}

final List<QuizQuestion> quizQuestions = [
  // Stress (5 questions)
  QuizQuestion(
    text: 'ທ່ານຮູ້ສຶກຮັບພາລະໜັກໜ່ວງເກີນໄປຈາກໜ້າທີ່ຮັບຜິດຊອບຂອງທ່ານເລື້ອຍປານໃດ?',
    category: QuizCategory.stress,
  ),
  QuizQuestion(
    text: 'ທ່ານຮູ້ສຶກຜ່ອນຄາຍໄດ້ຍາກເລື້ອຍປານໃດ?',
    category: QuizCategory.stress,
  ),
  QuizQuestion(
    text: 'ທ່ານຮູ້ສຶກຫງຸດຫງິດ ຫຼື ອາລົມຮ້ອນງ່າຍເລື້ອຍປານໃດ?',
    category: QuizCategory.stress,
  ),
  QuizQuestion(
    text: 'ທ່ານມີບັນຫາໃນການຜ່ອນຄາຍຄວາມຕຶງຄຽດໃນທ້າຍມື້ເລື້ອຍປານໃດ?',
    category: QuizCategory.stress,
  ),
  QuizQuestion(
    text: 'ທ່ານຮູ້ສຶກວ່າຖືກຄາດຫວັງ ຫຼື ຮຽກຮ້ອງຈາກທ່ານຫຼາຍເກີນໄປເລື້ອຍປານໃດ?',
    category: QuizCategory.stress,
  ),
  // Anxiety (5 questions)
  QuizQuestion(
    text: 'ທ່ານຮູ້ສຶກປະໝ່າ ຫຼື ວິຕົກກັງວົນເລື້ອຍປານໃດ?',
    category: QuizCategory.anxiety,
  ),
  QuizQuestion(
    text: 'ທ່ານມີອາການຫົວໃຈເຕັ້ນໄວ ຫຼື ຫາຍໃຈຝືດເລື້ອຍປານໃດ?',
    category: QuizCategory.anxiety,
  ),
  QuizQuestion(
    text: 'ທ່ານກັງວົນກ່ຽວກັບສະຖານະການຕ່າງໆ ທີ່ອາດຈະຜິດພາດເລື້ອຍປານໃດ?',
    category: QuizCategory.anxiety,
  ),
  QuizQuestion(
    text: 'ທ່ານຮູ້ສຶກຕົວສັ່ນ ຫຼື ມືສັ່ນໂດຍບໍ່ມີເຫດຜົນຈະແຈ້ງເລື້ອຍປານໃດ?',
    category: QuizCategory.anxiety,
  ),
  QuizQuestion(
    text: 'ທ່ານຫຼີກລ່ຽງສະຖານະການບາງຢ່າງຍ້ອນຄວາມຢ້ານ ຫຼື ຄວາມກັງວົນເລື້ອຍປານໃດ?',
    category: QuizCategory.anxiety,
  ),
  // Depression (5 questions)
  QuizQuestion(
    text: 'ທ່ານຮູ້ສຶກທໍ້ແທ້, ຊຶມເສົ້າ ຫຼື ສິ້ນຫວັງເລື້ອຍປານໃດ?',
    category: QuizCategory.depression,
  ),
  QuizQuestion(
    text: 'ທ່ານເສຍຄວາມສົນໃຈໃນສິ່ງທີ່ເຄີຍມັກເຮັດເລື້ອຍປານໃດ?',
    category: QuizCategory.depression,
  ),
  QuizQuestion(
    text: 'ທ່ານຮູ້ສຶກອິດເມື່ອຍ ຫຼື ຂາດພະລັງງານເລື້ອຍປານໃດ?',
    category: QuizCategory.depression,
  ),
  QuizQuestion(
    text: 'ທ່ານຮູ້ສຶກວ່າຕົນເອງບໍ່ມີຄ່າ ຫຼື ຮູ້ສຶກຜິດກ່ຽວກັບສິ່ງຕ່າງໆ ເລື້ອຍປານໃດ?',
    category: QuizCategory.depression,
  ),
  QuizQuestion(
    text: 'ທ່ານມີບັນຫາໃນການຕັ້ງສະມາທິ ຫຼື ການຕັດສິນໃຈເລື້ອຍປານໃດ?',
    category: QuizCategory.depression,
  ),
];

QuizResult calculateQuizResult(List<int> answers) {
  int stress = 0, anxiety = 0, depression = 0;
  for (int i = 0; i < answers.length; i++) {
    final category = quizQuestions[i].category;
    switch (category) {
      case QuizCategory.stress:
        stress += answers[i];
      case QuizCategory.anxiety:
        anxiety += answers[i];
      case QuizCategory.depression:
        depression += answers[i];
    }
  }
  return QuizResult(stressScore: stress, anxietyScore: anxiety, depressionScore: depression);
}
