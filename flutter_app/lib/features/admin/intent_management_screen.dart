import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/admin_scaffold.dart';
import '../providers.dart';
import '../../models/models.dart' as models;
import '../../repositories/repositories.dart';

class IntentManagementScreen extends ConsumerStatefulWidget {
  final String companyId;
  const IntentManagementScreen({super.key, required this.companyId});

  @override
  ConsumerState<IntentManagementScreen> createState() => _IntentManagementScreenState();
}

class _IntentManagementScreenState extends ConsumerState<IntentManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final intents = ref.watch(intentsProvider(widget.companyId));

    return AdminScaffold(
      companyId: widget.companyId,
      title: 'Intents',
      currentRoute: AppRoutes.intents,
      body: intents.when(
        data: (data) {
          final filtered = _searchQuery.isEmpty
              ? data
              : data.where((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search intents...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Intent'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No intents yet. Click "Add Intent" to create one.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => _IntentCard(
                          intent: filtered[i],
                          onDelete: () => _deleteIntent(filtered[i].id),
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phrasesCtrl = TextEditingController();
    final responseCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Intent'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Intent Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phrasesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Training Phrases (one per line)',
                  hintText: 'How do I reset my password?\nForgot password',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: responseCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Response'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              try {
                await IntentRepository().createIntent({
                  'company_id': widget.companyId,
                  'name': nameCtrl.text.trim(),
                  'training_phrases': phrasesCtrl.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
                  'response': responseCtrl.text.trim(),
                  'category': 'general',
                  'is_active': true,
                });
                ref.invalidate(intentsProvider(widget.companyId));
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteIntent(String id) async {
    try {
      await IntentRepository().deleteIntent(id);
      ref.invalidate(intentsProvider(widget.companyId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Intent deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _IntentCard extends StatelessWidget {
  final models.Intent intent;
  final VoidCallback onDelete;
  const _IntentCard({required this.intent, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(intent.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                  onPressed: onDelete,
                ),
              ],
            ),
            if (intent.description != null && intent.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(intent.description!, style: const TextStyle(fontSize: 13, color: AppColors.grey600)),
            ],
            const SizedBox(height: 12),
            Text('Response: ${intent.response}',
                style: const TextStyle(fontSize: 13, color: AppColors.grey600)),
            const SizedBox(height: 8),
            Text('Training phrases: ${intent.trainingPhrases.length} • Matched: ${intent.matchCount} times',
                style: const TextStyle(fontSize: 11, color: AppColors.grey400)),
          ],
        ),
      ),
    );
  }
}
