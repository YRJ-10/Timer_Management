import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../core/audio_service.dart';

class SimpleTimerProvider extends ChangeNotifier {
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;

  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  Timer? _timer;

  int get hours => _hours;
  int get minutes => _minutes;
  int get seconds => _seconds;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;

  void setTime(int h, int m, int s) {
    if (_isRunning) return;
    _hours = h;
    _minutes = m;
    _seconds = s;
    notifyListeners();
  }

  void start() {
    if (_isRunning && !_isPaused) return;
    
    if (!_isRunning) {
      _remainingSeconds = (_hours * 3600) + (_minutes * 60) + _seconds;
      if (_remainingSeconds == 0) return;
    }

    _isRunning = true;
    _isPaused = false;
    WakelockPlus.enable(); // Keep screen on

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        stop(playAlarm: true);
      }
    });
    notifyListeners();
  }

  void pause() {
    if (!_isRunning || _isPaused) return;
    _timer?.cancel();
    _isPaused = true;
    WakelockPlus.disable();
    notifyListeners();
  }

  void stop({bool playAlarm = false}) {
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;
    _remainingSeconds = 0;
    WakelockPlus.disable();
    if (playAlarm) {
      AudioService.playLongAlarm();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }
}
