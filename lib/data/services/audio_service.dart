import 'package:audioplayers/audioplayers.dart';
import 'app_settings.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  // Initialize and preload if needed
  static Future<void> init() async {
    // We can set default settings here if required
  }

  static Future<void> playCorrect() async {
    if (!AppSettings.ttsEnabled) return; // Optional: Tie it to general sound settings
    await _player.play(AssetSource('sounds/correct.wav'));
  }

  static Future<void> playWrong() async {
    if (!AppSettings.ttsEnabled) return;
    await _player.play(AssetSource('sounds/wrong.wav'));
  }

  static Future<void> playWin() async {
    if (!AppSettings.ttsEnabled) return;
    await _player.play(AssetSource('sounds/win.wav'));
  }

  static Future<void> playClick() async {
    if (!AppSettings.ttsEnabled) return;
    await _player.play(AssetSource('sounds/click.wav'));
  }
}
