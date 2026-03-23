import 'package:audioplayers/audioplayers.dart';
import 'app_settings.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  static final AudioPlayer _bgmPlayer = AudioPlayer(); // مشغل خاص بالموسيقى في الخلفية

  // Initialize and preload if needed
  static Future<void> init() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  static Future<void> updateBgmState() async {
    try {
      if (AppSettings.ttsEnabled) {
        await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
        await _bgmPlayer.play(AssetSource('sounds/muisc.mp3'), volume: 0.15); // مستوى الصوت هادئ 
      } else {
        await _bgmPlayer.pause();
      }
    } catch (e) {
      print('BGM Error: $e');
    }
  }

  static Future<void> playCorrect() async {
    if (!AppSettings.ttsEnabled) return;
    await _player.play(AssetSource('sounds/correct.mp3'));
  }

  static Future<void> playWrong() async {
    if (!AppSettings.ttsEnabled) return;
    await _player.play(AssetSource('sounds/wrong.mp3'));
  }

  static Future<void> playWin() async {
    if (!AppSettings.ttsEnabled) return;
    await _player.play(AssetSource('sounds/win.mp3'));
  }

  static Future<void> playClick() async {
    try {
      if (!AppSettings.ttsEnabled) return;
      await _player.stop();
      await _player.play(AssetSource('sounds/click.mp3'));
    } catch (e) {
      print('Audio Error: $e');
    }
  }
}
