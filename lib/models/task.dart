class Task {
  final int? id;
  final String description;
  final bool isCompleted;
  final DateTime date;
  final double hours;

  const Task({
    this.id,
    required this.description,
    required this.isCompleted,
    required this.date,
    this.hours = 0.0,
  });

  Task copyWith({
    int? id,
    String? description,
    bool? isCompleted,
    DateTime? date,
    double? hours,
  }) {
    return Task(
      id: id ?? this.id,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
      hours: hours ?? this.hours,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'date': date.millisecondsSinceEpoch,
      'hours': hours,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id']?.toInt(),
      description: map['description'] ?? '',
      isCompleted: (map['isCompleted'] ?? 0) == 1,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      hours: (map['hours'] ?? 0.0).toDouble(),
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, description: $description, isCompleted: $isCompleted, date: $date, hours: $hours)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task &&
        other.id == id &&
        other.description == description &&
        other.isCompleted == isCompleted &&
        other.date == date &&
        other.hours == hours;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        description.hashCode ^
        isCompleted.hashCode ^
        date.hashCode ^
        hours.hashCode;
  }
} 