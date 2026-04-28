import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/admin_scaffold.dart';
import '../providers.dart';

class SessionsScreen extends ConsumerWidget {
  final String companyId;
  const SessionsScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider(companyId));

    return AdminScaffold(
      companyId: companyId,
      title: 'Sessions',
      currentRoute: AppRoutes.sessions,
      body: sessions.when(
        data: (data) {
          if (data.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined, size: 64, color: AppColors.grey400),
                  SizedBox(height: 16),
                  Text('No sessions yet', style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: data.length,
            itemBuilder: (ctx, i) {
              final session = data[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Text('${i + 1}', style: const TextStyle(color: AppColors.primary)),
                  ),
                  title: Text('Session ${session.id.substring(0, 8)}...'),
                  subtitle: Text('${session.messageCount} messages • ${session.status}'),
                  trailing: Text(
                    session.startedAt.toString().substring(0, 16),
                    style: const TextStyle(fontSize: 11, color: AppColors.grey600),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
