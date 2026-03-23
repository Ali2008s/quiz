import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  Directory('assets/sounds').createSync(recursive: true);

  // Generate a modern, soft "Pop" sound (famous in modern casual games)
  createPopWav('assets/sounds/click.mp3');

  print('تم استبدال صوت النقر بصوت (Pop) حديث وجميل!');
}

void createPopWav(String filename) {
  int sampleRate = 44100;
  double durationSec = 0.08; // Short duration
  int numSamples = (sampleRate * durationSec).toInt();

  var file = File(filename);
  var bytes = BytesBuilder();

  // RIFF Header
  bytes.add('RIFF'.codeUnits);
  bytes.add(_writeInt32(36 + numSamples * 2));
  bytes.add('WAVE'.codeUnits);

  // fmt Subchunk
  bytes.add('fmt '.codeUnits);
  bytes.add(_writeInt32(16));
  bytes.add(_writeInt16(1));
  bytes.add(_writeInt16(1));
  bytes.add(_writeInt32(sampleRate));
  bytes.add(_writeInt32(sampleRate * 2));
  bytes.add(_writeInt16(2));
  bytes.add(_writeInt16(16));

  // data Subchunk
  bytes.add('data'.codeUnits);
  bytes.add(_writeInt32(numSamples * 2));

  // Audio Samples for "Pop/Bloop"
  double phase = 0;
  for (int i = 0; i < numSamples; i++) {
    double time = i / sampleRate;
    // Fast frequency sweep (starting high, sweeping low for a 'bloop' effect)
    double currentFreq = 800.0 - (600.0 * (time / durationSec));

    // Calculate phase integral manually for a sweep
    phase += 2 * pi * currentFreq / sampleRate;

    // Smooth envelope: fades out quickly
    double envelope = 1.0 - (time / durationSec);
    envelope = pow(envelope, 1.5).toDouble(); // Curve the fade out

    double value = sin(phase);
    int sample = (value * 32767 * 0.7 * envelope).toInt(); // 70% volume
    bytes.add(_writeInt16(sample));
  }

  file.writeAsBytesSync(bytes.toBytes());
}

List<int> _writeInt32(int value) => [
      (value & 0xff),
      ((value >> 8) & 0xff),
      ((value >> 16) & 0xff),
      ((value >> 24) & 0xff)
    ];
List<int> _writeInt16(int value) => [(value & 0xff), ((value >> 8) & 0xff)];
