import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_config.dart';

enum MatchStrategy { exact, similarity, keyword, ml, ai, none }

class IntentMatchResult {
  final Intent? intent;
  final double confidence;
  final MatchStrategy strategy;
  const IntentMatchResult({this.intent, required this.confidence, required this.strategy});
  bool get matched => intent != null && confidence >= AppConstants.similarityThreshold;
}

class ChatLogicService {
  ChatLogicService._();
  static final ChatLogicService instance = ChatLogicService._();

  // ── Stage 1 + 2: Rule-based ──────────────────────────────
  IntentMatchResult detectIntent(String message, List<Intent> intents) {
    final norm   = _normalize(message);
    final active = intents.where((i) => i.isActive).toList();

    // Exact match
    for (final i in active) {
      for (final p in i.trainingPhrases) {
        if (_normalize(p) == norm) {
          return IntentMatchResult(intent: i, confidence: 1.0, strategy: MatchStrategy.exact);
        }
      }
    }

    // Levenshtein similarity
    double bestScore = 0; Intent? bestIntent;
    for (final i in active) {
      for (final p in i.trainingPhrases) {
        final s = _similarity(_normalize(p), norm);
        if (s > bestScore) { bestScore = s; bestIntent = i; }
      }
    }
    if (bestScore >= AppConstants.similarityThreshold) {
      return IntentMatchResult(intent: bestIntent, confidence: bestScore, strategy: MatchStrategy.similarity);
    }

    // Keyword overlap
    final inputWords = norm.split(RegExp(r'\s+')).toSet();
    bestScore = 0; bestIntent = null;
    for (final i in active) {
      for (final p in i.trainingPhrases) {
        final pw = _normalize(p).split(RegExp(r'\s+')).toSet();
        if (pw.isEmpty) continue;
        final score = inputWords.intersection(pw).length / pw.length;
        if (score > bestScore) { bestScore = score; bestIntent = i; }
      }
    }
    if (bestScore >= AppConstants.keywordThreshold) {
      return IntentMatchResult(intent: bestIntent, confidence: bestScore, strategy: MatchStrategy.keyword);
    }

    return const IntentMatchResult(confidence: 0, strategy: MatchStrategy.none);
  }

  // ── Stage 3: ML Model ────────────────────────────────────
  Future<IntentMatchResult> askML({
    required String message, required String companyId, required List<Intent> intents,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.mlApiUrl}/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'company_id': companyId, 'message': message, 'threshold': 0.3}),
      ).timeout(const Duration(seconds: 3));
      if (res.statusCode != 200) return _noMatch();
      final data = jsonDecode(res.body);
      if (data['matched'] != true) return _noMatch();
      final intentId = data['intent_id'] as String?;
      final matched = intents.firstWhere(
        (i) => i.id == intentId,
        orElse: () => Intent(
          id: intentId ?? '', companyId: companyId,
          name: data['intent_name'] ?? '', trainingPhrases: [],
          response: data['response'] ?? '',
          createdAt: DateTime.now(), updatedAt: DateTime.now(),
        ),
      );
      return IntentMatchResult(
        intent: matched,
        confidence: (data['confidence'] as num).toDouble(),
        strategy: MatchStrategy.ml,
      );
    } catch (_) { return _noMatch(); }
  }

  // ── Stage 4: GPT-4o-mini + personality + multilingual ────
  Future<String?> askAI({
    required String message,
    required Company? company,
    required List<Message> history,
  }) async {
    try {
      final res = await Supabase.instance.client.functions.invoke('ai-chat', body: {
        'message': message,
        'companyId': company?.id,
        'companyName': company?.name ?? 'Support',
        'welcomeMessage': company?.welcomeMessage,
        'personality': company?.botPersonality ?? 'friendly',
        'conversationHistory': history.take(6).map((m) => {
          'sender': m.sender.name, 'content': m.content,
        }).toList(),
      });
      if (res.data?['fallback'] == true) return null;
      final text = res.data?['response'] as String?;
      return text?.isNotEmpty == true ? text : null;
    } catch (_) { return null; }
  }

  // ── Train ML ─────────────────────────────────────────────
  Future<void> trainML(String companyId, List<Intent> intents) async {
    try {
      await http.post(
        Uri.parse('${AppConfig.mlApiUrl}/train'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'company_id': companyId,
          'intents': intents
              .where((i) => i.isActive && i.trainingPhrases.isNotEmpty)
              .map((i) => {
                'id': i.id, 'name': i.name,
                'training_phrases': i.trainingPhrases, 'response': i.response,
              }).toList(),
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // ── Helpers ──────────────────────────────────────────────
  String handoffMessage({String? email, String? whatsapp}) {
    final parts = ["I'm sorry, I couldn't fully answer your question. Let me connect you with our team."];
    if (whatsapp != null) parts.add('📱 WhatsApp: $whatsapp');
    if (email != null)    parts.add('📧 Email: $email');
    return parts.join('\n\n');
  }

  String get fallback => "I didn't quite understand that. Could you rephrase your question?";

  String _normalize(String t) =>
      t.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ');

  double _similarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final d = _levenshtein(a, b);
    return 1.0 - d / (a.length > b.length ? a.length : b.length);
  }

  int _levenshtein(String s, String t) {
    final m = s.length, n = t.length;
    final dp = List.generate(m + 1, (i) => List.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) dp[i][0] = i;
    for (var j = 0; j <= n; j++) dp[0][j] = j;
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        final c = s[i - 1] == t[j - 1] ? 0 : 1;
        dp[i][j] = [dp[i-1][j]+1, dp[i][j-1]+1, dp[i-1][j-1]+c].reduce((a, b) => a < b ? a : b);
      }
    }
    return dp[m][n];
  }

  IntentMatchResult _noMatch() => const IntentMatchResult(confidence: 0, strategy: MatchStrategy.none);
}
