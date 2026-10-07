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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      minutes: json['minutes'] ?? 0,
      seconds: json['seconds'] ?? 0,
    );
  }
}

class RoutineProfile {
  final String id;
  String name;
  bool isLooping;
  List<TimerSequenceItem> items;

  RoutineProfile({
    required this.id,
    required this.name,
    this.isLooping = false,
    List<TimerSequenceItem>? items,
  }) : items = items ?? [];

  int get totalSeconds =>
      items.fold(0, (sum, item) => sum + item.totalSeconds);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isLooping': isLooping,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory RoutineProfile.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return RoutineProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Routine',
      isLooping: json['isLooping'] ?? false,
      items: rawItems.map((e) => TimerSequenceItem.fromJson(e)).toList(),
    );
  }

  RoutineProfile copyWith({
    String? id,
    String? name,
    bool? isLooping,
    List<TimerSequenceItem>? items,
  }) {
    return RoutineProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      isLooping: isLooping ?? this.isLooping,
      items: items ?? List.from(this.items),
    );
  }
}

