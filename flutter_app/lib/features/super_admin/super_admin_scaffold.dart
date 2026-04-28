// Distinct scaffold for the super-admin section.
//
// Uses a darker color palette (slate + amber accent) so it's visually obvious
// you're operating across all tenants, not inside one. The sidebar lists only
// platform-wide screens (Overview / Companies / Users / Audit) and offers an
// explicit "Back to admin" exit.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../services/auth_service.dart';

// --- Super-admin palette (intentionally different from AppColors) -----------
class SuperColors {
  SuperColors._();
  static const Color bg          = Color(0xFF0F172A); // slate-900
  static const Color sidebar     = Color(0xFF1E293B); // slate-800
  static const Color sidebarHi   = Color(0xFF334155); // slate-700
  static const Color border      = Color(0xFF334155);
  static const Color content     = Color(0xFFF8FAFC); // slate-50
  static const Color text        = Color(0xFFE2E8F0); // slate-200
  static const Color textMuted   = Color(0xFF94A3B8); // slate-400
  static const Color accent      = Color(0xFFF59E0B); // amber-500
  static const Color accentSoft  = Color(0xFFFEF3C7); // amber-100
  static const Color danger      = Color(0xFFEF4444);
  static const Color success     = Color(0xFF10B981);
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem(this.label, this.icon, this.route);
}

const List<_NavItem> _navItems = [
  _NavItem('Overview',  Icons.bar_chart_outlined,  AppRoutes.superStats),
  _NavItem('Companies', Icons.apartment_outlined,  AppRoutes.superCompanies),
  _NavItem('Users',     Icons.group_outlined,      AppRoutes.superUsers),
  _NavItem('Audit log', Icons.receipt_long_outlined, AppRoutes.superAudit),
];

class SuperAdminScaffold extends StatelessWidget {
  final String currentRoute;
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const SuperAdminScaffold({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      backgroundColor: SuperColors.content,
      appBar: isWide
          ? null
          : AppBar(
              backgroundColor: SuperColors.bg,
              foregroundColor: SuperColors.text,
              title: Text(title),
              actions: actions,
            ),
      drawer: isWide ? null : Drawer(child: _Sidebar(currentRoute: currentRoute)),
      body: Row(
        children: [
          if (isWide)
            SizedBox(
              width: 240,
              child: _Sidebar(currentRoute: currentRoute),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isWide) _TopBar(title: title, actions: actions),
                Expanded(
                  child: Container(
                    color: SuperColors.content,
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  const _TopBar({required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String currentRoute;
  const _Sidebar({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SuperColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Brand ----------------------------------------------------
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: SuperColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      size: 18, color: Color(0xFF0F172A)),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Platform',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    Text('Super admin',
                        style: TextStyle(
                            color: SuperColors.accent,
                            fontSize: 11,
                            letterSpacing: 0.5)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: SuperColors.border),
          const SizedBox(height: 8),

          // ---- Nav items ------------------------------------------------
          ..._navItems.map((item) {
            final selected = currentRoute == item.route ||
                (item.route == AppRoutes.superStats &&
                    currentRoute == AppRoutes.superHome);
            return _NavTile(
              item: item,
              selected: selected,
              onTap: () => context.go(item.route),
            );
          }),

          const Spacer(),

          // ---- Footer: leave super-admin --------------------------------
          const Divider(height: 1, color: SuperColors.border),
          ListTile(
            leading: const Icon(Icons.arrow_back, color: SuperColors.textMuted),
            title: const Text('Back to admin',
                style: TextStyle(color: SuperColors.textMuted, fontSize: 14)),
            onTap: () => context.go(AppRoutes.dashboard),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: SuperColors.textMuted),
            title: const Text('Sign out',
                style: TextStyle(color: SuperColors.textMuted, fontSize: 14)),
            onTap: () async {
              await AuthService.instance.signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? SuperColors.sidebarHi : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(item.icon,
                    size: 18,
                    color: selected ? SuperColors.accent : SuperColors.textMuted),
                const SizedBox(width: 12),
                Text(item.label,
                    style: TextStyle(
                      color: selected ? Colors.white : SuperColors.text,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 14,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
