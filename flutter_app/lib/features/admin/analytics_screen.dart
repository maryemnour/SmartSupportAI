import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/admin_scaffold.dart';
import '../providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  final String companyId;
  const AnalyticsScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider(companyId));

    return AdminScaffold(
      companyId: companyId,
      title: 'Analytics',
      currentRoute: AppRoutes.analytics,
      body: analytics.when(
        data: (data) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Performance Metrics', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.8,
                      children: [
                        _MetricCard('Total Sessions', '${data?.totalSessions ?? 0}', Icons.chat_outlined, AppColors.primary),
                        _MetricCard('Total Messages', '${data?.totalMessages ?? 0}', Icons.message_outlined, AppColors.success),
                        _MetricCard('Unanswered', '${data?.unansweredQuestions ?? 0}', Icons.help_outline, AppColors.warning),
                        _MetricCard('Satisfaction', '${(data?.avgSatisfaction ?? 0).toStringAsFixed(1)}/5', Icons.star_outlined, AppColors.warning),
                        _MetricCard('Handoffs', '${data?.handoffCount ?? 0}', Icons.support_agent_outlined, AppColors.error),
                        _MetricCard('Active Intents', '${data?.activeIntents ?? 0}', Icons.psychology_outlined, AppColors.primary),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sessions Over Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: const Text('Chart coming soon', style: TextStyle(color: AppColors.grey400)),
                      ),
                    ],
                  ),
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCard(this.title, this.value, this.icon, this.color);

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
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
