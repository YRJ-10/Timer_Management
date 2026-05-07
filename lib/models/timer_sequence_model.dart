class TimerSequenceItem {
  final String id;
  final int minutes;
  final int seconds;

  TimerSequenceItem({
    required this.id,
    required this.minutes,
    required this.seconds,
  });

  int get totalSeconds => (minutes * 60) + seconds;

  // For SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'minutes': minutes,
      'seconds': seconds,
    };
  }

  factory TimerSequenceItem.fromJson(Map<String, dynamic> json) {
    return TimerSequenceItem(
      id: json['id'],
      minutes: json['minutes'],
      seconds: json['seconds'],
    );
  }
}
