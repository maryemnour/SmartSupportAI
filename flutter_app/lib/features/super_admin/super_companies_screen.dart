import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_routes.dart';
import 'super_admin_scaffold.dart';
import 'super_providers.dart';

const _plans = ['free', 'starter', 'pro', 'enterprise'];

class SuperCompaniesScreen extends ConsumerStatefulWidget {
  const SuperCompaniesScreen({super.key});

  @override
  ConsumerState<SuperCompaniesScreen> createState() =>
      _SuperCompaniesScreenState();
}

class _SuperCompaniesScreenState extends ConsumerState<SuperCompaniesScreen> {
  final _sb = Supabase.instance.client;
  String _search = '';
  String _planFilter = 'all';
  bool _activeOnly = false;

  // ----- mutations ----------------------------------------------------------
  Future<void> _toggle(Map<String, dynamic> c) async {
    final next = !(c['is_active'] as bool? ?? true);
    await _sb.from('companies').update({'is_active': next}).eq('id', c['id']);
    ref.invalidate(allCompaniesProvider);
    ref.invalidate(platformStatsProvider);
    _snack(next ? 'Activated' : 'Suspended');
  }

  Future<void> _changePlan(Map<String, dynamic> c, String plan) async {
    await _sb.from('companies').update({'plan': plan}).eq('id', c['id']);
    ref.invalidate(allCompaniesProvider);
    _snack('Plan -> $plan');
  }

  Future<void> _delete(Map<String, dynamic> c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete company?'),
        content: Text(
            'This permanently removes "${c['name']}" and ALL its data. Cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SuperColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _sb.from('companies').delete().eq('id', c['id']);
    ref.invalidate(allCompaniesProvider);
    ref.invalidate(platformStatsProvider);
    _snack('Deleted');
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

  // ----- build --------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final companies = ref.watch(allCompaniesProvider);

    return SuperAdminScaffold(
      currentRoute: AppRoutes.superCompanies,
      title: 'Companies',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh, color: Color(0xFF0F172A)),
          onPressed: () => ref.invalidate(allCompaniesProvider),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Filters(
              onSearch: (v) => setState(() => _search = v.toLowerCase()),
              onPlan: (v) => setState(() => _planFilter = v),
              onActiveOnly: (v) => setState(() => _activeOnly = v),
              activeOnly: _activeOnly,
              planFilter: _planFilter,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: companies.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Failed: $e'),
                data: (rows) {
                  final filtered = rows.where((c) {
                    final name = (c['name'] ?? '').toString().toLowerCase();
                    final email =
                        (c['support_email'] ?? '').toString().toLowerCase();
                    final plan = (c['plan'] ?? '').toString();
                    final active = c['is_active'] as bool? ?? true;
                    if (_activeOnly && !active) return false;
                    if (_planFilter != 'all' && plan != _planFilter) {
                      return false;
                    }
                    if (_search.isEmpty) return true;
                    return name.contains(_search) || email.contains(_search);
                  }).toList();
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No companies match.'),
                    );
                  }
                  return _CompanyTable(
                    rows: filtered,
                    onToggle: _toggle,
                    onPlan: _changePlan,
                    onDelete: _delete,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final void Function(String) onSearch;
  final void Function(String) onPlan;
  final void Function(bool) onActiveOnly;
  final bool activeOnly;
  final String planFilter;
  const _Filters({
    required this.onSearch,
    required this.onPlan,
    required this.onActiveOnly,
    required this.activeOnly,
    required this.planFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, size: 18),
              hintText: 'Search by name or email',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: onSearch,
          ),
        ),
        DropdownButton<String>(
          value: planFilter,
          items: ['all', ..._plans]
              .map((p) => DropdownMenuItem(value: p, child: Text('Plan: $p')))
              .toList(),
          onChanged: (v) => v != null ? onPlan(v) : null,
        ),
        FilterChip(
          label: const Text('Active only'),
          selected: activeOnly,
          onSelected: onActiveOnly,
        ),
      ],
    );
  }
}

class _CompanyTable extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final Future<void> Function(Map<String, dynamic>) onToggle;
  final Future<void> Function(Map<String, dynamic>, String) onPlan;
  final Future<void> Function(Map<String, dynamic>) onDelete;
  const _CompanyTable({
    required this.rows,
    required this.onToggle,
    required this.onPlan,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 900),
          child: SingleChildScrollView(
            child: DataTable(
              columnSpacing: 24,
              headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF8FAFC)),
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Plan')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Created')),
                DataColumn(label: Text('Actions')),
              ],
              rows: rows.map((c) {
                final active = c['is_active'] as bool? ?? true;
                final plan = (c['plan'] ?? 'free').toString();
                final created = (c['created_at'] ?? '').toString();
                return DataRow(cells: [
                  DataCell(Text(c['name']?.toString() ?? '-',
                      style:
                          const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(
                      Text(c['support_email']?.toString() ?? '-')),
                  DataCell(_PlanDropdown(
                    current: plan,
                    onChanged: (v) => onPlan(c, v),
                  )),
                  DataCell(_StatusPill(active: active)),
                  DataCell(Text(created.length >= 10
                      ? created.substring(0, 10)
                      : created)),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: active ? 'Suspend' : 'Activate',
                        icon: Icon(
                            active
                                ? Icons.block
                                : Icons.check_circle_outline,
                            size: 18,
                            color: active
                                ? SuperColors.danger
                                : SuperColors.success),
                        onPressed: () => onToggle(c),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: SuperColors.danger),
                        onPressed: () => onDelete(c),
                      ),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanDropdown extends StatelessWidget {
  final String current;
  final void Function(String) onChanged;
  const _PlanDropdown({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _plans.contains(current) ? current : 'free',
      underline: const SizedBox.shrink(),
      items: _plans
          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
          .toList(),
      onChanged: (v) => v != null ? onChanged(v) : null,
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool active;
  const _StatusPill({required this.active});
  @override
  Widget build(BuildContext context) {
    final c = active ? SuperColors.success : SuperColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(active ? 'Active' : 'Suspended',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: c)),
    );
  }
}
