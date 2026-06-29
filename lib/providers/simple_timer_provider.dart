import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../core/audio_service.dart';

class SimpleTimerProvider extends ChangeNotifier {
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;

  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  Timer? _timer;

  // Custom templates list in seconds
  List<int> _templates = [];

  int get hours => _hours;
  int get minutes => _minutes;
  int get seconds => _seconds;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  double get progress {
    if (_totalSeconds == 0) return 0;
    return 1 - (_remainingSeconds / _totalSeconds);
  }

  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  List<int> get templates => _templates;

  SimpleTimerProvider() {
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('simple_templates');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      _templates = decoded.cast<int>();
    } else {
      // Default templates (1 min, 5 min)
      _templates = [60, 300];
      _saveTemplates();
    }
    notifyListeners();
  }

  Future<void> _saveTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('simple_templates', jsonEncode(_templates));
  }

  void addTemplate(int h, int m, int s) {
    if (_templates.length >= 5) return;
    int totalSec = (h * 3600) + (m * 60) + s;
    if (totalSec == 0 || _templates.contains(totalSec)) return;

    _templates.add(totalSec);
    _templates.sort();
    _saveTemplates();
    notifyListeners();
  }

  void removeTemplate(int index) {
    if (index >= 0 && index < _templates.length) {
      _templates.removeAt(index);
      _saveTemplates();
      notifyListeners();
    }
  }

  void setTime(int h, int m, int s) {
    if (_isRunning) return;
    _hours = h;
    _minutes = m;
    _seconds = s;
    notifyListeners();
  }

  void setTimeFromSeconds(int totalSeconds) {
    if (_isRunning) return;
    _hours = totalSeconds ~/ 3600;
    _minutes = (totalSeconds % 3600) ~/ 60;
    _seconds = totalSeconds % 60;
    notifyListeners();
  }

  void start() {
    if (_isRunning && !_isPaused) return;

    if (!_isRunning) {
      _totalSeconds = (_hours * 3600) + (_minutes * 60) + _seconds;
      _remainingSeconds = _totalSeconds;
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
    _totalSeconds = 0;
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
