class UnknownQuestion {
  final String id;
  final String companyId;
  final String? sessionId;
  final String question;
  final int frequency;
  final String status;
  final DateTime createdAt;

  const UnknownQuestion({
    required this.id,
    required this.companyId,
    this.sessionId,
    required this.question,
    this.frequency = 1,
    this.status = 'pending',
    required this.createdAt,
  });

  factory UnknownQuestion.fromJson(Map<String, dynamic> j) => UnknownQuestion(
    id: j['id'],
    companyId: j['company_id'],
    sessionId: j['session_id'],
    question: j['question'],
    frequency: j['frequency'] ?? 1,
    status: j['status'] ?? 'pending',
    createdAt: DateTime.parse(j['created_at']),
  );
}
