enum LogEntryCategory {
  dailyLog('daily_log', 'Daily Log'),
  strategy('strategy', 'Strategy & Notes');

  const LogEntryCategory(this.value, this.displayName);
  
  final String value;
  final String displayName;
  
  static LogEntryCategory fromValue(String value) {
    return LogEntryCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => LogEntryCategory.dailyLog,
    );
  }
}

class LogEntry {
  final int? id;
  final String title;
  final String content;
  final LogEntryCategory category;
  final DateTime timestamp;

  const LogEntry({
    this.id,
    required this.title,
    required this.content,
    this.category = LogEntryCategory.dailyLog,
    required this.timestamp,
  });

  LogEntry copyWith({
    int? id,
    String? title,
    String? content,
    LogEntryCategory? category,
    DateTime? timestamp,
  }) {
    return LogEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Extract hashtags from the content
  List<String> get hashtags {
    final regex = RegExp(r'#\w+');
    return regex.allMatches(content).map((match) => match.group(0)!).toList();
  }

  /// Check if entry contains any of the provided hashtags
  bool containsHashtag(String hashtag) {
    return content.toLowerCase().contains(hashtag.toLowerCase());
  }

  /// Check if entry contains search term in title or content (case-insensitive)
  bool containsText(String searchTerm) {
    final searchLower = searchTerm.toLowerCase();
    return title.toLowerCase().contains(searchLower) || 
           content.toLowerCase().contains(searchLower);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category.value,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      category: LogEntryCategory.fromValue(map['category'] ?? 'daily_log'),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }

  @override
  String toString() {
    return 'LogEntry(id: $id, title: $title, content: $content, category: $category, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LogEntry &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.category == category &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ content.hashCode ^ category.hashCode ^ timestamp.hashCode;
  }
} 