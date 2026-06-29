import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider extends ChangeNotifier {
  bool _alarmSoundEnabled = true;
  bool _vibrateOnComplete = true;
  bool _keepScreenAwake = true;

  bool get alarmSoundEnabled => _alarmSoundEnabled;
  bool get vibrateOnComplete => _vibrateOnComplete;
  bool get keepScreenAwake => _keepScreenAwake;

  AppSettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _alarmSoundEnabled = prefs.getBool('alarm_sound_enabled') ?? true;
    _vibrateOnComplete = prefs.getBool('vibrate_on_complete') ?? true;
    _keepScreenAwake = prefs.getBool('keep_screen_awake') ?? true;
    notifyListeners();
  }

  Future<void> setAlarmSoundEnabled(bool value) async {
    if (_alarmSoundEnabled == value) return;
    _alarmSoundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarm_sound_enabled', value);
    notifyListeners();
  }

  Future<void> setVibrateOnComplete(bool value) async {
    if (_vibrateOnComplete == value) return;
    _vibrateOnComplete = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrate_on_complete', value);
    notifyListeners();
  }

  Future<void> setKeepScreenAwake(bool value) async {
    if (_keepScreenAwake == value) return;
    _keepScreenAwake = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keep_screen_awake', value);
    notifyListeners();
  }
}
