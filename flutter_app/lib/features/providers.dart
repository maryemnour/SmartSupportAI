import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/repositories.dart';
import '../models/models.dart';

final companyRepoProvider = Provider((_) => CompanyRepository());
final intentRepoProvider  = Provider((_) => IntentRepository());
final chatRepoProvider    = Provider((_) => ChatRepository());
final uqRepoProvider      = Provider((_) => UnknownQuestionRepository());
final analyticsRepoProvider = Provider((_) => AnalyticsRepository());

final companyProvider = FutureProvider.family<Company?, String>((ref, id) =>
    ref.read(companyRepoProvider).getCompany(id));

final intentsProvider = FutureProvider.family<List<Intent>, String>((ref, companyId) =>
    ref.read(intentRepoProvider).getIntents(companyId));

final analyticsProvider = FutureProvider.family<CompanyAnalytics?, String>((ref, companyId) =>
    ref.read(analyticsRepoProvider).getAnalytics(companyId));

final sessionsProvider = FutureProvider.family<List<ChatSession>, String>((ref, companyId) =>
    ref.read(chatRepoProvider).getSessions(companyId));

final unknownQuestionsProvider = FutureProvider.family<List<UnknownQuestion>, String>((ref, companyId) =>
    ref.read(uqRepoProvider).getQuestions(companyId));
