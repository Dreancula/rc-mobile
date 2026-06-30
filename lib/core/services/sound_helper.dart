import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class SoundHelper {
  SoundHelper._();

  static final AudioPlayer _player = AudioPlayer();
  static String? _cachedPath;

  static Future<void> playNotificationSound() async {
    try {
      final path = await _getOrGenerateBeep();
      if (path != null) {
        await _player.stop();
        await _player.play(DeviceFileSource(path));
      }
    } catch (_) {}
  }

  static Future<String?> _getOrGenerateBeep() async {
    if (_cachedPath != null && await File(_cachedPath!).exists()) {
      return _cachedPath;
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/notif_beep.wav');

      if (await file.exists()) {
        _cachedPath = file.path;
        return _cachedPath;
      }

      final sampleRate = 22050;
      final tone1Freq = 880.0;
      final tone1Duration = 0.12;
      final gapDuration = 0.05;
      final tone2Freq = 1320.0;
      final tone2Duration = 0.18;
      final totalSamples = ((tone1Duration + gapDuration + tone2Duration) * sampleRate).toInt();

      final data = <int>[];

      data.addAll([0x52, 0x49, 0x46, 0x46]);
      final fileSize = 36 + totalSamples * 2;
      data.addAll(_toLE(fileSize, 4));
      data.addAll([0x57, 0x41, 0x56, 0x45]);

      data.addAll([0x66, 0x6D, 0x74, 0x20]);
      data.addAll(_toLE(16, 4));
      data.addAll(_toLE(1, 2));
      data.addAll(_toLE(1, 2));
      data.addAll(_toLE(sampleRate, 4));
      data.addAll(_toLE(sampleRate * 2, 4));
      data.addAll(_toLE(2, 2));
      data.addAll(_toLE(16, 2));

      data.addAll([0x64, 0x61, 0x74, 0x61]);
      data.addAll(_toLE(totalSamples * 2, 4));

      int tone1Samples = (tone1Duration * sampleRate).toInt();
      int gapSamples = (gapDuration * sampleRate).toInt();

      for (int i = 0; i < tone1Samples; i++) {
        final t = i / sampleRate;
        final envelope = sin(pi * i / tone1Samples);
        final sample = (sin(2 * pi * tone1Freq * t) * envelope * 0.6 * 32767).toInt();
        data.addAll(_toLE(sample.clamp(-32767, 32767), 2));
      }
      for (int i = 0; i < gapSamples; i++) {
        data.addAll(_toLE(0, 2));
      }
      for (int i = 0; i < totalSamples - tone1Samples - gapSamples; i++) {
        final t = i / sampleRate;
        final tone2Samples = totalSamples - tone1Samples - gapSamples;
        final envelope = sin(pi * i / tone2Samples);
        final sample = (sin(2 * pi * tone2Freq * t) * envelope * 0.6 * 32767).toInt();
        data.addAll(_toLE(sample.clamp(-32767, 32767), 2));
      }

      await file.writeAsBytes(data);
      _cachedPath = file.path;
      return _cachedPath;
    } catch (_) {
      return null;
    }
  }

  static List<int> _toLE(int value, int length) {
    final bytes = <int>[];
    for (int i = 0; i < length; i++) {
      bytes.add(value & 0xFF);
      value >>= 8;
    }
    return bytes;
  }
}
