import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/admin_scaffold.dart';

final _docsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, cid) async {
  final res = await Supabase.instance.client.from('company_documents')
      .select().eq('company_id', cid).order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(res);
});

class DocumentsScreen extends ConsumerStatefulWidget {
  final String companyId;
  const DocumentsScreen({super.key, required this.companyId});
  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  bool _uploading = false;

  Future<void> _upload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf', 'txt', 'docx'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    if (file.size > 10 * 1024 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File too large — max 10MB'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _uploading = true);
    try {
      final sb   = Supabase.instance.client;
      final path = '${widget.companyId}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      await sb.storage.from('company-documents').uploadBinary(path, file.bytes!);
      final url = sb.storage.from('company-documents').getPublicUrl(path);
      await sb.from('company_documents').insert({
        'company_id': widget.companyId, 'file_name': file.name,
        'file_url': url, 'file_size': file.size, 'status': 'processing',
      });
      ref.invalidate(_docsProvider(widget.companyId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${file.name}" uploaded!'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(_docsProvider(widget.companyId));
    return AdminScaffold(
      companyId: widget.companyId, currentRoute: AppRoutes.documents, title: 'Knowledge Base',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Upload zone
          GestureDetector(
            onTap: _uploading ? null : _upload,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, style: BorderStyle.solid, width: 1.5),
              ),
              child: Column(children: [
                _uploading
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : Icon(Icons.cloud_upload_rounded, size: 48, color: AppColors.primary.withOpacity(.7)),
                const SizedBox(height: 12),
                const Text('Click to upload documents', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.grey900)),
                const SizedBox(height: 4),
                const Text('PDF, TXT, DOCX — max 10MB', style: TextStyle(fontSize: 13, color: AppColors.grey400)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                  child: const Text('The AI learns from these files to answer your customers', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Uploaded Files', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.grey900)),
          const SizedBox(height: 12),
          docsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (docs) => docs.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                    child: const Center(child: Text('No files yet. Upload your first document to train the AI.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey400))))
                : Column(
                    children: docs.map((d) => _DocTile(doc: d, companyId: widget.companyId, onDelete: () => ref.invalidate(_docsProvider(widget.companyId)))).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  final Map<String, dynamic> doc;
  final String companyId;
  final VoidCallback onDelete;
  const _DocTile({required this.doc, required this.companyId, required this.onDelete});

  String _fmt(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes/1024).toStringAsFixed(1)} KB';
    return '${(bytes/1048576).toStringAsFixed(1)} MB';
  }

  Color get _statusColor => switch (doc['status']) { 'ready' => AppColors.success, 'error' => AppColors.error, _ => AppColors.warning };

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.grey200)),
    child: Row(children: [
      Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 28),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(doc['file_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.grey900), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(_fmt(doc['file_size'] ?? 0), style: const TextStyle(fontSize: 12, color: AppColors.grey400)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: _statusColor.withOpacity(.12), borderRadius: BorderRadius.circular(100)),
        child: Text((doc['status'] ?? 'processing').toString().toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor)),
      ),
    ]),
  );
}
