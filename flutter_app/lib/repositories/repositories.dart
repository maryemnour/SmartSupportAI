import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

final _sb = Supabase.instance.client;

// ── Company ──────────────────────────────────────────────────
class CompanyRepository {
  Future<Company?> getCompany(String id) async {
    final res = await _sb.from('companies').select().eq('id', id).maybeSingle();
    return res != null ? Company.fromJson(res) : null;
  }

  Future<Company?> getCompanyByUser(String userId) async {
    final user = await _sb.from('users').select('company_id').eq('id', userId).maybeSingle();
    if (user == null || user['company_id'] == null) return null;
    return getCompany(user['company_id']);
  }

  Future<void> updateCompany(String id, Map<String, dynamic> data) async {
    await _sb.from('companies').update(data).eq('id', id);
  }
}

// ── Intent ───────────────────────────────────────────────────
class IntentRepository {
  Future<List<Intent>> getIntents(String companyId) async {
    final res = await _sb.from('intents')
        .select().eq('company_id', companyId).order('created_at');
    return (res as List).map((e) => Intent.fromJson(e)).toList();
  }

  Future<Intent> createIntent(Map<String, dynamic> data) async {
    final res = await _sb.from('intents').insert(data).select().single();
    return Intent.fromJson(res);
  }

  Future<void> updateIntent(String id, Map<String, dynamic> data) async {
    await _sb.from('intents').update(data).eq('id', id);
  }

  Future<void> deleteIntent(String id) async {
    await _sb.from('intents').delete().eq('id', id);
  }
}

// ── Chat ─────────────────────────────────────────────────────
class ChatRepository {
  Future<ChatSession> createSession({
    required String companyId,
    required String visitorId,
  }) async {
    final res = await _sb.from('chat_sessions').insert({
      'company_id': companyId, 'visitor_id': visitorId, 'status': 'active',
    }).select().single();
    return ChatSession.fromJson(res);
  }

  Future<List<Message>> getMessages(String sessionId) async {
    final res = await _sb.from('messages')
        .select().eq('session_id', sessionId).order('created_at');
    return (res as List).map((e) => Message.fromJson(e)).toList();
  }

  Future<void> sendMessage({
    required String sessionId,
    required String companyId,
    required String content,
    required MessageSender sender,
    String? intentId,
  }) async {
    await _sb.from('messages').insert({
      'session_id': sessionId, 'company_id': companyId,
      'content': content, 'sender': sender.name, 'intent_id': intentId,
    });
  }

  Future<void> triggerHandoff(String sessionId) async {
    await _sb.from('chat_sessions')
        .update({'status': 'handed_off', 'handoff_triggered': true})
        .eq('id', sessionId);
  }

  Future<void> submitRating({
    required String sessionId,
    required String companyId,
    required int score,
    String? comment,
  }) async {
    await _sb.from('ratings').upsert({
      'session_id': sessionId, 'company_id': companyId,
      'score': score, 'comment': comment,
    });
  }

  Future<List<ChatSession>> getSessions(String companyId) async {
    final res = await _sb.from('chat_sessions')
        .select().eq('company_id', companyId)
        .order('started_at', ascending: false).limit(50);
    return (res as List).map((e) => ChatSession.fromJson(e)).toList();
  }
}

// ── UnknownQuestion ──────────────────────────────────────────
class UnknownQuestionRepository {
  Future<void> record({
    required String companyId,
    required String question,
    String? sessionId,
  }) async {
    try {
      await _sb.from('unknown_questions').insert({
        'company_id': companyId, 'question': question, 'session_id': sessionId,
      });
    } catch (_) {}
  }

  Future<List<UnknownQuestion>> getQuestions(String companyId) async {
    final res = await _sb.from('unknown_questions')
        .select().eq('company_id', companyId).eq('status', 'pending')
        .order('frequency', ascending: false);
    return (res as List).map((e) => UnknownQuestion.fromJson(e)).toList();
  }

  Future<void> updateStatus(String id, String status) async {
    await _sb.from('unknown_questions').update({'status': status}).eq('id', id);
  }
}

// ── Analytics ────────────────────────────────────────────────
class AnalyticsRepository {
  Future<CompanyAnalytics?> getAnalytics(String companyId) async {
    final res = await _sb.from('company_analytics')
        .select().eq('company_id', companyId).maybeSingle();
    return res != null ? CompanyAnalytics.fromJson(res) : null;
  }

  Future<List<Map<String, dynamic>>> getDailySessions(String companyId) async {
    final res = await _sb.from('daily_session_counts')
        .select().eq('company_id', companyId).limit(30);
    return List<Map<String, dynamic>>.from(res);
  }
}
