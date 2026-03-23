import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

void main() {
  Directory('assets/sounds').createSync(recursive: true);

  // 1. Correct sound (Ding-Ding, high pitch)
  createWav('assets/sounds/correct.wav', [880.0, 1108.73], 0.4);

  // 2. Wrong sound (Low buzz)
  createWav('assets/sounds/wrong.wav', [150.0], 0.5);

  // 3. Win sound (Happy Arpeggio)
  createWav('assets/sounds/win.wav', [523.25, 659.25, 783.99, 1046.50], 1.2);

  // 4. Click/Pop sound (very short tick)
  createWav('assets/sounds/click.mp3', [600.0], 0.05);

  print('جميع الأصوات تم توليدها بنجاح!');
}

void createWav(String filename, List<double> frequencies, double durationSec) {
  int sampleRate = 44100;
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

  // Audio Samples
  int samplesPerFreq = numSamples ~/ frequencies.length;
  for (int f = 0; f < frequencies.length; f++) {
    double freq = frequencies[f];
    for (int i = 0; i < samplesPerFreq; i++) {
      double time = i / sampleRate;
      // Fade out slightly at the end of each note
      double fade = 1.0 - (i / samplesPerFreq) * 0.3;
      double value = sin(2 * pi * freq * time);
      int sample = (value * 32767 * 0.4 * fade).toInt(); // 40% volume
      bytes.add(_writeInt16(sample));
    }
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
