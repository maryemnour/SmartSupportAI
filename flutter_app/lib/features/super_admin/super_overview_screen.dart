import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_routes.dart';
import 'super_admin_scaffold.dart';
import 'super_providers.dart';

class SuperOverviewScreen extends ConsumerWidget {
  const SuperOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(platformStatsProvider);
    final companies = ref.watch(allCompaniesProvider);

    return SuperAdminScaffold(
      currentRoute: AppRoutes.superStats,
      title: 'Platform overview',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh, color: Color(0xFF0F172A)),
          onPressed: () {
            ref.invalidate(platformStatsProvider);
            ref.invalidate(allCompaniesProvider);
          },
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            stats.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _ErrorBox('Failed to load stats: $e'),
              data: (s) => _StatsGrid(stats: s),
            ),
            const SizedBox(height: 32),
            const Text('Plan distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            companies.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => _ErrorBox('$e'),
              data: (list) => _PlanBreakdown(companies: list),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _StatTile(
        label: 'Companies',
        value: '${stats['total_companies'] ?? 0}',
        icon: Icons.apartment_outlined,
        color: SuperColors.accent,
      ),
      _StatTile(
        label: 'Active',
        value: '${stats['active_companies'] ?? 0}',
        icon: Icons.check_circle_outline,
        color: SuperColors.success,
      ),
      _StatTile(
        label: 'Users',
        value: '${stats['total_users'] ?? 0}',
        icon: Icons.group_outlined,
        color: const Color(0xFF6366F1),
      ),
      _StatTile(
        label: 'Sessions',
        value: '${stats['total_sessions'] ?? 0}',
        icon: Icons.forum_outlined,
        color: const Color(0xFF06B6D4),
      ),
      _StatTile(
        label: 'Messages',
        value: '${stats['total_messages'] ?? 0}',
        icon: Icons.chat_bubble_outline,
        color: const Color(0xFF8B5CF6),
      ),
      _StatTile(
        label: 'Documents',
        value: '${stats['total_documents'] ?? 0}',
        icon: Icons.description_outlined,
        color: const Color(0xFFEC4899),
      ),
    ];
    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth >= 1100
          ? 6
          : c.maxWidth >= 800
              ? 3
              : 2;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
        children: tiles,
      );
    });
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
            ],
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A))),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _PlanBreakdown extends StatelessWidget {
  final List<Map<String, dynamic>> companies;
  const _PlanBreakdown({required this.companies});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final c in companies) {
      final p = (c['plan'] ?? 'free').toString();
      counts[p] = (counts[p] ?? 0) + 1;
    }
    final total = companies.length.clamp(1, 1 << 31);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: counts.entries.map((e) {
          final pct = (e.value / total * 100).toStringAsFixed(0);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(e.key.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: e.value / total,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation(
                          SuperColors.accent),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 70,
                  child: Text('${e.value}  ($pct%)',
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Color(0xFF64748B))),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String msg;
  const _ErrorBox(this.msg);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(msg, style: const TextStyle(color: SuperColors.danger)),
    );
  }
}
