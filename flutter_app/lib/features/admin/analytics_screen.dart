import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/admin_scaffold.dart';
import '../providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  final String companyId;
  const AnalyticsScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider(companyId));
    final dailyAsync     = ref.watch(_dailyProvider(companyId));

    return AdminScaffold(
      companyId: companyId, currentRoute: AppRoutes.analytics, title: 'Analytics',
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (analytics) {
          if (analytics == null) return const Center(child: Text('No analytics data yet.'));
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // KPI row
              _SectionTitle('Key Metrics'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
                children: [
                  _MetricCard('Sessions', '${analytics.totalSessions}', Icons.forum_rounded, AppColors.primary, '+12% this week'),
                  _MetricCard('Messages', '${analytics.totalMessages}', Icons.chat_bubble_rounded, const Color(0xFF8B5CF6), 'Total exchanged'),
                  _MetricCard('Satisfaction', analytics.avgSatisfaction > 0 ? '${analytics.avgSatisfaction}/5' : '—', Icons.star_rounded, const Color(0xFFF59E0B), 'Avg rating'),
                  _MetricCard('Handoffs', '${analytics.handoffCount}', Icons.transfer_within_a_station_rounded, const Color(0xFFEF4444), 'Human escalations'),
                  _MetricCard('Active Intents', '${analytics.activeIntents}', Icons.psychology_rounded, const Color(0xFF10B981), 'Trained responses'),
                  _MetricCard('Unanswered', '${analytics.unansweredQuestions}', Icons.help_outline_rounded, const Color(0xFFF59E0B), 'Need review'),
                ],
              ),
              const SizedBox(height: 28),

              // Resolution breakdown
              _SectionTitle('Resolution Breakdown'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                child: Column(children: [
                  SizedBox(
                    height: 180,
                    child: PieChart(PieChartData(
                      sections: [
                        PieChartSectionData(value: (analytics.totalSessions - analytics.handoffCount - analytics.unansweredQuestions).toDouble().clamp(0, double.infinity), color: AppColors.success, title: 'Resolved', radius: 60, titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                        PieChartSectionData(value: analytics.handoffCount.toDouble(), color: const Color(0xFFEF4444), title: 'Handoff', radius: 60, titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                        PieChartSectionData(value: analytics.unansweredQuestions.toDouble(), color: const Color(0xFFF59E0B), title: 'Unanswered', radius: 60, titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                      ],
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                    )),
                  ),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _Legend('Resolved', AppColors.success),
                    _Legend('Handoff', const Color(0xFFEF4444)),
                    _Legend('Unanswered', const Color(0xFFF59E0B)),
                  ]),
                ]),
              ),
              const SizedBox(height: 28),

              // Daily sessions chart
              _SectionTitle('Daily Sessions (This Week)'),
              const SizedBox(height: 12),
              dailyAsync.when(
                loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox(),
                data: (daily) {
                  if (daily.isEmpty) return Container(
                    height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                    child: const Center(child: Text('No session data yet', style: TextStyle(color: AppColors.grey400))),
                  );
                  final spots = daily.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['session_count'] ?? 0).toDouble())).toList();
                  return Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                    child: LineChart(LineChartData(
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      titlesData: const FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [LineChartBarData(
                        spots: spots,
                        isCurved: true, color: AppColors.primary,
                        barWidth: 2.5,
                        belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(.1)),
                        dotData: const FlDotData(show: false),
                      )],
                    )),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

final _dailyProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, cid) =>
    ref.read(analyticsRepoProvider).getDailySessions(cid));

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.grey900));
}

class _MetricCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  const _MetricCard(this.label, this.value, this.icon, this.color, this.sub);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey900)),
      Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.grey400)),
    ]),
  );
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  const _Legend(this.label, this.color);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
  ]);
}
