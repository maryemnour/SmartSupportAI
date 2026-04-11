import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../repositories/repositories.dart';
import '../../services/chat_logic_service.dart';
import '../../services/offline_cache_service.dart';
import '../../core/constants/app_constants.dart';

class ChatState {
  final List<Message> messages;
  final bool isTyping;
  final bool isHandoffTriggered;
  final String? sessionId;
  final String? visitorId;
  final int failureCount;
  final Company? company;
  final List<Intent> intents;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [], this.isTyping = false,
    this.isHandoffTriggered = false, this.sessionId,
    this.visitorId, this.failureCount = 0, this.company,
    this.intents = const [], this.isLoading = false, this.error,
  });

  ChatState copyWith({
    List<Message>? messages, bool? isTyping, bool? isHandoffTriggered,
    String? sessionId, String? visitorId, int? failureCount,
    Company? company, List<Intent>? intents, bool? isLoading, String? error,
  }) => ChatState(
    messages: messages ?? this.messages, isTyping: isTyping ?? this.isTyping,
    isHandoffTriggered: isHandoffTriggered ?? this.isHandoffTriggered,
    sessionId: sessionId ?? this.sessionId, visitorId: visitorId ?? this.visitorId,
    failureCount: failureCount ?? this.failureCount, company: company ?? this.company,
    intents: intents ?? this.intents, isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
  );
}

class ChatController extends StateNotifier<ChatState> {
  final ChatRepository _chatRepo;
  final IntentRepository _intentRepo;
  final UnknownQuestionRepository _uqRepo;
  final CompanyRepository _companyRepo;
  final ChatLogicService _logic;
  final OfflineCacheService _cache;
  final String _companyId;

  ChatController({
    required ChatRepository chatRepo, required IntentRepository intentRepo,
    required UnknownQuestionRepository uqRepo, required CompanyRepository companyRepo,
    required String companyId,
  }) : _chatRepo = chatRepo, _intentRepo = intentRepo, _uqRepo = uqRepo,
       _companyRepo = companyRepo, _logic = ChatLogicService.instance,
       _cache = OfflineCacheService.instance, _companyId = companyId,
       super(const ChatState());

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      final company = await _companyRepo.getCompany(_companyId);
      List<Intent> intents;
      try {
        intents = await _intentRepo.getIntents(_companyId);
        await _cache.cacheIntents(_companyId, intents);
        await _logic.trainML(_companyId, intents);
      } catch (_) {
        intents = _cache.getCachedIntents(_companyId) ?? [];
      }

      var visitorId = _cache.getVisitorId() ?? const Uuid().v4();
      await _cache.saveVisitorId(visitorId);

      final cachedSession = _cache.getSessionId(_companyId);
      String sessionId;
      if (cachedSession != null) {
        sessionId = cachedSession;
        try {
          final msgs = await _chatRepo.getMessages(sessionId);
          state = state.copyWith(messages: msgs, company: company, intents: intents, visitorId: visitorId, sessionId: sessionId, isLoading: false);
          return;
        } catch (_) {}
      }

      final session = await _chatRepo.createSession(companyId: _companyId, visitorId: visitorId);
      sessionId = session.id;
      await _cache.saveSessionId(_companyId, sessionId);

      final welcome = Message(
        id: const Uuid().v4(), sessionId: sessionId, companyId: _companyId,
        content: company?.welcomeMessage ?? 'Hello! How can I help you?',
        sender: MessageSender.bot, createdAt: DateTime.now(),
      );
      state = state.copyWith(company: company, intents: intents, visitorId: visitorId, sessionId: sessionId, messages: [welcome], isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || state.sessionId == null) return;
    final sessionId = state.sessionId!;

    final userMsg = Message(
      id: const Uuid().v4(), sessionId: sessionId, companyId: _companyId,
      content: content, sender: MessageSender.user, createdAt: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, userMsg], isTyping: true);

    try {
      await _chatRepo.sendMessage(sessionId: sessionId, companyId: _companyId, content: content, sender: MessageSender.user);
    } catch (_) {
      await _cache.savePendingMessage(_companyId, userMsg);
    }

    await Future.delayed(Duration(milliseconds: AppConstants.typingDelayMs));

    String botResponse;
    String? matchedIntentId;
    int newFailures = state.failureCount;

    // Stage 1 + 2: Rule-based
    final ruleResult = _logic.detectIntent(content, state.intents);
    if (ruleResult.matched) {
      botResponse = ruleResult.intent!.response;
      matchedIntentId = ruleResult.intent!.id;
      newFailures = 0;
    } else {
      // Stage 3: ML
      final mlResult = await _logic.askML(message: content, companyId: _companyId, intents: state.intents);
      if (mlResult.matched) {
        botResponse = mlResult.intent!.response;
        matchedIntentId = mlResult.intent!.id;
        newFailures = 0;
      } else {
        // Stage 4: AI
        final aiResponse = await _logic.askAI(message: content, company: state.company, history: state.messages);
        if (aiResponse != null) {
          botResponse = aiResponse;
          await _uqRepo.record(companyId: _companyId, question: content, sessionId: sessionId);
        } else {
          newFailures++;
          await _uqRepo.record(companyId: _companyId, question: content, sessionId: sessionId);
          if (newFailures >= AppConstants.maxFailuresBeforeHandoff && !state.isHandoffTriggered) {
            botResponse = _logic.handoffMessage(email: state.company?.supportEmail, whatsapp: state.company?.whatsappNumber);
            try { await _chatRepo.triggerHandoff(sessionId); } catch (_) {}
            state = state.copyWith(isHandoffTriggered: true);
          } else {
            botResponse = _logic.fallback;
          }
        }
      }
    }

    final botMsg = Message(
      id: const Uuid().v4(), sessionId: sessionId, companyId: _companyId,
      content: botResponse, sender: MessageSender.bot,
      intentId: matchedIntentId, createdAt: DateTime.now(),
    );

    try {
      await _chatRepo.sendMessage(sessionId: sessionId, companyId: _companyId, content: botResponse, sender: MessageSender.bot, intentId: matchedIntentId);
    } catch (_) {}

    state = state.copyWith(messages: [...state.messages, botMsg], isTyping: false, failureCount: newFailures);
  }

  Future<void> submitRating(int score, {String? comment}) async {
    if (state.sessionId == null) return;
    try {
      await _chatRepo.submitRating(sessionId: state.sessionId!, companyId: _companyId, score: score, comment: comment);
    } catch (_) {}
  }
}

final chatControllerProvider = StateNotifierProvider.family<ChatController, ChatState, String>(
  (ref, companyId) {
    final ctrl = ChatController(
      chatRepo: ChatRepository(), intentRepo: IntentRepository(),
      uqRepo: UnknownQuestionRepository(), companyRepo: CompanyRepository(),
      companyId: companyId,
    );
    ctrl.initialize();
    return ctrl;
  },
);
