enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final String userId;
  final MessageRole role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    String? id,
    this.userId = 'default_user',
    required this.role,
    required this.content,
    required this.timestamp,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  bool get isUser => role == MessageRole.user;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    try {
      final dynamic roleData = json['role'];
      MessageRole role = MessageRole.user;
      if (roleData is String) {
        final String roleStr = roleData.toLowerCase();
        if (roleStr == 'assistant' || roleStr == 'model') {
          role = MessageRole.assistant;
        } else {
          role = MessageRole.user;
        }
      }

      return ChatMessage(
        id: (json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
        userId: (json['userId'] ?? 'default_user').toString(),
        role: role,
        content: (json['content'] ?? '').toString(),
        timestamp: json['timestamp'] != null 
            ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    } catch (e) {
      return ChatMessage(
        role: MessageRole.assistant,
        content: 'Error loading this message.',
        timestamp: DateTime.now(),
      );
    }
  }
}
