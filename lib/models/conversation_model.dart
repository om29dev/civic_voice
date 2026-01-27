class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? action;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.action,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    if (action != null) 'action': action,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    text: json['text'],
    isUser: json['isUser'],
    timestamp: DateTime.parse(json['timestamp']),
    action: json['action'] != null ? Map<String, dynamic>.from(json['action']) : null,
  );
}

class ChatSession {
  final String id;
  String title;
  final DateTime createdAt;
  final List<Message> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'],
    title: json['title'],
    createdAt: DateTime.parse(json['createdAt']),
    messages: (json['messages'] as List).map((m) => Message.fromJson(m)).toList(),
  );
}
