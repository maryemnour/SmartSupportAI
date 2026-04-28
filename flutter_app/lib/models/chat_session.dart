class ChatSession {
  final String id;
  final String companyId;
  final String visitorId;
  final String? visitorName;
  final String status;
  final bool handoffTriggered;
  final int failureCount;
  final int messageCount;
  final DateTime startedAt;
  final DateTime? endedAt;

  const ChatSession({
    required this.id,
    required this.companyId,
    required this.visitorId,
    this.visitorName,
    this.status = 'active',
    this.handoffTriggered = false,
    this.failureCount = 0,
    this.messageCount = 0,
    required this.startedAt,
    this.endedAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> j) => ChatSession(
    id: j['id'],
    companyId: j['company_id'],
    visitorId: j['visitor_id'],
    visitorName: j['visitor_name'],
    status: j['status'] ?? 'active',
    handoffTriggered: j['handoff_triggered'] ?? false,
    failureCount: j['failure_count'] ?? 0,
    messageCount: j['message_count'] ?? 0,
    startedAt: DateTime.parse(j['started_at']),
    endedAt: j['ended_at'] != null ? DateTime.parse(j['ended_at']) : null,
  );
}
