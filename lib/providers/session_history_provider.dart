import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/session_log.dart';

class SessionHistoryProvider extends ChangeNotifier {
  static const _storageKey = 'session_history';
  static const _maxItems = 50;

  List<SessionLog> _sessions = [];

  List<SessionLog> get sessions => List.unmodifiable(_sessions);
  int get completedCount => _sessions.length;
  int get totalSeconds =>
      _sessions.fold(0, (sum, session) => sum + session.durationSeconds);
  List<SessionLog> get recentSessions => _sessions.take(5).toList();

  SessionHistoryProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data == null) return;

    final decoded = jsonDecode(data) as List<dynamic>;
    _sessions = decoded
        .map((item) => SessionLog.fromJson(item as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_sessions.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> addSession({
    required String type,
    required String title,
    required int durationSeconds,
    int stepCount = 1,
  }) async {
    if (durationSeconds <= 0) return;

    _sessions = [
      SessionLog(
        id: const Uuid().v4(),
        type: type,
        title: title,
        durationSeconds: durationSeconds,
        stepCount: stepCount,
        completedAt: DateTime.now(),
      ),
      ..._sessions,
    ].take(_maxItems).toList();

    await _save();
    notifyListeners();
  }

  Future<void> clear() async {
    _sessions = [];
    await _save();
    notifyListeners();
  }
}
