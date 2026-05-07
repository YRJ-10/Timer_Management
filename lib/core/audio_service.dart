import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playShortBeep() async {
    await _player.stop();
    await _player.play(AssetSource('audio/short_beep.wav'));
  }

  static Future<void> playLongAlarm() async {
    await _player.stop();
    await _player.play(AssetSource('audio/long_alarm.wav'));
  }

  static Future<void> stop() async {
    await _player.stop();
  }
}
