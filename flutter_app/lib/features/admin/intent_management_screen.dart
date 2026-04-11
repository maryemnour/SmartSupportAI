import 'package:flutter/material.dart' hide Intent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../models/models.dart';
import '../../repositories/repositories.dart';
import '../../widgets/admin_scaffold.dart';
import '../providers.dart';

class IntentManagementScreen extends ConsumerStatefulWidget {
  final String companyId;
  const IntentManagementScreen({super.key, required this.companyId});
  @override
  ConsumerState<IntentManagementScreen> createState() => _IntentManagementScreenState();
}

class _IntentManagementScreenState extends ConsumerState<IntentManagementScreen> {
  String _search = '';
  String _category = 'All';
  static const _categories = ['All','general','billing','technical','support','other'];

  @override
  Widget build(BuildContext context) {
    final intentsAsync = ref.watch(intentsProvider(widget.companyId));
    return AdminScaffold(
      companyId: widget.companyId, currentRoute: AppRoutes.intents, title: 'Intents',
      fab: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Intent'),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        onPressed: () => _openDialog(context, null),
      ),
      body: intentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e,_) => Center(child: Text('Error: $e')),
        data: (intents) {
          final filtered = intents.where((i) {
            final matchSearch = _search.isEmpty || i.name.toLowerCase().contains(_search.toLowerCase()) || i.response.toLowerCase().contains(_search.toLowerCase());
            final matchCat = _category == 'All' || i.category == _category;
            return matchSearch && matchCat;
          }).toList();
          return Column(children: [
            // Search + filter bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(children: [
                TextField(
                  decoration: const InputDecoration(hintText: 'Search intents...', prefixIcon: Icon(Icons.search_rounded)),
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _categories.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(c, style: const TextStyle(fontSize: 12)),
                      selected: _category == c,
                      selectedColor: AppColors.primaryLight,
                      checkmarkColor: AppColors.primary,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                  )).toList()),
                ),
              ]),
            ),
            // List
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.psychology_outlined, size: 64, color: AppColors.grey200),
                      const SizedBox(height: 12),
                      Text(_search.isEmpty ? 'No intents yet. Create your first one!' : 'No results found.', style: const TextStyle(color: AppColors.grey400)),
                    ]))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) => _IntentCard(
                        intent: filtered[i],
                        onEdit: () => _openDialog(context, filtered[i]),
                        onDelete: () => _delete(filtered[i].id),
                        onToggle: () => _toggle(filtered[i]),
                      ),
                    ),
            ),
          ]);
        },
      ),
    );
  }

  Future<void> _openDialog(BuildContext context, Intent? intent) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _IntentDialog(companyId: widget.companyId, intent: intent),
    );
    if (result == true) ref.invalidate(intentsProvider(widget.companyId));
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Intent?'),
        content: const Text('This will permanently remove the intent and all its training phrases.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: AppColors.error), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await IntentRepository().deleteIntent(id);
      ref.invalidate(intentsProvider(widget.companyId));
    }
  }

  Future<void> _toggle(Intent intent) async {
    await IntentRepository().updateIntent(intent.id, {'is_active': !intent.isActive});
    ref.invalidate(intentsProvider(widget.companyId));
  }
}

class _IntentCard extends StatelessWidget {
  final Intent intent;
  final VoidCallback onEdit, onDelete, onToggle;
  const _IntentCard({required this.intent, required this.onEdit, required this.onDelete, required this.onToggle});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: intent.isActive ? AppColors.grey200 : AppColors.grey100),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(intent.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.grey900))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(100)),
          child: Text(intent.category, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Switch(value: intent.isActive, onChanged: (_) => onToggle(), activeColor: AppColors.primary),
      ]),
      const SizedBox(height: 6),
      Text(intent.response, style: const TextStyle(color: AppColors.grey600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 8),
      Wrap(spacing: 4, runSpacing: 4, children: intent.trainingPhrases.take(4).map((p) =>
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(100)),
          child: Text(p, style: const TextStyle(fontSize: 11, color: AppColors.grey600)))).toList()),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton.icon(icon: const Icon(Icons.edit_rounded, size: 16), label: const Text('Edit'), onPressed: onEdit),
        TextButton.icon(icon: const Icon(Icons.delete_outline_rounded, size: 16), label: const Text('Delete'),
          style: TextButton.styleFrom(foregroundColor: AppColors.error), onPressed: onDelete),
      ]),
    ]),
  );
}

class _IntentDialog extends ConsumerStatefulWidget {
  final String companyId;
  final Intent? intent;
  const _IntentDialog({required this.companyId, this.intent});
  @override
  ConsumerState<_IntentDialog> createState() => _IntentDialogState();
}

class _IntentDialogState extends ConsumerState<_IntentDialog> {
  final _name     = TextEditingController();
  final _response = TextEditingController();
  final _phrase   = TextEditingController();
  String _category = 'general';
  List<String> _phrases = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.intent != null) {
      _name.text     = widget.intent!.name;
      _response.text = widget.intent!.response;
      _category      = widget.intent!.category;
      _phrases       = List.from(widget.intent!.trainingPhrases);
    }
  }

  @override
  void dispose() { _name.dispose(); _response.dispose(); _phrase.dispose(); super.dispose(); }

  void _addPhrase() {
    final t = _phrase.text.trim();
    if (t.isEmpty || _phrases.contains(t)) return;
    setState(() { _phrases.add(t); _phrase.clear(); });
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _response.text.trim().isEmpty || _phrases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields and add at least one phrase.')));
      return;
    }
    setState(() => _loading = true);
    final data = {'company_id': widget.companyId, 'name': _name.text.trim(), 'response': _response.text.trim(), 'category': _category, 'training_phrases': _phrases, 'is_active': true};
    try {
      if (widget.intent == null) {
        await IntentRepository().createIntent(data);
      } else {
        await IntentRepository().updateIntent(widget.intent!.id, data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Container(
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(widget.intent == null ? 'New Intent' : 'Edit Intent',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 16),
        Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey600)),
          const SizedBox(height: 6),
          TextField(controller: _name, decoration: const InputDecoration(hintText: 'e.g. Business Hours')),
          const SizedBox(height: 14),
          const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(),
            items: ['general','billing','technical','support','other'].map((c) =>
              DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 14),
          const Text('Training Phrases *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey600)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: TextField(controller: _phrase, decoration: const InputDecoration(hintText: 'e.g. what are your hours'), onSubmitted: (_) => _addPhrase())),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _addPhrase, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13)), child: const Text('Add')),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: _phrases.map((p) => Chip(
            label: Text(p, style: const TextStyle(fontSize: 12)),
            deleteIcon: const Icon(Icons.close_rounded, size: 14),
            onDeleted: () => setState(() => _phrases.remove(p)),
            backgroundColor: AppColors.primaryLight,
            labelStyle: const TextStyle(color: AppColors.primary),
          )).toList()),
          const SizedBox(height: 14),
          const Text('Response *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey600)),
          const SizedBox(height: 6),
          TextField(controller: _response, maxLines: 4, decoration: const InputDecoration(hintText: 'The bot will reply with this message...')),
        ]))),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _save,
            child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(widget.intent == null ? 'Create Intent' : 'Save Changes'),
          )),
      ]),
    ),
  );
}
