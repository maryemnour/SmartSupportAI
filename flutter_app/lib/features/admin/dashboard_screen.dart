import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/admin_scaffold.dart';
import '../providers.dart';

class DashboardScreen extends ConsumerWidget {
  final String companyId;
  const DashboardScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider(companyId));

    return AdminScaffold(
      companyId: companyId,
      title: 'Dashboard',
      currentRoute: AppRoutes.dashboard,
      body: analytics.when(
        data: (data) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overview', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                
                // KPI Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.8,
                      children: [
                        _KpiCard('Total Sessions', '${data?.totalSessions ?? 0}', Icons.chat_bubble_outline, AppColors.primary),
                        _KpiCard('Total Messages', '${data?.totalMessages ?? 0}', Icons.message_outlined, AppColors.success),
                        _KpiCard('Avg Satisfaction', (data?.avgSatisfaction ?? 0).toStringAsFixed(1), Icons.star_outline, AppColors.warning),
                        _KpiCard('Active Intents', '${data?.activeIntents ?? 0}', Icons.psychology_outlined, AppColors.primary),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Quick Actions
                const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ActionButton(Icons.add, 'Add Intent', () => context.go('${AppRoutes.intents}?companyId=$companyId')),
                    _ActionButton(Icons.settings, 'Settings', () => context.go('${AppRoutes.settings}?companyId=$companyId')),
                    _ActionButton(Icons.analytics, 'Analytics', () => context.go('${AppRoutes.analytics}?companyId=$companyId')),
                    _ActionButton(Icons.help_outline, 'Unknown Questions', () => context.go('${AppRoutes.unknownQuestions}?companyId=$companyId')),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: AppColors.grey600))),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
