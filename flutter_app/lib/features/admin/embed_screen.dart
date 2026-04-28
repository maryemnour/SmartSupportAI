import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/admin_scaffold.dart';

class EmbedScreen extends StatelessWidget {
  final String companyId;
  const EmbedScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final embedCode = '''<script src="https://your-domain.com/widget.js"></script>
<script>
  SmartSupportWidget.init({
    companyId: '$companyId'
  });
</script>''';

    return AdminScaffold(
      companyId: companyId,
      title: 'Embed / API Key',
      currentRoute: AppRoutes.embed,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Embed Widget', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('Copy and paste this code into your website',
                  style: TextStyle(color: AppColors.grey600)),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.grey300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Embed Code', style: TextStyle(fontWeight: FontWeight.w600)),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: embedCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied to clipboard!')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(embedCode,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Company ID',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    SelectableText(companyId,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
