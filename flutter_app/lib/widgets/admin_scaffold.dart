import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';

class AdminScaffold extends StatelessWidget {
  final String companyId;
  final String title;
  final Widget body;
  final String currentRoute;
  final List<Widget>? actions;
  final Widget? fab;

  const AdminScaffold({
    super.key, required this.companyId, required this.title,
    required this.body, required this.currentRoute,
    this.actions, this.fab,
  });

  static const _navItems = [
    _Nav(Icons.dashboard_rounded,         'Dashboard',         AppRoutes.dashboard),
    _Nav(Icons.psychology_rounded,        'Intents',           AppRoutes.intents),
    _Nav(Icons.upload_file_rounded,       'Knowledge Base',    AppRoutes.documents),
    _Nav(Icons.analytics_rounded,         'Analytics',         AppRoutes.analytics),
    _Nav(Icons.help_outline_rounded,      'Unknown Questions', AppRoutes.unknownQuestions),
    _Nav(Icons.forum_rounded,             'Sessions',          AppRoutes.sessions),
    _Nav(Icons.integration_instructions_rounded, 'Embed / API Key', AppRoutes.embed),
    _Nav(Icons.tune_rounded,              'Bot Controls',      AppRoutes.botControls),
    _Nav(Icons.settings_rounded,          'Settings',          AppRoutes.settings),
    _Nav(Icons.chat_rounded,              'Preview Chat',      AppRoutes.chat),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...?actions,
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      drawer: isWide ? null : _Drawer(companyId: companyId, current: currentRoute),
      body: isWide
          ? Row(children: [
              _Rail(companyId: companyId, current: currentRoute),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ])
          : body,
      floatingActionButton: fab,
    );
  }
}

class _Rail extends StatelessWidget {
  final String companyId, current;
  const _Rail({required this.companyId, required this.current});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: ListView(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      children: AdminScaffold._navItems.map((n) => _NavTile(nav: n, companyId: companyId, current: current)).toList(),
    ),
  );
}

class _Drawer extends StatelessWidget {
  final String companyId, current;
  const _Drawer({required this.companyId, required this.current});

  @override
  Widget build(BuildContext context) => Drawer(
    child: ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Smart Support AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
        ),
        ...AdminScaffold._navItems.map((n) => _NavTile(nav: n, companyId: companyId, current: current)),
      ],
    ),
  );
}

class _NavTile extends StatelessWidget {
  final _Nav nav;
  final String companyId, current;
  const _NavTile({required this.nav, required this.companyId, required this.current});

  @override
  Widget build(BuildContext context) {
    final active = current == nav.route;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(nav.icon, color: active ? AppColors.primary : AppColors.grey400, size: 20),
        title: Text(nav.label, style: TextStyle(
          fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? AppColors.primary : AppColors.grey600,
        )),
        dense: true,
        onTap: () {
          if (Navigator.canPop(context)) Navigator.pop(context);
          if (nav.route == AppRoutes.chat) {
            context.go('${nav.route}?companyId=$companyId');
          } else {
            context.go('${nav.route}?companyId=$companyId');
          }
        },
      ),
    );
  }
}

class _Nav {
  final IconData icon;
  final String label, route;
  const _Nav(this.icon, this.label, this.route);
}
