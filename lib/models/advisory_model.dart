class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> sources;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.sources = const [],
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, {bool isUser = false}) {
    return ChatMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['conversational_response']?.toString() ?? json['answer']?.toString() ?? json['message']?.toString() ?? '',
      isUser: isUser,
      timestamp: DateTime.now(),
      sources: (json['sources'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
