import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'app_settings.dart';
import 'tts_web_adapter.dart';

class TTSService {
  static const String _apiBase =
      'https://major.g6.cz/sp-c3/api.php?action=tts';
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> speak(String text) async {
    if (text.isEmpty) return;
    if (!AppSettings.ttsEnabled) return; // Respect user setting

    if (kIsWeb) {
      // Use built-in browser Web Speech API — no CORS issues
      speakWithBrowserTTS(text);
      return;
    }

    // Native (Android/iOS) — use external TTS API
    final String targetUrl =
        '$_apiBase&text=${Uri.encodeComponent(text)}&voice_id=tc_685ca2dcfa58f44bdbe60d65&emotion=normal';

    try {
      final response = await http.get(Uri.parse(targetUrl), headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      }).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['url'] != null) {
          final String audioUrl = data['url'] as String;
          print('Playing TTS: $audioUrl');
          await _player.stop();
          await _player.play(UrlSource(audioUrl));
        }
      }
    } catch (e) {
      print('TTS Service Error: $e');
    }
  }

  static void stop() {
    if (kIsWeb) {
      stopWithBrowserTTS();
      return;
    }
    _player.stop();
  }
}
