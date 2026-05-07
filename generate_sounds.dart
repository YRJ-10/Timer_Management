import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

void main() async {
  await generateTone('assets/audio/short_beep.wav', 0.5, 800);
  await generateTone('assets/audio/long_alarm.wav', 2.0, 600);
  print('Sounds generated.');
}

Future<void> generateTone(String filename, double duration, double frequency, {int sampleRate = 44100}) async {
  int numSamples = (duration * sampleRate).toInt();
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
  for (int i = 0; i < numSamples; i++) {
    double t = i / sampleRate;
    int value = (32767.0 * sin(2.0 * pi * frequency * t)).toInt();
    data.setInt16(i * 2, value, Endian.little);
  }
  
  sink.add(data.buffer.asUint8List());
  await sink.close();
}
