class ApiConfig {
  static const String edamamAppId =
      String.fromEnvironment('EDAMAM_APP_ID', defaultValue: '');
  static const String edamamAppKey =
      String.fromEnvironment('EDAMAM_APP_KEY', defaultValue: '');

  // ໃສ່ Gemini API Key ຜ່ານ --dart-define ຕອນຮັນແອັບ:
  //   flutter run --dart-define=GEMINI_API_KEY=AIzaSy...
  // ໄປເອົາ API Key ໄດ້ທີ່ https://aistudio.google.com/apikey
  static const String geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
}
