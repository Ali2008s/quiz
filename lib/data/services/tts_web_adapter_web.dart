import 'dart:js' as js;
import 'dart:convert';

void speakWithBrowserTTS(String text) {
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

void stopWithBrowserTTS() {
  try {
    js.context.callMethod('eval', ['window.speechSynthesis.cancel();']);
  } catch (_) {}
}
