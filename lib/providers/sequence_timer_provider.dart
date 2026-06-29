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
  int get currentTotalSeconds =>
      _sequence.isEmpty ? 0 : _sequence[_currentIndex].totalSeconds;
  double get currentProgress {
    if (currentTotalSeconds == 0) return 0;
    return 1 - (_remainingSeconds / currentTotalSeconds);
  }

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
    final String encoded = jsonEncode(
      _sequence.map((e) => e.toJson()).toList(),
    );
    await prefs.setString('sequence_data', encoded);
    await prefs.setBool('is_looping', _isLooping);
  }

  void toggleLoop() {
    setLooping(!_isLooping);
  }

  void setLooping(bool value) {
    if (_isLooping == value) return;
    _isLooping = value;
    _saveSequence();
    notifyListeners();
  }

  void addSequenceItem(int minutes, int seconds, {String name = ''}) {
    if (_sequence.length >= 10) return;
    final item = TimerSequenceItem(
      id: const Uuid().v4(),
      name: name.trim(),
      minutes: minutes,
      seconds: seconds,
    );
    _sequence.add(item);
    _saveSequence();
    notifyListeners();
  }

  void updateSequenceItem(
    String id, {
    required String name,
    required int minutes,
    required int seconds,
  }) {
    if (_isRunning) return;
    final index = _sequence.indexWhere((item) => item.id == id);
    if (index == -1) return;
    if (minutes == 0 && seconds == 0) return;

    _sequence[index] = TimerSequenceItem(
      id: id,
      name: name.trim(),
      minutes: minutes,
      seconds: seconds,
    );
    _saveSequence();
    notifyListeners();
  }

  void reorderSequenceItem(int oldIndex, int newIndex) {
    if (_isRunning) return;
    if (oldIndex < 0 || oldIndex >= _sequence.length) return;

    final adjustedNewIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
    if (adjustedNewIndex < 0 || adjustedNewIndex >= _sequence.length) return;

    final item = _sequence.removeAt(oldIndex);
    _sequence.insert(adjustedNewIndex, item);
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

  void previousTimer() {
    if (!_isRunning || _sequence.isEmpty) return;
    _timer?.cancel();

    if (_currentIndex > 0) {
      _currentIndex--;
    }
    _remainingSeconds = _sequence[_currentIndex].totalSeconds;
    if (!_isPaused) _runTimer();
    notifyListeners();
  }

  void nextTimer() {
    if (!_isRunning || _sequence.isEmpty) return;
    _timer?.cancel();

    if (_currentIndex < _sequence.length - 1) {
      _currentIndex++;
    } else if (_isLooping) {
      _currentIndex = 0;
    } else {
      stop();
      return;
    }

    _remainingSeconds = _sequence[_currentIndex].totalSeconds;
    if (!_isPaused) _runTimer();
    notifyListeners();
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
