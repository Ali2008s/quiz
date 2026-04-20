import 'package:audioplayers/audioplayers.dart';
import 'app_settings.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  static final AudioPlayer _bgmPlayer =
      AudioPlayer(); // مشغل خاص بالموسيقى في الخلفية
  static bool _bgmListenerAdded = false;

  // Initialize and preload if needed
  static Future<void> init() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    
    // حل احتياطي للأجهزة التي لا تدعم التكرار التلقائي بشكل صحيح
    if (!_bgmListenerAdded) {
      _bgmPlayer.onPlayerComplete.listen((_) {
        if (AppSettings.ttsEnabled) {
          _bgmPlayer.play(AssetSource('sounds/music.mp3'), volume: 0.15);
        }
      });
      _bgmListenerAdded = true;
    }
  }

  static Future<void> updateBgmState() async {
    try {
      if (AppSettings.ttsEnabled) {
        if (_bgmPlayer.state != PlayerState.playing) {
          await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
          await _bgmPlayer.play(AssetSource('sounds/music.mp3'),
              volume: 0.15);
        }
      } else {
        await _bgmPlayer.pause();
      }
    } catch (e) {
      print('BGM Error: $e');
    }
  }

  /// Temporarily pause BGM (e.g. inside a game room)
  static Future<void> pauseBgm() async {
    try { await _bgmPlayer.pause(); } catch (_) {}
  }

  /// Resume BGM if setting allows
  static Future<void> resumeBgm() async {
    try {
      if (AppSettings.ttsEnabled) {
        if (_bgmPlayer.state != PlayerState.playing) {
          await _bgmPlayer.play(AssetSource('sounds/music.mp3'), volume: 0.15);
        }
      }
    } catch (_) {}
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
    await _player.play(AssetSource('sounds/win.wav'));
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
