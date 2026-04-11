import 'package:flutter/material.dart';

// ── Company ──────────────────────────────────────────────────
class Company {
  final String id;
  final String name;
  final String? logoUrl;
  final String primaryColor;
  final String welcomeMessage;
  final String? supportEmail;
  final String? whatsappNumber;
  final String? apiKey;
  final String plan;
  final bool isActive;
  final DateTime createdAt;

  const Company({
    required this.id, required this.name, this.logoUrl,
    this.primaryColor = '#6366F1',
    this.welcomeMessage = 'Hello! How can I help you today?',
    this.supportEmail, this.whatsappNumber, this.apiKey,
    this.plan = 'free', this.isActive = true, required this.createdAt,
  });

  Color get color {
    try { return Color(int.parse('FF${primaryColor.replaceAll('#','')}', radix: 16)); }
    catch (_) { return const Color(0xFF6366F1); }
  }

  factory Company.fromJson(Map<String, dynamic> j) => Company(
    id: j['id'], name: j['name'], logoUrl: j['logo_url'],
    primaryColor: j['primary_color'] ?? '#6366F1',
    welcomeMessage: j['welcome_message'] ?? 'Hello! How can I help you today?',
    supportEmail: j['support_email'], whatsappNumber: j['whatsapp_number'],
    apiKey: j['api_key'], plan: j['plan'] ?? 'free',
    isActive: j['is_active'] ?? true,
    createdAt: DateTime.parse(j['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'logo_url': logoUrl,
    'primary_color': primaryColor, 'welcome_message': welcomeMessage,
    'support_email': supportEmail, 'whatsapp_number': whatsappNumber,
    'api_key': apiKey, 'plan': plan, 'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };
}

// ── AppUser ──────────────────────────────────────────────────
class AppUser {
  final String id;
  final String? companyId;
  final String role;
  final String email;
  final String? fullName;
  final DateTime createdAt;

  const AppUser({
    required this.id, this.companyId, this.role = 'admin',
    required this.email, this.fullName, required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'], companyId: j['company_id'], role: j['role'] ?? 'admin',
    email: j['email'] ?? '', fullName: j['full_name'],
    createdAt: DateTime.parse(j['created_at']),
  );
}

// ── Intent ───────────────────────────────────────────────────
class Intent {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final List<String> trainingPhrases;
  final String response;
  final String category;
  final bool isActive;
  final int matchCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Intent({
    required this.id, required this.companyId, required this.name,
    this.description, required this.trainingPhrases, required this.response,
    this.category = 'general', this.isActive = true, this.matchCount = 0,
    required this.createdAt, required this.updatedAt,
  });

  factory Intent.fromJson(Map<String, dynamic> j) => Intent(
    id: j['id'], companyId: j['company_id'], name: j['name'],
    description: j['description'],
    trainingPhrases: List<String>.from(j['training_phrases'] ?? []),
    response: j['response'] ?? '', category: j['category'] ?? 'general',
    isActive: j['is_active'] ?? true, matchCount: j['match_count'] ?? 0,
    createdAt: DateTime.parse(j['created_at']),
    updatedAt: DateTime.parse(j['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'company_id': companyId, 'name': name,
    'description': description, 'training_phrases': trainingPhrases,
    'response': response, 'category': category, 'is_active': isActive,
  };
}

// ── ChatSession ──────────────────────────────────────────────
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
    required this.id, required this.companyId, required this.visitorId,
    this.visitorName, this.status = 'active', this.handoffTriggered = false,
    this.failureCount = 0, this.messageCount = 0,
    required this.startedAt, this.endedAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> j) => ChatSession(
    id: j['id'], companyId: j['company_id'], visitorId: j['visitor_id'],
    visitorName: j['visitor_name'], status: j['status'] ?? 'active',
    handoffTriggered: j['handoff_triggered'] ?? false,
    failureCount: j['failure_count'] ?? 0, messageCount: j['message_count'] ?? 0,
    startedAt: DateTime.parse(j['started_at']),
    endedAt: j['ended_at'] != null ? DateTime.parse(j['ended_at']) : null,
  );
}

// ── Message ──────────────────────────────────────────────────
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
    required this.id, required this.sessionId, required this.companyId,
    required this.content, required this.sender, this.intentId,
    this.isRead = false, required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
    id: j['id'], sessionId: j['session_id'], companyId: j['company_id'],
    content: j['content'],
    sender: MessageSender.values.firstWhere(
      (s) => s.name == j['sender'], orElse: () => MessageSender.bot),
    intentId: j['intent_id'], isRead: j['is_read'] ?? false,
    createdAt: DateTime.parse(j['created_at']),
  );
}

// ── UnknownQuestion ──────────────────────────────────────────
class UnknownQuestion {
  final String id;
  final String companyId;
  final String? sessionId;
  final String question;
  final int frequency;
  final String status;
  final DateTime createdAt;

  const UnknownQuestion({
    required this.id, required this.companyId, this.sessionId,
    required this.question, this.frequency = 1, this.status = 'pending',
    required this.createdAt,
  });

  factory UnknownQuestion.fromJson(Map<String, dynamic> j) => UnknownQuestion(
    id: j['id'], companyId: j['company_id'], sessionId: j['session_id'],
    question: j['question'], frequency: j['frequency'] ?? 1,
    status: j['status'] ?? 'pending',
    createdAt: DateTime.parse(j['created_at']),
  );
}

// ── CompanyAnalytics ─────────────────────────────────────────
class CompanyAnalytics {
  final int totalSessions;
  final int totalMessages;
  final int unansweredQuestions;
  final double avgSatisfaction;
  final int handoffCount;
  final int activeIntents;

  const CompanyAnalytics({
    this.totalSessions = 0, this.totalMessages = 0,
    this.unansweredQuestions = 0, this.avgSatisfaction = 0,
    this.handoffCount = 0, this.activeIntents = 0,
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
