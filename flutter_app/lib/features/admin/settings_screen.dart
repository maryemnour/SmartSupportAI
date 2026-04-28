import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/admin_scaffold.dart';
import '../providers.dart';
import '../../repositories/repositories.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final String companyId;
  const SettingsScreen({super.key, required this.companyId});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _welcomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  String _personality = 'friendly';
  bool _loading = false;
  bool _saved = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _welcomeCtrl.dispose();
    _emailCtrl.dispose();
    _waCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final company = ref.watch(companyProvider(widget.companyId));

    return AdminScaffold(
      companyId: widget.companyId,
      title: 'Settings',
      currentRoute: AppRoutes.settings,
      body: company.when(
        data: (data) {
          if (data == null) return const Center(child: Text('Company not found'));
          
          if (!_initialized) {
            _nameCtrl.text = data.name;
            _welcomeCtrl.text = data.welcomeMessage;
            _emailCtrl.text = data.supportEmail ?? '';
            _waCtrl.text = data.whatsappNumber ?? '';
            _personality = data.botPersonality ?? 'friendly';
            _initialized = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 24),

                  _buildSection('Company Information', [
                    _buildField('Company Name', _nameCtrl),
                    _buildField('Welcome Message', _welcomeCtrl, maxLines: 3),
                  ]),

                  const SizedBox(height: 24),

                  _buildSection('Support Contacts', [
                    _buildField('Support Email', _emailCtrl, hint: 'support@company.com'),
                    _buildField('WhatsApp Number', _waCtrl, hint: '+1234567890'),
                  ]),

                  const SizedBox(height: 24),

                  _buildSection('Bot Personality', [
                    const Text('Choose how your bot communicates:',
                        style: TextStyle(fontSize: 13, color: AppColors.grey600)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: [
                        _buildPersonalityChip('Friendly', 'friendly'),
                        _buildPersonalityChip('Professional', 'professional'),
                        _buildPersonalityChip('Funny', 'funny'),
                      ],
                    ),
                  ]),

                  const SizedBox(height: 28),

                  if (_saved)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF6EE7B7)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                          SizedBox(width: 8),
                          Text('Settings saved!', style: TextStyle(color: AppColors.success)),
                        ],
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _saved = false;
    });

    try {
      await CompanyRepository().updateCompany(widget.companyId, {
        'name': _nameCtrl.text.trim(),
        'welcome_message': _welcomeCtrl.text.trim(),
        'support_email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'whatsapp_number': _waCtrl.text.trim().isEmpty ? null : _waCtrl.text.trim(),
        'bot_personality': _personality,
      });

      ref.invalidate(companyProvider(widget.companyId));

      setState(() {
        _loading = false;
        _saved = true;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _saved = false);
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildSection(String title, List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      );

  Widget _buildField(String label, TextEditingController ctrl, {String hint = '', int maxLines = 1}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey600)),
          const SizedBox(height: 6),
          TextField(controller: ctrl, maxLines: maxLines, decoration: InputDecoration(hintText: hint)),
          const SizedBox(height: 12),
        ],
      );

  Widget _buildPersonalityChip(String label, String value) {
    final isSelected = value == _personality;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _personality = value),
      backgroundColor: Colors.white,
      selectedColor: AppColors.primaryLight,
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.grey300),
      labelStyle: TextStyle(color: isSelected ? AppColors.primary : AppColors.grey600),
    );
  }
}
