import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const String _ttsEnabledKey = 'tts_enabled';

  // Default: TTS is enabled
  static bool _ttsEnabled = true;

  static bool get ttsEnabled => _ttsEnabled;

  /// Load all settings from SharedPreferences (call once at startup if needed)
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _ttsEnabled = prefs.getBool(_ttsEnabledKey) ?? true;
  }

  /// Toggle TTS and persist
  static Future<void> setTtsEnabled(bool value) async {
    _ttsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ttsEnabledKey, value);
  }
}
