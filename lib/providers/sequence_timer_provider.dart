import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:uuid/uuid.dart';
import '../core/audio_service.dart';
import '../models/timer_sequence_model.dart';
import 'session_history_provider.dart';
import 'settings_provider.dart';

class SequenceTimerProvider extends ChangeNotifier {
  List<RoutineProfile> _routines = [];
  String? _activeRoutineId;

  bool _isRunning = false;
  bool _isPaused = false;
  int _currentIndex = 0;
  int _remainingSeconds = 0;
  Timer? _timer;
  AppSettingsProvider? _settings;
  SessionHistoryProvider? _history;

  List<RoutineProfile> get routines => _routines;
  String? get activeRoutineId => activeRoutine?.id;

  RoutineProfile? get activeRoutine {
    if (_routines.isEmpty) return null;
    return _routines.firstWhere(
      (r) => r.id == _activeRoutineId,
      orElse: () => _routines.first,
    );
  }

  String get activeRoutineName => activeRoutine?.name ?? 'Routine';
  List<TimerSequenceItem> get sequence => activeRoutine?.items ?? [];
  bool get isLooping => activeRoutine?.isLooping ?? false;

  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  int get currentIndex => _currentIndex;
  int get remainingSeconds => _remainingSeconds;

  int get currentTotalSeconds {
    final list = sequence;
    if (list.isEmpty || _currentIndex >= list.length) return 0;
    return list[_currentIndex].totalSeconds;
  }

  double get currentProgress {
    if (currentTotalSeconds == 0) return 0;
    return 1 - (_remainingSeconds / currentTotalSeconds);
  }

  int get totalSequenceSeconds {
    return activeRoutine?.totalSeconds ?? 0;
  }

  SequenceTimerProvider() {
    _loadSequence();
  }

  void attachServices(
    AppSettingsProvider settings,
    SessionHistoryProvider history,
  ) {
    _settings = settings;
    _history = history;
  }

  Future<void> _loadSequence() async {
    final prefs = await SharedPreferences.getInstance();
    final String? routinesData = prefs.getString('routine_profiles');
    final String? activeId = prefs.getString('active_routine_id');

    if (routinesData != null) {
      try {
        final List<dynamic> decoded = jsonDecode(routinesData);
        _routines = decoded.map((e) => RoutineProfile.fromJson(e)).toList();
        _activeRoutineId = activeId;
      } catch (_) {
        _routines = [];
      }
    } else {
      // Migrate from legacy single-sequence storage
      final String? legacySeq = prefs.getString('sequence_data');
      final bool? legacyLoop = prefs.getBool('is_looping');

      List<TimerSequenceItem> legacyItems = [];
      if (legacySeq != null) {
        try {
          final List<dynamic> decoded = jsonDecode(legacySeq);
          legacyItems =
              decoded.map((e) => TimerSequenceItem.fromJson(e)).toList();
        } catch (_) {}
      }

      final defaultRoutine = RoutineProfile(
        id: const Uuid().v4(),
        name: 'Default Routine',
        isLooping: legacyLoop ?? false,
        items: legacyItems,
      );

      _routines = [defaultRoutine];
      _activeRoutineId = defaultRoutine.id;
      await _saveSequence();
    }

    if (_routines.isEmpty) {
      final defaultRoutine = RoutineProfile(
        id: const Uuid().v4(),
        name: 'Default Routine',
        isLooping: false,
        items: [],
      );
      _routines.add(defaultRoutine);
      _activeRoutineId = defaultRoutine.id;
      await _saveSequence();
    } else if (_activeRoutineId == null ||
        !_routines.any((r) => r.id == _activeRoutineId)) {
      _activeRoutineId = _routines.first.id;
    }

    notifyListeners();
  }

  Future<void> _saveSequence() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _routines.map((e) => e.toJson()).toList(),
    );
    await prefs.setString('routine_profiles', encoded);
    if (_activeRoutineId != null) {
      await prefs.setString('active_routine_id', _activeRoutineId!);
    }

    // Keep legacy storage in sync as fallback
    if (activeRoutine != null) {
      await prefs.setString(
        'sequence_data',
        jsonEncode(sequence.map((e) => e.toJson()).toList()),
      );
      await prefs.setBool('is_looping', isLooping);
    }
  }

  // --- Routine Profile Management ---

  void selectRoutine(String routineId) {
    if (_isRunning) return;
    if (_activeRoutineId == routineId) return;
    final found = _routines.any((r) => r.id == routineId);
    if (!found) return;

    _activeRoutineId = routineId;
    _currentIndex = 0;
    _remainingSeconds = 0;
    _saveSequence();
    notifyListeners();
  }

  void createRoutine(String name) {
    if (_isRunning) return;
    final trimmed = name.trim();
    final routineName =
        trimmed.isEmpty ? 'Routine ${_routines.length + 1}' : trimmed;
    final newRoutine = RoutineProfile(
      id: const Uuid().v4(),
      name: routineName,
      isLooping: false,
      items: [],
    );
    _routines.add(newRoutine);
    _activeRoutineId = newRoutine.id;
    _currentIndex = 0;
    _remainingSeconds = 0;
    _saveSequence();
    notifyListeners();
  }

  void renameRoutine(String routineId, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final index = _routines.indexWhere((r) => r.id == routineId);
    if (index == -1) return;
    _routines[index].name = trimmed;
    _saveSequence();
    notifyListeners();
  }

  void duplicateRoutine(String routineId) {
    if (_isRunning) return;
    final existing = _routines.firstWhere(
      (r) => r.id == routineId,
      orElse: () => _routines.first,
    );
    final duplicated = RoutineProfile(
      id: const Uuid().v4(),
      name: '${existing.name} (Copy)',
      isLooping: existing.isLooping,
      items: existing.items
          .map(
            (i) => TimerSequenceItem(
              id: const Uuid().v4(),
              name: i.name,
              minutes: i.minutes,
              seconds: i.seconds,
            ),
          )
          .toList(),
    );
    _routines.add(duplicated);
    _activeRoutineId = duplicated.id;
    _currentIndex = 0;
    _remainingSeconds = 0;
    _saveSequence();
    notifyListeners();
  }

  void deleteRoutine(String routineId) {
    if (_isRunning) return;
    if (_routines.length <= 1) return; // Keep at least one routine
    final index = _routines.indexWhere((r) => r.id == routineId);
    if (index == -1) return;

    _routines.removeAt(index);
    if (_activeRoutineId == routineId) {
      _activeRoutineId = _routines.first.id;
      _currentIndex = 0;
      _remainingSeconds = 0;
    }
    _saveSequence();
    notifyListeners();
  }

  void toggleLoop() {
    setLooping(!isLooping);
  }

  void setLooping(bool value) {
    final current = activeRoutine;
    if (current == null || current.isLooping == value) return;
    current.isLooping = value;
    _saveSequence();
    notifyListeners();
  }

  // --- Step Management ---

  void addSequenceItem(int minutes, int seconds, {String name = ''}) {
    final routine = activeRoutine;
    if (routine == null || routine.items.length >= 15) return;
    final item = TimerSequenceItem(
      id: const Uuid().v4(),
      name: name.trim(),
      minutes: minutes,
      seconds: seconds,
    );
    routine.items.add(item);
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
    final routine = activeRoutine;
    if (routine == null) return;
    final index = routine.items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    if (minutes == 0 && seconds == 0) return;

    routine.items[index] = TimerSequenceItem(
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
    final routine = activeRoutine;
    if (routine == null) return;
    if (oldIndex < 0 || oldIndex >= routine.items.length) return;

    final adjustedNewIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
    if (adjustedNewIndex < 0 || adjustedNewIndex >= routine.items.length) return;

    final item = routine.items.removeAt(oldIndex);
    routine.items.insert(adjustedNewIndex, item);
    _saveSequence();
    notifyListeners();
  }

  void removeSequenceItem(String id) {
    final routine = activeRoutine;
    if (routine == null) return;
    routine.items.removeWhere((item) => item.id == id);
    _saveSequence();
    notifyListeners();
  }

  // --- Timer Controls ---

  void start() {
    final list = sequence;
    if (list.length < 2 || (_isRunning && !_isPaused)) return;

    if (!_isRunning) {
      _currentIndex = 0;
      _remainingSeconds = list[_currentIndex].totalSeconds;
    }

    _isRunning = true;
    _isPaused = false;
    if (_settings?.keepScreenAwake ?? true) {
      WakelockPlus.enable();
    }

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
    final list = sequence;
    if (!_isRunning || list.isEmpty) return;
    _timer?.cancel();

    if (_currentIndex > 0) {
      _currentIndex--;
    }
    _remainingSeconds = list[_currentIndex].totalSeconds;
    if (!_isPaused) _runTimer();
    notifyListeners();
  }

  void nextTimer() {
    final list = sequence;
    if (!_isRunning || list.isEmpty) return;
    _timer?.cancel();

    if (_currentIndex < list.length - 1) {
      _currentIndex++;
    } else if (isLooping) {
      _currentIndex = 0;
    } else {
      stop();
      return;
    }

    _remainingSeconds = list[_currentIndex].totalSeconds;
    if (!_isPaused) _runTimer();
    notifyListeners();
  }

  void _nextTimer() {
    _timer?.cancel();
    final list = sequence;

    if (_currentIndex < list.length - 1) {
      if (_settings?.alarmSoundEnabled ?? true) {
        AudioService.playShortBeep();
      }
      _currentIndex++;
      _remainingSeconds = list[_currentIndex].totalSeconds;
      _runTimer();
      notifyListeners();
    } else {
      // Reached the end
      if (isLooping) {
        _recordCompletion();
        _playCompletionFeedback();
        _currentIndex = 0;
        _remainingSeconds = list.isEmpty ? 0 : list[_currentIndex].totalSeconds;
        _runTimer();
        notifyListeners();
      } else {
        stop(playAlarm: true);
      }
    }
  }

  void _recordCompletion() {
    final routineName = activeRoutineName.trim();
    final title = routineName.isNotEmpty ? routineName : 'Sequence Routine';

    _history?.addSession(
      type: 'Sequence',
      title: title,
      durationSeconds: totalSequenceSeconds,
      stepCount: sequence.length,
    );
  }

  void _playCompletionFeedback() {
    if (_settings?.vibrateOnComplete ?? true) {
      HapticFeedback.heavyImpact();
    }
    if (_settings?.alarmSoundEnabled ?? true) {
      AudioService.playLongAlarm();
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
      _recordCompletion();
      _playCompletionFeedback();
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
