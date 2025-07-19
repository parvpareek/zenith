enum MessageSender { user, assistant }

class ChatMessage {
  final int? id;
  final String content;
  final MessageSender sender;
  final DateTime timestamp;

  const ChatMessage({
    this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
  });

  ChatMessage copyWith({
    int? id,
    String? content,
    MessageSender? sender,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  bool get isUser => sender == MessageSender.user;
  bool get isAssistant => sender == MessageSender.assistant;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'sender': sender.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id']?.toInt(),
      content: map['content'] ?? '',
      sender: MessageSender.values.firstWhere(
        (e) => e.name == map['sender'],
        orElse: () => MessageSender.user,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, content: $content, sender: $sender, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.content == content &&
        other.sender == sender &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        content.hashCode ^
        sender.hashCode ^
        timestamp.hashCode;
  }
} 