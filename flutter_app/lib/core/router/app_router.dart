import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_routes.dart';
import '../constants/app_config.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/auth_screens.dart';
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
import '../../features/super_admin/super_admin_dashboard.dart';
import '../../features/super_admin/super_overview_screen.dart';
import '../../features/super_admin/super_companies_screen.dart';
import '../../features/super_admin/super_users_screen.dart';
import '../../features/super_admin/super_audit_screen.dart';
import '../../services/auth_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) async {
      final auth = Supabase.instance.client.auth;
      final isAuth = auth.currentUser != null;
      final path = state.matchedLocation;

      // Public routes
      final publicRoutes = [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.onboarding,
        AppRoutes.chat,
      ];
      if (publicRoutes.contains(path)) return null;

      // Require authentication
      if (!isAuth) return AppRoutes.login;

      // Super-admin route guard -- protect every /super* path AND the legacy
      // /super-admin path. Non-super-admin users get bounced to /dashboard.
      final isSuperPath =
          path == AppRoutes.superAdmin || path.startsWith(AppRoutes.superHome);
      if (isSuperPath) {
        final ok = await AuthService.instance.isSuperAdmin();
        if (!ok) return AppRoutes.dashboard;
        // /super or /super-admin -> normalize to /super/stats
        if (path == AppRoutes.superHome || path == AppRoutes.superAdmin) {
          return AppRoutes.superStats;
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),

      GoRoute(
        path: AppRoutes.chat,
        builder: (ctx, state) {
          final companyId = state.uri.queryParameters['companyId'] ?? AppConfig.defaultCompanyId;
          return ChatScreen(companyId: companyId);
        },
      ),

      GoRoute(
        path: AppRoutes.dashboard,
        builder: (ctx, state) => DashboardScreen(companyId: _cid(state)),
      ),

      GoRoute(
        path: AppRoutes.intents,
        builder: (ctx, state) => IntentManagementScreen(companyId: _cid(state)),
      ),

      GoRoute(
        path: AppRoutes.analytics,
        builder: (ctx, state) => AnalyticsScreen(companyId: _cid(state)),
      ),

      GoRoute(
        path: AppRoutes.settings,
        builder: (ctx, state) => SettingsScreen(companyId: _cid(state)),
      ),

      GoRoute(
        path: AppRoutes.unknownQuestions,
        builder: (ctx, state) => UnknownQuestionsScreen(companyId: _cid(state)),
      ),

      GoRoute(
        path: AppRoutes.sessions,
        builder: (ctx, state) => SessionsScreen(companyId: _cid(state)),
      ),

      GoRoute(
        path: AppRoutes.documents,
        builder: (ctx, state) => DocumentsScreen(companyId: _cid(state)),
      ),

      GoRoute(
        path: AppRoutes.embed,
        builder: (ctx, state) => EmbedScreen(companyId: _cid(state)),
      ),

      GoRoute(
        path: AppRoutes.botControls,
        builder: (ctx, state) => BotControlsScreen(companyId: _cid(state)),
      ),

      // ---- Super admin (separate scaffold + sub-routes) ----------------
      GoRoute(
        path: AppRoutes.superAdmin,
        builder: (_, __) => const SuperAdminDashboard(),
      ),
      GoRoute(
        path: AppRoutes.superHome,
        builder: (_, __) => const SuperAdminDashboard(),
      ),
      GoRoute(
        path: AppRoutes.superStats,
        builder: (_, __) => const SuperOverviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.superCompanies,
        builder: (_, __) => const SuperCompaniesScreen(),
      ),
      GoRoute(
        path: AppRoutes.superUsers,
        builder: (_, __) => const SuperUsersScreen(),
      ),
      GoRoute(
        path: AppRoutes.superAudit,
        builder: (_, __) => const SuperAuditScreen(),
      ),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});

String _cid(GoRouterState state) =>
    state.uri.queryParameters['companyId'] ?? AppConfig.defaultCompanyId;
