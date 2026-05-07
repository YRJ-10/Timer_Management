import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:uuid/uuid.dart';
import '../core/audio_service.dart';
import '../models/timer_sequence_model.dart';

class SequenceTimerProvider extends ChangeNotifier {
  List<TimerSequenceItem> _sequence = [];
  bool _isLooping = false;
  
  bool _isRunning = false;
  bool _isPaused = false;
  int _currentIndex = 0;
  int _remainingSeconds = 0;
  Timer? _timer;

  List<TimerSequenceItem> get sequence => _sequence;
  bool get isLooping => _isLooping;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  int get currentIndex => _currentIndex;
  int get remainingSeconds => _remainingSeconds;

  SequenceTimerProvider() {
    _loadSequence();
  }

  Future<void> _loadSequence() async {
    final prefs = await SharedPreferences.getInstance();
    final String? seqData = prefs.getString('sequence_data');
    final bool? loopData = prefs.getBool('is_looping');
    
    if (loopData != null) _isLooping = loopData;

    if (seqData != null) {
      final List<dynamic> decoded = jsonDecode(seqData);
      _sequence = decoded.map((e) => TimerSequenceItem.fromJson(e)).toList();
    }
    notifyListeners();
  }

  Future<void> _saveSequence() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_sequence.map((e) => e.toJson()).toList());
    await prefs.setString('sequence_data', encoded);
    await prefs.setBool('is_looping', _isLooping);
  }

  void toggleLoop() {
    _isLooping = !_isLooping;
    _saveSequence();
    notifyListeners();
  }

  void addSequenceItem(int minutes, int seconds) {
    if (_sequence.length >= 10) return;
    final item = TimerSequenceItem(
      id: const Uuid().v4(),
      minutes: minutes,
      seconds: seconds,
    );
    _sequence.add(item);
    _saveSequence();
    notifyListeners();
  }

  void removeSequenceItem(String id) {
    _sequence.removeWhere((item) => item.id == id);
    _saveSequence();
    notifyListeners();
  }

  void start() {
    if (_sequence.length < 2 || (_isRunning && !_isPaused)) return;

    if (!_isRunning) {
      _currentIndex = 0;
      _remainingSeconds = _sequence[_currentIndex].totalSeconds;
    }

    _isRunning = true;
    _isPaused = false;
    WakelockPlus.enable();
    
    _runTimer();
    notifyListeners();
  }
  
  void _runTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _nextTimer();
      }
    });
  }

  void _nextTimer() {
    _timer?.cancel();
    
    if (_currentIndex < _sequence.length - 1) {
      AudioService.playShortBeep();
      _currentIndex++;
      _remainingSeconds = _sequence[_currentIndex].totalSeconds;
      _runTimer();
      notifyListeners();
    } else {
      // Reached the end
      if (_isLooping) {
        AudioService.playLongAlarm();
        _currentIndex = 0;
        _remainingSeconds = _sequence[_currentIndex].totalSeconds;
        _runTimer();
        notifyListeners();
      } else {
        stop(playAlarm: true);
      }
    }
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
    _currentIndex = 0;
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
