class CompanyAnalytics {
  final int totalSessions;
  final int totalMessages;
  final int unansweredQuestions;
  final double avgSatisfaction;
  final int handoffCount;
  final int activeIntents;

  const CompanyAnalytics({
    this.totalSessions = 0,
    this.totalMessages = 0,
    this.unansweredQuestions = 0,
    this.avgSatisfaction = 0,
    this.handoffCount = 0,
    this.activeIntents = 0,
  });

  factory CompanyAnalytics.fromJson(Map<String, dynamic> j) => CompanyAnalytics(
    totalSessions: j['total_sessions'] ?? 0,
    totalMessages: j['total_messages'] ?? 0,
    unansweredQuestions: j['unanswered_questions'] ?? 0,
    avgSatisfaction: (j['avg_satisfaction'] ?? 0).toDouble(),
    handoffCount: j['handoff_count'] ?? 0,
    activeIntents: j['active_intents'] ?? 0,
  );
}
