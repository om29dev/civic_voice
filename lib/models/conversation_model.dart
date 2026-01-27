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
