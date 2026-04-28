import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_routes.dart';
import 'super_admin_scaffold.dart';
import 'super_providers.dart';

class SuperAuditScreen extends ConsumerStatefulWidget {
  const SuperAuditScreen({super.key});

  @override
  ConsumerState<SuperAuditScreen> createState() => _SuperAuditScreenState();
}

class _SuperAuditScreenState extends ConsumerState<SuperAuditScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(auditLogsProvider);
    final companies = ref.watch(allCompaniesProvider);

    return SuperAdminScaffold(
      currentRoute: AppRoutes.superAudit,
      title: 'Audit log',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh, color: Color(0xFF0F172A)),
          onPressed: () => ref.invalidate(auditLogsProvider),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, size: 18),
                  hintText: 'Search by action or target',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) =>
                    setState(() => _search = v.toLowerCase()),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Last 200 events. Newest first.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: logs.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorBox(
                    'Failed to load audit log: $e\n\nDoes the audit_logs table exist?'),
                data: (rows) {
                  final cMap = <String, String>{};
                  for (final c in companies.value ?? const []) {
                    cMap[c['id'].toString()] = c['name']?.toString() ?? '-';
                  }
                  final filtered = rows.where((r) {
                    if (_search.isEmpty) return true;
                    final action = (r['action'] ?? '').toString().toLowerCase();
                    final target =
                        (r['target_type'] ?? '').toString().toLowerCase();
                    return action.contains(_search) ||
                        target.contains(_search);
                  }).toList();
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No matching audit entries.'),
                    );
                  }
                  return _AuditList(rows: filtered, companyName: cMap);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditList extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final Map<String, String> companyName;
  const _AuditList({required this.rows, required this.companyName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: rows.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
        itemBuilder: (_, i) {
          final r = rows[i];
          final action = (r['action'] ?? '').toString();
          final target =
              '${r['target_type'] ?? ''}${r['target_id'] != null ? ' / ${r['target_id']}' : ''}';
          final cId = r['company_id']?.toString();
          final cName = cId != null ? (companyName[cId] ?? '-') : '-';
          final ts = (r['created_at'] ?? '').toString();
          final meta = r['metadata'];
          final metaPretty = (meta == null || meta.toString() == '{}')
              ? null
              : (meta is String ? meta : jsonEncode(meta));
          return ListTile(
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: SuperColors.accentSoft,
              child: const Icon(Icons.bolt,
                  size: 14, color: Color(0xFF92400E)),
            ),
            title: Row(
              children: [
                Text(action,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(cName,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF475569))),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (target.trim().isNotEmpty)
                  Text(target,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B))),
                if (metaPretty != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(metaPretty,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontFamily: 'monospace'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
            trailing: Text(
              ts.length >= 16 ? ts.substring(0, 16).replaceAll('T', ' ') : ts,
              style:
                  const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          );
        },
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
