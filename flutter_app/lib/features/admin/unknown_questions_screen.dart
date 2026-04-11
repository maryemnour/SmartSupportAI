import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../models/models.dart';
import '../../repositories/repositories.dart';
import '../../widgets/admin_scaffold.dart';
import '../providers.dart';

class UnknownQuestionsScreen extends ConsumerStatefulWidget {
  final String companyId;
  const UnknownQuestionsScreen({super.key, required this.companyId});
  @override
  ConsumerState<UnknownQuestionsScreen> createState() => _UnknownQuestionsScreenState();
}

class _UnknownQuestionsScreenState extends ConsumerState<UnknownQuestionsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(unknownQuestionsProvider(widget.companyId));
    return AdminScaffold(
      companyId: widget.companyId, currentRoute: AppRoutes.unknownQuestions, title: 'Unknown Questions',
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (questions) {
          final filtered = questions.where((q) =>
              _search.isEmpty || q.question.toLowerCase().contains(_search.toLowerCase())).toList();
          return Column(children: [
            Container(
              color: Colors.white, padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Questions your bot could not answer.', style: TextStyle(color: AppColors.grey400, fontSize: 13)),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(hintText: 'Search questions...', prefixIcon: Icon(Icons.search_rounded)),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ]),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.success),
                      const SizedBox(height: 12),
                      Text(_search.isEmpty ? 'All clear! No unanswered questions.' : 'No results.', style: const TextStyle(color: AppColors.grey400)),
                    ]))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) => _QuestionCard(
                        question: filtered[i],
                        onConvert: () => _convertToIntent(ctx, filtered[i]),
                        onIgnore: () => _ignore(filtered[i].id),
                      ),
                    ),
            ),
          ]);
        },
      ),
    );
  }

  Future<void> _ignore(String id) async {
    await UnknownQuestionRepository().updateStatus(id, 'ignored');
    ref.invalidate(unknownQuestionsProvider(widget.companyId));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question ignored')));
  }

  Future<void> _convertToIntent(BuildContext ctx, UnknownQuestion q) async {
    final nameCtrl = TextEditingController(text: q.question.length > 40 ? q.question.substring(0, 40) : q.question);
    final respCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Create Intent from Question'),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Question: "${q.question}"', style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.grey600, fontSize: 13)),
          const SizedBox(height: 14),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Intent name')),
          const SizedBox(height: 10),
          TextField(controller: respCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Bot response')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok == true && respCtrl.text.trim().isNotEmpty) {
      await IntentRepository().createIntent({
        'company_id': widget.companyId,
        'name': nameCtrl.text.trim(),
        'training_phrases': [q.question],
        'response': respCtrl.text.trim(),
        'category': 'general', 'is_active': true,
      });
      await UnknownQuestionRepository().updateStatus(q.id, 'converted');
      ref.invalidate(unknownQuestionsProvider(widget.companyId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intent created!'), backgroundColor: AppColors.success));
    }
    nameCtrl.dispose(); respCtrl.dispose();
  }
}

class _QuestionCard extends StatelessWidget {
  final UnknownQuestion question;
  final VoidCallback onConvert, onIgnore;
  const _QuestionCard({required this.question, required this.onConvert, required this.onIgnore});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(question.question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.grey900))),
        if (question.frequency > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(100)),
            child: Text('Asked ${question.frequency}×', style: const TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w600)),
          ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
          label: const Text('Create Intent', style: TextStyle(fontSize: 13)),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
          onPressed: onConvert,
        )),
        const SizedBox(width: 8),
        TextButton.icon(
          icon: const Icon(Icons.block_rounded, size: 16),
          label: const Text('Ignore', style: TextStyle(fontSize: 13)),
          style: TextButton.styleFrom(foregroundColor: AppColors.grey400),
          onPressed: onIgnore,
        ),
      ]),
    ]),
  );
}
