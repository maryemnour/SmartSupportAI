import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../repositories/repositories.dart';
import '../../widgets/admin_scaffold.dart';
import '../providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final String companyId;
  const SettingsScreen({super.key, required this.companyId});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _name    = TextEditingController();
  final _welcome = TextEditingController();
  final _email   = TextEditingController();
  final _wa      = TextEditingController();
  final _color   = TextEditingController();
  bool _loading  = false;
  bool _saved    = false;

  static const _presets = ['#6366F1','#8B5CF6','#EC4899','#EF4444','#F59E0B','#10B981','#3B82F6','#0EA5E9'];

  @override
  void initState() {
    super.initState();
    _loadCompany();
  }

  Future<void> _loadCompany() async {
    final company = await CompanyRepository().getCompany(widget.companyId);
    if (company != null && mounted) {
      _name.text    = company.name;
      _welcome.text = company.welcomeMessage;
      _email.text   = company.supportEmail ?? '';
      _wa.text      = company.whatsappNumber ?? '';
      _color.text   = company.primaryColor;
      setState(() {});
    }
  }

  Future<void> _save() async {
    final name    = _name.text.trim();
    final welcome = _welcome.text.trim();
    final color   = _color.text.trim().isEmpty ? '#6366F1' : _color.text.trim();
    final hexRe   = RegExp(r'^#[0-9A-Fa-f]{6}$');
    if (name.isEmpty)               { _showErr('Company name cannot be empty.');          return; }
    if (name.length > 120)          { _showErr('Company name must be 120 chars or less.'); return; }
    if (welcome.length > 500)       { _showErr('Welcome message must be 500 chars or less.'); return; }
    if (!hexRe.hasMatch(color))     { _showErr('Brand color must be a valid hex (e.g. #6366F1).'); return; }
    setState(() { _loading = true; _saved = false; });
    try {
      await CompanyRepository().updateCompany(widget.companyId, {
        'name': name,
        'welcome_message': welcome,
        'support_email': _email.text.trim().isEmpty ? null : _email.text.trim(),
        'whatsapp_number': _wa.text.trim().isEmpty ? null : _wa.text.trim(),
        'primary_color': color,
      });
      ref.invalidate(companyProvider(widget.companyId));
      setState(() { _loading = false; _saved = true; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  void _showErr(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  @override
  void dispose() { _name.dispose(); _welcome.dispose(); _email.dispose(); _wa.dispose(); _color.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AdminScaffold(
    companyId: widget.companyId, currentRoute: AppRoutes.settings, title: 'Settings',
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Section('Company Information', [
          _Field('Company Name', _name, hint: 'Your company name'),
          _Field('Welcome Message', _welcome, hint: 'What your bot says first', maxLines: 3),
        ]),
        const SizedBox(height: 20),
        _Section('Support Contacts', [
          _Field('Support Email', _email, hint: 'support@company.com', keyboard: TextInputType.emailAddress),
          _Field('WhatsApp Number', _wa, hint: '+216 12 345 678', keyboard: TextInputType.phone),
        ]),
        const SizedBox(height: 20),
        _Section('Brand Color', [
          const SizedBox(height: 8),
          _Field('Hex Color', _color, hint: '#6366F1'),
          const SizedBox(height: 10),
          const Text('Presets', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey600)),
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 10, children: _presets.map((c) {
            final col = Color(int.parse('FF${c.replaceAll('#', '')}', radix: 16));
            final sel = _color.text.toLowerCase() == c.toLowerCase();
            return GestureDetector(
              onTap: () { setState(() => _color.text = c); },
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: col, shape: BoxShape.circle,
                  border: Border.all(color: sel ? AppColors.grey900 : Colors.transparent, width: 2.5),
                  boxShadow: sel ? [BoxShadow(color: col.withOpacity(.4), blurRadius: 8)] : []),
                child: sel ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
              ),
            );
          }).toList()),
        ]),
        const SizedBox(height: 28),
        if (_saved)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF6EE7B7))),
            child: const Row(children: [Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18), SizedBox(width: 8), Text('Settings saved successfully!', style: TextStyle(color: AppColors.success))]),
          ),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _save,
            child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save All Settings'),
          )),
      ],
    ),
  );

  Widget _Section(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.grey900)),
      const SizedBox(height: 14),
      ...children,
    ]),
  );

  Widget _Field(String label, TextEditingController ctrl, {String hint = '', int maxLines = 1, TextInputType keyboard = TextInputType.text}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey600)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, maxLines: maxLines, keyboardType: keyboard, decoration: InputDecoration(hintText: hint)),
      const SizedBox(height: 12),
    ]);
}
