import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/admin_scaffold.dart';
import '../providers.dart';

class EmbedScreen extends ConsumerStatefulWidget {
  final String companyId;
  const EmbedScreen({super.key, required this.companyId});
  @override
  ConsumerState<EmbedScreen> createState() => _EmbedScreenState();
}

class _EmbedScreenState extends ConsumerState<EmbedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _keyVisible = false;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$label copied ✓'), backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyProvider(widget.companyId));
    return AdminScaffold(
      companyId: widget.companyId, currentRoute: AppRoutes.embed, title: 'Embed / API Key',
      body: companyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (company) {
          final apiKey = company?.apiKey ?? 'sk_not_configured';
          final cid    = widget.companyId;

          final codes = {
            'web': '''<script
  src="https://cdn.smartsupport.ai/widget.js"
  data-key="$apiKey">
</script>''',
            'flutter': '''// pubspec.yaml:
// smart_support_ai: ^1.0.0

SmartSupportChatbotWidget(
  companyId: '$cid',
)''',
            'react': '''// npm install @smartsupport/react
import { ChatWidget } from '@smartsupport/react';

<ChatWidget apiKey="$apiKey" />''',
          };

          return ListView(padding: const EdgeInsets.all(20), children: [
            // Company ID card
            _CredCard(
              label: 'Company ID',
              icon: Icons.business_rounded,
              value: cid,
              hint: 'Use this in your Flutter app',
              onCopy: () => _copy(cid, 'Company ID'),
            ),
            const SizedBox(height: 12),
            // API Key card
            _CredCard(
              label: 'API Key',
              icon: Icons.key_rounded,
              value: _keyVisible ? apiKey : '${apiKey.substring(0, 8)}••••••••••••••••',
              hint: 'Use this in the web widget script',
              onCopy: () => _copy(apiKey, 'API Key'),
              trailing: TextButton(
                onPressed: () => setState(() => _keyVisible = !_keyVisible),
                child: Text(_keyVisible ? 'Hide' : 'Show'),
              ),
              warning: '⚠️ Never share this key publicly',
            ),
            const SizedBox(height: 24),

            // Embed code
            const Text('Embed Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.grey900)),
            const SizedBox(height: 4),
            const Text('Paste into your site or app — the chatbot goes live instantly', style: TextStyle(color: AppColors.grey400, fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
              child: Column(children: [
                TabBar(
                  controller: _tabs,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.grey400,
                  tabs: const [Tab(text: '🌐 Website'), Tab(text: '📱 Flutter'), Tab(text: '⚛️ React')],
                ),
                SizedBox(
                  height: 180,
                  child: TabBarView(
                    controller: _tabs,
                    children: ['web','flutter','react'].map((k) => Stack(children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Text(codes[k]!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF22D3A0), height: 1.7)),
                      ),
                      Positioned(top: 8, right: 8,
                        child: OutlinedButton(
                          onPressed: () => _copy(codes[k]!, 'Embed code'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero),
                          child: const Text('Copy', style: TextStyle(fontSize: 12)),
                        )),
                    ])).toList(),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // Steps
            const Text('How it works', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.grey900)),
            const SizedBox(height: 12),
            ...[
              ('1', Icons.code_rounded, 'Copy the embed code above'),
              ('2', Icons.web_rounded, 'Paste it into your website or app'),
              ('3', Icons.upload_file_rounded, 'Upload knowledge files in "Knowledge Base"'),
              ('4', Icons.psychology_rounded, 'The AI learns and answers your customers'),
              ('5', Icons.bar_chart_rounded, 'Monitor performance in Analytics'),
            ].map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center, child: Text(s.$1, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13))),
                const SizedBox(width: 12),
                Icon(s.$2, color: AppColors.grey400, size: 18),
                const SizedBox(width: 8),
                Text(s.$3, style: const TextStyle(color: AppColors.grey600, fontSize: 13)),
              ]),
            )),
          ]);
        },
      ),
    );
  }
}

class _CredCard extends StatelessWidget {
  final String label, value, hint;
  final IconData icon;
  final VoidCallback onCopy;
  final Widget? trailing;
  final String? warning;
  const _CredCard({required this.label, required this.icon, required this.value, required this.hint, required this.onCopy, this.trailing, this.warning});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.grey200),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey900)),
      ]),
      const SizedBox(height: 6),
      Text(hint, style: const TextStyle(fontSize: 12, color: AppColors.grey400)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFF0F0F1A), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Expanded(child: Text(value, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFFA5B4FC)), overflow: TextOverflow.ellipsis)),
          if (trailing != null) trailing!,
          TextButton(onPressed: onCopy, style: TextButton.styleFrom(foregroundColor: AppColors.primary, minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)), child: const Text('Copy', style: TextStyle(fontSize: 12))),
        ]),
      ),
      if (warning != null) ...[
        const SizedBox(height: 6),
        Text(warning!, style: const TextStyle(fontSize: 11, color: AppColors.error)),
      ],
    ]),
  );
}
