enum MessageSender { user, bot, agent }

class Message {
  final String id;
  final String sessionId;
  final String companyId;
  final String content;
  final MessageSender sender;
  final String? intentId;
  final bool isRead;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.sessionId,
    required this.companyId,
    required this.content,
    required this.sender,
    this.intentId,
    this.isRead = false,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
    id: j['id'],
    sessionId: j['session_id'],
    companyId: j['company_id'],
    content: j['content'],
    sender: MessageSender.values.firstWhere(
      (s) => s.name == j['sender'],
      orElse: () => MessageSender.bot,
    ),
    intentId: j['intent_id'],
    isRead: j['is_read'] ?? false,
    createdAt: DateTime.parse(j['created_at']),
  );
}
