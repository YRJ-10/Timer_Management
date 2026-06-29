import 'dart:io';
import 'dart:typed_data';

void main() async {
  // 5 short beeps (high pitch - 1500Hz)
  // Total duration: 5 * (0.15s beep + 0.15s silence) = 1.5s
  await generatePatternTone('assets/audio/short_beep.wav', 1500, 5, 0.15, 0.15);
  
  // 4 long beeps (lower pitch than short beep - 1000Hz)
  // Total duration: 4 * (0.6s beep + 0.4s silence) = 4.0s
  await generatePatternTone('assets/audio/long_alarm.wav', 1000, 4, 0.6, 0.4);
  
  print('Pattern sounds generated.');
}

Future<void> generatePatternTone(
  String filename, 
  double frequency, 
  int repeatCount, 
  double beepDuration, 
  double silenceDuration, 
  {int sampleRate = 44100}
) async {
  double totalDuration = repeatCount * (beepDuration + silenceDuration);
  int numSamples = (totalDuration * sampleRate).toInt();
  
  var file = File(filename);
  var sink = file.openWrite();

  // WAV Header (44 bytes)
  var header = ByteData(44);
  header.setUint8(0, 0x52); // 'R'
  header.setUint8(1, 0x49); // 'I'
  header.setUint8(2, 0x46); // 'F'
  header.setUint8(3, 0x46); // 'F'
  
  int fileSize = 36 + numSamples * 2;
  header.setUint32(4, fileSize, Endian.little);
  
  header.setUint8(8, 0x57);  // 'W'
  header.setUint8(9, 0x41);  // 'A'
  header.setUint8(10, 0x56); // 'V'
  header.setUint8(11, 0x45); // 'E'
  
  header.setUint8(12, 0x66); // 'f'
  header.setUint8(13, 0x6D); // 'm'
  header.setUint8(14, 0x74); // 't'
  header.setUint8(15, 0x20); // ' '
  
  header.setUint32(16, 16, Endian.little); // Subchunk1Size
  header.setUint16(20, 1, Endian.little);  // AudioFormat (PCM)
  header.setUint16(22, 1, Endian.little);  // NumChannels (1)
  header.setUint32(24, sampleRate, Endian.little); // SampleRate
  header.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
  header.setUint16(32, 2, Endian.little);  // BlockAlign
  header.setUint16(34, 16, Endian.little); // BitsPerSample
  
  header.setUint8(36, 0x64); // 'd'
  header.setUint8(37, 0x61); // 'a'
  header.setUint8(38, 0x74); // 't'
  header.setUint8(39, 0x61); // 'a'
  
  header.setUint32(40, numSamples * 2, Endian.little); // Subchunk2Size

  sink.add(header.buffer.asUint8List());

  // Data
  var data = ByteData(numSamples * 2);
  double cycleDuration = beepDuration + silenceDuration;
  
  for (int i = 0; i < numSamples; i++) {
    double t = i / sampleRate;
    double currentCycleTime = t % cycleDuration;
    
    int value = 0;
    // Only play sound during the beepDuration part of the cycle
    if (currentCycleTime < beepDuration) {
      // Square wave
      bool isHigh = (t * frequency) % 1.0 < 0.5;
      value = isHigh ? 26000 : -26000;
    }

    data.setInt16(i * 2, value, Endian.little);
  }
  
  sink.add(data.buffer.asUint8List());
  await sink.close();
}
