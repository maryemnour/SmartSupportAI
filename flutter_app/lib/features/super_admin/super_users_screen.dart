import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_routes.dart';
import 'super_admin_scaffold.dart';
import 'super_providers.dart';

const _roles = ['owner', 'admin', 'agent', 'superadmin'];

class SuperUsersScreen extends ConsumerStatefulWidget {
  const SuperUsersScreen({super.key});

  @override
  ConsumerState<SuperUsersScreen> createState() => _SuperUsersScreenState();
}

class _SuperUsersScreenState extends ConsumerState<SuperUsersScreen> {
  final _sb = Supabase.instance.client;
  String _search = '';
  String _roleFilter = 'all';

  Future<void> _changeRole(Map<String, dynamic> u, String role) async {
    await _sb.from('users').update({'role': role}).eq('id', u['id']);
    ref.invalidate(allUsersProvider);
    _snack('Role -> $role');
  }

  Future<void> _toggleActive(Map<String, dynamic> u) async {
    final next = !(u['is_active'] as bool? ?? true);
    await _sb.from('users').update({'is_active': next}).eq('id', u['id']);
    ref.invalidate(allUsersProvider);
    _snack(next ? 'Activated' : 'Deactivated');
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(allUsersProvider);
    final companies = ref.watch(allCompaniesProvider);

    return SuperAdminScaffold(
      currentRoute: AppRoutes.superUsers,
      title: 'Users',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh, color: Color(0xFF0F172A)),
          onPressed: () => ref.invalidate(allUsersProvider),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, size: 18),
                      hintText: 'Search by email or name',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) =>
                        setState(() => _search = v.toLowerCase()),
                  ),
                ),
                DropdownButton<String>(
                  value: _roleFilter,
                  items: ['all', ..._roles]
                      .map((r) =>
                          DropdownMenuItem(value: r, child: Text('Role: $r')))
                      .toList(),
                  onChanged: (v) =>
                      v != null ? setState(() => _roleFilter = v) : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: users.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Failed: $e'),
                data: (rows) {
                  // Build company name lookup.
                  final cMap = <String, String>{};
                  for (final c in companies.value ?? const []) {
                    cMap[c['id'].toString()] = c['name']?.toString() ?? '-';
                  }
                  final filtered = rows.where((u) {
                    final email = (u['email'] ?? '').toString().toLowerCase();
                    final name =
                        (u['full_name'] ?? '').toString().toLowerCase();
                    final role = (u['role'] ?? '').toString();
                    if (_roleFilter != 'all' && role != _roleFilter) {
                      return false;
                    }
                    if (_search.isEmpty) return true;
                    return email.contains(_search) || name.contains(_search);
                  }).toList();
                  if (filtered.isEmpty) {
                    return const Center(child: Text('No users match.'));
                  }
                  return _UserTable(
                    rows: filtered,
                    companyName: cMap,
                    onRole: _changeRole,
                    onToggle: _toggleActive,
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

class _UserTable extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final Map<String, String> companyName;
  final Future<void> Function(Map<String, dynamic>, String) onRole;
  final Future<void> Function(Map<String, dynamic>) onToggle;
  const _UserTable({
    required this.rows,
    required this.companyName,
    required this.onRole,
    required this.onToggle,
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
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Company')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: rows.map((u) {
                final role = (u['role'] ?? 'agent').toString();
                final active = u['is_active'] as bool? ?? true;
                final cId = u['company_id']?.toString();
                final cName =
                    cId != null ? (companyName[cId] ?? '-') : '-';
                return DataRow(cells: [
                  DataCell(Text(u['email']?.toString() ?? '-',
                      style:
                          const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(u['full_name']?.toString() ?? '-')),
                  DataCell(Text(cName)),
                  DataCell(DropdownButton<String>(
                    value: _roles.contains(role) ? role : 'agent',
                    underline: const SizedBox.shrink(),
                    items: _roles
                        .map((r) =>
                            DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => v != null ? onRole(u, v) : null,
                  )),
                  DataCell(_StatusPill(active: active)),
                  DataCell(IconButton(
                    tooltip: active ? 'Deactivate' : 'Activate',
                    icon: Icon(
                        active
                            ? Icons.block
                            : Icons.check_circle_outline,
                        size: 18,
                        color: active
                            ? SuperColors.danger
                            : SuperColors.success),
                    onPressed: () => onToggle(u),
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
      child: Text(active ? 'Active' : 'Inactive',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: c)),
    );
  }
}
