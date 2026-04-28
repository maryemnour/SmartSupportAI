class AppRoutes {
  AppRoutes._();
  static const String splash           = '/';
  static const String login            = '/login';
  static const String register         = '/register';
  static const String onboarding       = '/onboarding';
  static const String chat             = '/chat';
  static const String dashboard        = '/dashboard';
  static const String intents          = '/intents';
  static const String analytics        = '/analytics';
  static const String settings         = '/settings';
  static const String unknownQuestions = '/unknown-questions';
  static const String sessions         = '/sessions';
  static const String documents        = '/documents';
  static const String embed            = '/embed';
  static const String botControls      = '/bot-controls';

  // Super admin -- platform-wide tools, separate scaffold + sub-routes.
  static const String superAdmin       = '/super-admin';     // legacy, redirects to superHome
  static const String superHome        = '/super';           // landing -> superStats
  static const String superStats       = '/super/stats';
  static const String superCompanies   = '/super/companies';
  static const String superUsers       = '/super/users';
  static const String superAudit       = '/super/audit';
}
