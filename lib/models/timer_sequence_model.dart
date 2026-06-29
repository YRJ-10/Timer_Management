class TimerSequenceItem {
  final String id;
  final String name;
  final int minutes;
  final int seconds;

  TimerSequenceItem({
    required this.id,
    this.name = '',
    required this.minutes,
    required this.seconds,
  });

  int get totalSeconds => (minutes * 60) + seconds;

  // For SharedPreferences
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'minutes': minutes, 'seconds': seconds};
  }

  factory TimerSequenceItem.fromJson(Map<String, dynamic> json) {
    return TimerSequenceItem(
      id: json['id'],
      name: json['name'] ?? '',
      minutes: json['minutes'],
      seconds: json['seconds'],
    );
  }
}
