import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum VoiceCommand {
  apod,
  iss,
  dashboard,
  weather,
  health,
  emergency,
  recipe,
  country,
  worldtime,
  currency,
  earthquake,
  portfolio,
  smartlens,
  recycle,
  airquality,
  disease,
  accessibility,
  safeway,
  magnifier,
  emergencyhub,
  stop,
  unknown,
}

class VoiceService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _ttsReady = false;
  bool _sttAvailable = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastRecognized = '';

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get sttAvailable => _sttAvailable;
  bool get ttsAvailable => _ttsReady;
  String get lastRecognized => _lastRecognized;

  static const _commandMap = {
    'go to picture': VoiceCommand.apod,
    'open picture': VoiceCommand.apod,
    'go to apod': VoiceCommand.apod,
    'open apod': VoiceCommand.apod,
    'picture': VoiceCommand.apod,
    'apod': VoiceCommand.apod,
    'go to space': VoiceCommand.iss,
    'open space': VoiceCommand.iss,
    'go to iss': VoiceCommand.iss,
    'open iss': VoiceCommand.iss,
    'iss': VoiceCommand.iss,
    'space station': VoiceCommand.iss,
    'go to dashboard': VoiceCommand.dashboard,
    'open dashboard': VoiceCommand.dashboard,
    'dashboard': VoiceCommand.dashboard,
    'global': VoiceCommand.dashboard,
    'go to weather': VoiceCommand.weather,
    'open weather': VoiceCommand.weather,
    'weather': VoiceCommand.weather,
    'go to health': VoiceCommand.health,
    'open health': VoiceCommand.health,
    'health': VoiceCommand.health,
    'mind': VoiceCommand.health,
    'go to mind': VoiceCommand.health,
    'go to emergency': VoiceCommand.emergency,
    'open emergency': VoiceCommand.emergency,
    'emergency': VoiceCommand.emergency,
    'help': VoiceCommand.emergency,
    'first aid': VoiceCommand.emergency,
    'sos': VoiceCommand.emergency,
    'go to recipe': VoiceCommand.recipe,
    'open recipe': VoiceCommand.recipe,
    'recipe': VoiceCommand.recipe,
    'food': VoiceCommand.recipe,
    'cook': VoiceCommand.recipe,
    'go to lens': VoiceCommand.smartlens,
    'open lens': VoiceCommand.smartlens,
    'smart lens': VoiceCommand.smartlens,
    'scan': VoiceCommand.smartlens,
    'camera': VoiceCommand.smartlens,
    'go to recycle': VoiceCommand.recycle,
    'open recycle': VoiceCommand.recycle,
    'recycle': VoiceCommand.recycle,
    'recycling': VoiceCommand.recycle,
    'waste': VoiceCommand.recycle,
    'trash': VoiceCommand.recycle,
    'green': VoiceCommand.recycle,
    'go to country': VoiceCommand.country,
    'open country': VoiceCommand.country,
    'country': VoiceCommand.country,
    'go to map': VoiceCommand.country,
    'world': VoiceCommand.country,
    'go to world clock': VoiceCommand.worldtime,
    'go to worldtime': VoiceCommand.worldtime,
    'open world clock': VoiceCommand.worldtime,
    'world clock': VoiceCommand.worldtime,
    'worldtime': VoiceCommand.worldtime,
    'time zone': VoiceCommand.worldtime,
    'go to currency': VoiceCommand.currency,
    'open currency': VoiceCommand.currency,
    'currency': VoiceCommand.currency,
    'money': VoiceCommand.currency,
    'convert': VoiceCommand.currency,
    'exchange': VoiceCommand.currency,
    'go to earthquake': VoiceCommand.earthquake,
    'open earthquake': VoiceCommand.earthquake,
    'earthquake': VoiceCommand.earthquake,
    'seismic': VoiceCommand.earthquake,
    'alert': VoiceCommand.earthquake,
    'go to portfolio': VoiceCommand.portfolio,
    'open portfolio': VoiceCommand.portfolio,
    'portfolio': VoiceCommand.portfolio,
    'stock': VoiceCommand.portfolio,
    'crypto': VoiceCommand.portfolio,
    'investment': VoiceCommand.portfolio,
    'go to air quality': VoiceCommand.airquality,
    'open air quality': VoiceCommand.airquality,
    'air quality': VoiceCommand.airquality,
    'air': VoiceCommand.airquality,
    'pollution': VoiceCommand.airquality,
    'aqi': VoiceCommand.airquality,
    'pm': VoiceCommand.airquality,
    'go to disease': VoiceCommand.disease,
    'open disease': VoiceCommand.disease,
    'disease tracker': VoiceCommand.disease,
    'disease': VoiceCommand.disease,
    'vaccine': VoiceCommand.disease,
    'covid': VoiceCommand.disease,
    'travel health': VoiceCommand.disease,
    'go to accessibility': VoiceCommand.accessibility,
    'open accessibility': VoiceCommand.accessibility,
    'accessibility': VoiceCommand.accessibility,
    'high contrast': VoiceCommand.accessibility,
    'screen reader': VoiceCommand.accessibility,
    'go to safe way': VoiceCommand.safeway,
    'open safe way': VoiceCommand.safeway,
    'safe way': VoiceCommand.safeway,
    'navigator': VoiceCommand.safeway,
    'gps': VoiceCommand.safeway,
    'go to magnifier': VoiceCommand.magnifier,
    'open magnifier': VoiceCommand.magnifier,
    'magnifier': VoiceCommand.magnifier,
    'zoom': VoiceCommand.magnifier,
    'go to emergency hub': VoiceCommand.emergencyhub,
    'open emergency hub': VoiceCommand.emergencyhub,
    'emergency hub': VoiceCommand.emergencyhub,
    'help me': VoiceCommand.emergencyhub,
    'stop': VoiceCommand.stop,
    'stop listening': VoiceCommand.stop,
  };

  Future<void> init() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      _ttsReady = true;
    } on MissingPluginException {
      _ttsReady = false;
    }

    try {
      _sttAvailable = await _stt.initialize();
    } on MissingPluginException {
      _sttAvailable = false;
    }
    notifyListeners();
  }

  VoiceCommand parseCommand(String text) {
    final normalized = text.trim().toLowerCase();
    if (_commandMap.containsKey(normalized)) return _commandMap[normalized]!;

    for (final entry in _commandMap.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }
    return VoiceCommand.unknown;
  }

  Future<void> speak(String text) async {
    if (!_ttsReady) return;
    _isSpeaking = true;
    notifyListeners();
    try {
      await _tts.speak(text);
    } on MissingPluginException {
      _ttsReady = false;
    }
    _isSpeaking = false;
    notifyListeners();
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } on MissingPluginException {
      _ttsReady = false;
    }
    _isSpeaking = false;
    notifyListeners();
  }

  Future<bool> startListening({
    required void Function(VoiceCommand command) onCommand,
  }) async {
    if (!_sttAvailable) return false;
    if (_isListening) return true;

    _isListening = true;
    notifyListeners();

    await _stt.listen(
      onResult: (result) {
        _lastRecognized = result.recognizedWords;
        notifyListeners();

        final command = parseCommand(result.recognizedWords);
        if (command != VoiceCommand.unknown) {
          stopListening();
          onCommand(command);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
        cancelOnError: true,
      ),
    );
    return true;
  }

  Future<void> stopListening() async {
    await _stt.stop();
    _isListening = false;
    notifyListeners();
  }

  Future<String> buildBriefing() async {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';

    return '$greeting! Welcome to Omni Nexus. '
        'You can explore space imagery, track the International Space Station, '
        'check the weather forecast, assess your mental well-being, '
        'review disease and vaccine signals for travel, '
        'adjust accessibility options, '
        'find recipes from ingredients you have at home, '
        'scan ingredients with your camera using artificial intelligence, '
        'explore country information, check world clocks, '
        'convert currencies, and stay informed about recent earthquakes. '
        'Try saying "Go to Space" to track the ISS, '
        '"Go to Weather" for the forecast, '
        '"Go to Health" for the wellness tools, '
        '"Go to Recipe" to find recipes, '
        '"Go to Lens" to scan ingredients with AI, '
        '"Go to Country" for country insights, '
        '"Go to World Clock" for time zones, '
        '"Go to Currency" to convert money, '
        '"Go to Earthquake" for seismic activity, '
        '"Go to Disease" for outbreak and vaccine tracking, '
        '"Go to Accessibility" for high contrast and visual alerts, '
        '"Go to Portfolio" to track stocks and crypto, '
        'or "Go to Apod" for today\'s astronomy picture. '
        'Say "Go to Dashboard" for a global statistics overview with charts and audio report. '
        'For emergencies, say "Emergency" for first aid guides, SOS, and medicine reminders. '
        'Say "Go to Recycle" for the waste sorting guide, AI waste scanner, and Green Points rewards. '
        'Say "Go to Air Quality" for the air pollution index and personalized health recommendations.';
  }

  @override
  void dispose() {
    _tts.stop();
    _stt.stop();
    super.dispose();
  }
}

final voiceService = VoiceService();
