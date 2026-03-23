import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'app_settings.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class TTSService {
  static const String _apiBase =
      'https://major.g6.cz/sp-c3/api.php?action=tts';
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> speak(String text) async {
    if (text.isEmpty) return;
    if (!AppSettings.ttsEnabled) return; // Respect user setting

    if (kIsWeb) {
      // Use built-in browser Web Speech API — no CORS issues
      _speakWithBrowserTTS(text);
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

  // Uses browser's native SpeechSynthesis — works on Chrome/Edge/Safari
  static void _speakWithBrowserTTS(String text) {
    try {
      js.context.callMethod('eval', [
        '''
        (function() {
          window.speechSynthesis.cancel();
          var u = new SpeechSynthesisUtterance(${jsonEncode(text)});
          u.lang = 'ar-IQ';
          u.rate = 0.9;
          u.pitch = 1.0;
          window.speechSynthesis.speak(u);
        })();
        '''
      ]);
    } catch (e) {
      print('Browser TTS Error: $e');
    }
  }

  static void stop() {
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', ['window.speechSynthesis.cancel();']);
      } catch (_) {}
      return;
    }
    _player.stop();
  }
}
