class SessionLog {
  final String id;
  final String type;
  final String title;
  final int durationSeconds;
  final int stepCount;
  final DateTime completedAt;

  const SessionLog({
    required this.id,
    required this.type,
    required this.title,
    required this.durationSeconds,
    required this.stepCount,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'durationSeconds': durationSeconds,
      'stepCount': stepCount,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory SessionLog.fromJson(Map<String, dynamic> json) {
    return SessionLog(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      durationSeconds: json['durationSeconds'],
      stepCount: json['stepCount'] ?? 1,
      completedAt: DateTime.parse(json['completedAt']),
    );
  }
}
