import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/admin_scaffold.dart';
import '../providers.dart';

class DashboardScreen extends ConsumerWidget {
  final String companyId;
  const DashboardScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider(companyId));
    final companyAsync   = ref.watch(companyProvider(companyId));
    final company = companyAsync.value;

    return AdminScaffold(
      companyId: companyId, currentRoute: AppRoutes.dashboard, title: 'Dashboard',
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (analytics) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Welcome back${company != null ? ', ${company.name}' : ''} 👋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.grey900)),
            const SizedBox(height: 4),
            const Text('Here\'s what\'s happening with your chatbot.', style: TextStyle(color: AppColors.grey400)),
            const SizedBox(height: 24),
            // KPI cards
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
              children: [
                _KpiCard('Total Sessions', '${analytics?.totalSessions ?? 0}', Icons.forum_rounded, AppColors.primary),
                _KpiCard('Total Messages', '${analytics?.totalMessages ?? 0}', Icons.chat_bubble_rounded, const Color(0xFF8B5CF6)),
                _KpiCard('Avg Satisfaction', analytics?.avgSatisfaction != null && analytics!.avgSatisfaction > 0 ? '${analytics.avgSatisfaction}/5' : '—', Icons.star_rounded, const Color(0xFFF59E0B)),
                _KpiCard('Human Handoffs', '${analytics?.handoffCount ?? 0}', Icons.transfer_within_a_station_rounded, const Color(0xFFEF4444)),
              ],
            ),
            const SizedBox(height: 24),
            // Quick actions
            const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.grey900)),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _ActionBtn('Manage Intents', Icons.psychology_rounded, () => context.go('${AppRoutes.intents}?companyId=$companyId')),
              _ActionBtn('Upload Documents', Icons.upload_file_rounded, () => context.go('${AppRoutes.documents}?companyId=$companyId')),
              _ActionBtn('View Analytics', Icons.analytics_rounded, () => context.go('${AppRoutes.analytics}?companyId=$companyId')),
              _ActionBtn('Unknown Questions', Icons.help_outline_rounded, () => context.go('${AppRoutes.unknownQuestions}?companyId=$companyId')),
              _ActionBtn('Embed Code', Icons.integration_instructions_rounded, () => context.go('${AppRoutes.embed}?companyId=$companyId')),
            ]),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _KpiCard(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.grey200)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18)),
        const Spacer(),
      ]),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grey400)),
    ]),
  );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn(this.label, this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    icon: Icon(icon, size: 16),
    label: Text(label, style: const TextStyle(fontSize: 13)),
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    onPressed: onTap,
  );
}
