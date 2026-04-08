import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_screens.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/admin/dashboard_screen.dart';
import '../../features/admin/intent_management_screen.dart';
import '../../features/admin/analytics_screen.dart';
import '../../features/admin/settings_screen.dart';
import '../../features/admin/unknown_questions_screen.dart';
import '../../features/admin/documents_screen.dart';
import '../../features/admin/embed_screen.dart';
import '../../features/admin/bot_controls_screen.dart';
import '../../features/sessions/sessions_screen.dart';
import '../../services/supabase_service.dart';
import '../constants/app_routes.dart';
import '../constants/app_config.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final pub = [AppRoutes.splash, AppRoutes.login, AppRoutes.register, AppRoutes.onboarding, AppRoutes.chat];
      if (pub.contains(state.matchedLocation)) return null;
      if (!SupabaseService.instance.isAuthenticated) return AppRoutes.login;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash,      builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login,       builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register,    builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.onboarding,  builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.chat,        builder: (ctx, state) => ChatScreen(companyId: state.uri.queryParameters['companyId'] ?? AppConfig.defaultCompanyId)),
      GoRoute(path: AppRoutes.dashboard,   builder: (ctx, state) => DashboardScreen(companyId: _cid(state))),
      GoRoute(path: AppRoutes.intents,     builder: (ctx, state) => IntentManagementScreen(companyId: _cid(state))),
      GoRoute(path: AppRoutes.analytics,   builder: (ctx, state) => AnalyticsScreen(companyId: _cid(state))),
      GoRoute(path: AppRoutes.settings,    builder: (ctx, state) => SettingsScreen(companyId: _cid(state))),
      GoRoute(path: AppRoutes.unknownQuestions, builder: (ctx, state) => UnknownQuestionsScreen(companyId: _cid(state))),
      GoRoute(path: AppRoutes.sessions,    builder: (ctx, state) => SessionsScreen(companyId: _cid(state))),
      GoRoute(path: AppRoutes.documents,   builder: (ctx, state) => DocumentsScreen(companyId: _cid(state))),
      GoRoute(path: AppRoutes.embed,       builder: (ctx, state) => EmbedScreen(companyId: _cid(state))),
      GoRoute(path: AppRoutes.botControls, builder: (ctx, state) => BotControlsScreen(companyId: _cid(state))),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});

String _cid(GoRouterState s) =>
    s.uri.queryParameters['companyId'] ?? AppConfig.defaultCompanyId;
