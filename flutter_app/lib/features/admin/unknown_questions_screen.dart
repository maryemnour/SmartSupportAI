import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/admin_scaffold.dart';
import '../providers.dart';
import '../../repositories/repositories.dart';

class UnknownQuestionsScreen extends ConsumerWidget {
  final String companyId;
  const UnknownQuestionsScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(unknownQuestionsProvider(companyId));

    return AdminScaffold(
      companyId: companyId,
      title: 'Unknown Questions',
      currentRoute: AppRoutes.unknownQuestions,
      body: questions.when(
        data: (data) {
          if (data.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.help_outline, size: 64, color: AppColors.grey400),
                  SizedBox(height: 16),
                  Text('No unknown questions yet', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Questions that bot couldn\'t answer will appear here',
                      style: TextStyle(color: AppColors.grey600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: data.length,
            itemBuilder: (ctx, i) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(data[i].question,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Text('${data[i].frequency}x',
                              style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Mark Resolved'),
                      onPressed: () async {
                        await UnknownQuestionRepository().updateStatus(data[i].id, 'resolved');
                        ref.invalidate(unknownQuestionsProvider(companyId));
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
