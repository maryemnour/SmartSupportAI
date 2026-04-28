// Knowledge-base management screen.
//
// Flow:
//   1. Admin pastes raw text (or uploads a .txt file).
//   2. We split it into ~500-char chunks (overlap 50).
//   3. POST the chunks (batched) to ${ML_API_URL}/embed -> 384-d vectors.
//   4. Insert one row in `company_documents` and one row per chunk in
//      `document_chunks` with its embedding. The ai-chat edge function
//      will then surface these chunks via `search_company_docs` (RAG).
//
// PDF parsing in Flutter web is non-trivial; v1 supports .txt and pasted
// text. PDFs can be added later by extracting text on the server side.

import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_config.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/admin_scaffold.dart';

class DocumentsScreen extends StatefulWidget {
  final String companyId;
  const DocumentsScreen({super.key, required this.companyId});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _ingesting = false;
  String? _statusMsg;

  // ------------------------------------------------------------------ helpers
  /// Split a long string into roughly-fixed-size chunks with light overlap so
  /// embeddings retain context across boundaries.
  List<String> _chunk(String text, {int size = 500, int overlap = 50}) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= size) return [clean];
    final out = <String>[];
    var start = 0;
    while (start < clean.length) {
      final end = (start + size).clamp(0, clean.length);
      out.add(clean.substring(start, end).trim());
      if (end >= clean.length) break;
      start = end - overlap;
    }
    return out.where((c) => c.isNotEmpty).toList();
  }

  Future<List<List<double>>> _embedBatch(List<String> texts) async {
    final res = await http.post(
      Uri.parse('${AppConfig.mlApiUrl}/embed'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': texts}),
    );
    if (res.statusCode != 200) {
      throw Exception('Embed API ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = data['embeddings'] as List<dynamic>;
    return raw
        .map((e) => (e as List).map((n) => (n as num).toDouble()).toList())
        .toList();
  }

  Future<void> _ingest() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      setState(() => _statusMsg = 'Title and body are required.');
      return;
    }
    setState(() {
      _ingesting = true;
      _statusMsg = 'Splitting into chunks...';
    });
    try {
      final sb = Supabase.instance.client;
      final chunks = _chunk(body);

      setState(() => _statusMsg = 'Embedding ${chunks.length} chunk(s)...');
      final vectors = await _embedBatch(chunks);

      setState(() => _statusMsg = 'Saving document...');
      final doc = await sb
          .from('company_documents')
          .insert({
            'company_id': widget.companyId,
            'file_name': title,
            'file_size': body.length,
            'status': 'processing',
            'chunk_count': chunks.length,
          })
          .select()
          .single();

      final docId = doc['id'] as String;
      final rows = <Map<String, dynamic>>[];
      for (var i = 0; i < chunks.length; i++) {
        rows.add({
          'company_id': widget.companyId,
          'document_id': docId,
          'content': chunks[i],
          'embedding': vectors[i],
          'chunk_index': i,
        });
      }
      await sb.from('document_chunks').insert(rows);
      await sb
          .from('company_documents')
          .update({'status': 'ready'}).eq('id', docId);

      _titleCtrl.clear();
      _bodyCtrl.clear();
      setState(() => _statusMsg = 'OK -- ingested ${chunks.length} chunk(s).');
    } catch (e) {
      setState(() => _statusMsg = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _ingesting = false);
    }
  }

  Future<void> _pickTextFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md'],
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;
    final f = res.files.first;
    final bytes = f.bytes ?? Uint8List(0);
    if (bytes.isEmpty) {
      setState(() => _statusMsg = 'Could not read file bytes.');
      return;
    }
    _titleCtrl.text = f.name;
    _bodyCtrl.text = utf8.decode(bytes, allowMalformed: true);
  }

  Future<void> _deleteDoc(String id) async {
    await Supabase.instance.client
        .from('company_documents')
        .delete()
        .eq('id', id);
    setState(() {});
  }

  // ----------------------------------------------------------------- UI build
  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      companyId: widget.companyId,
      title: 'Knowledge Base',
      currentRoute: AppRoutes.documents,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Add document card -----------------------------------------
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.grey200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add to knowledge base',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text(
                      'Paste text or upload a .txt / .md file. The bot will use this to answer customer questions via RAG.',
                      style: TextStyle(color: AppColors.grey600),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g. "Refund policy" or "FAQ"',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bodyCtrl,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Document text',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _ingesting ? null : _pickTextFile,
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Upload .txt'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _ingesting ? null : _ingest,
                          icon: _ingesting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.cloud_upload_outlined),
                          label: Text(_ingesting ? 'Ingesting...' : 'Ingest'),
                        ),
                        const SizedBox(width: 16),
                        if (_statusMsg != null)
                          Expanded(
                            child: Text(
                              _statusMsg!,
                              style: TextStyle(
                                color: _statusMsg!.startsWith('Failed')
                                    ? Colors.red
                                    : AppColors.grey600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ---- Existing documents list -----------------------------------
            const Text('Documents',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: Supabase.instance.client
                  .from('company_documents')
                  .select()
                  .eq('company_id', widget.companyId)
                  .order('created_at', ascending: false)
                  .then((value) =>
                      (value as List).cast<Map<String, dynamic>>()),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data ?? const <Map<String, dynamic>>[];
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No documents yet.',
                        style: TextStyle(color: AppColors.grey600)),
                  );
                }
                return Column(
                  children: docs
                      .map((d) => Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side:
                                  const BorderSide(color: AppColors.grey200),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.description_outlined),
                              title: Text(d['file_name']?.toString() ?? '-'),
                              subtitle: Text(
                                  '${d['chunk_count'] ?? 0} chunks - ${d['status'] ?? '-'}'),
                              trailing: IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () =>
                                    _deleteDoc(d['id'].toString()),
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
