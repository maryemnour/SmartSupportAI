import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../models/models.dart';
import '../../widgets/admin_scaffold.dart';
import '../providers.dart';

class SessionsScreen extends ConsumerStatefulWidget {
  final String companyId;
  const SessionsScreen({super.key, required this.companyId});
  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider(widget.companyId));
    return AdminScaffold(
      companyId: widget.companyId, currentRoute: AppRoutes.sessions, title: 'Sessions',
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sessions) {
          final filtered = sessions.where((s) => _filter == 'all' || s.status == _filter).toList();
          return Column(children: [
            Container(
              color: Colors.white, padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Text('Filter:', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey600, fontSize: 13)),
                const SizedBox(width: 10),
                ...[('all','All'), ('active','Active'), ('closed','Closed'), ('handed_off','Handed Off')].map((f) =>
                  Padding(padding: const EdgeInsets.only(right: 6), child: FilterChip(
                    label: Text(f.$2, style: const TextStyle(fontSize: 12)),
                    selected: _filter == f.$1,
                    selectedColor: AppColors.primaryLight,
                    checkmarkColor: AppColors.primary,
                    onSelected: (_) => setState(() => _filter = f.$1),
                  ))),
              ]),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No sessions found.', style: TextStyle(color: AppColors.grey400)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _SessionCard(session: filtered[i]),
                    ),
            ),
          ]);
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ChatSession session;
  const _SessionCard({required this.session});

  Color get _statusColor => switch (session.status) {
    'active'     => AppColors.success,
    'handed_off' => AppColors.error,
    _            => AppColors.grey400,
  };

  IconData get _statusIcon => switch (session.status) {
    'active'     => Icons.circle,
    'handed_off' => Icons.transfer_within_a_station_rounded,
    _            => Icons.check_circle_outline_rounded,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
    child: Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.grey100, shape: BoxShape.circle),
        child: const Icon(Icons.person_rounded, color: AppColors.grey400, size: 22)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(session.visitorName ?? 'Anonymous Visitor', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.grey900)),
        const SizedBox(height: 2),
        Text(DateFormat('MMM d, yyyy • HH:mm').format(session.startedAt.toLocal()),
          style: const TextStyle(fontSize: 12, color: AppColors.grey400)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_statusIcon, size: 12, color: _statusColor),
          const SizedBox(width: 4),
          Text(session.status.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor)),
        ]),
        const SizedBox(height: 4),
        Text('${session.messageCount} msgs', style: const TextStyle(fontSize: 12, color: AppColors.grey400)),
      ]),
    ]),
  );
}
