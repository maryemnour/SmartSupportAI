import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _waCtrl      = TextEditingController();
  bool _loading = false;
  String _color = '#6366F1';

  static const _colors = ['#6366F1','#8B5CF6','#EC4899','#EF4444','#F59E0B','#10B981','#3B82F6'];

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) { _show('Please enter your company name.'); return; }
    setState(() => _loading = true);
    try {
      final sb      = Supabase.instance.client;
      final user    = sb.auth.currentUser!;
      final key     = 'sk_${_genKey(32)}';
      final compId  = const Uuid().v4();
      final slug    = _nameCtrl.text.trim().toLowerCase().replaceAll(' ', '-').replaceAll(RegExp(r'[^a-z0-9\-]'), '');

      await sb.from('companies').insert({
        'id': compId,
        'name': _nameCtrl.text.trim(),
        'slug': slug.isEmpty ? 'company-${DateTime.now().millisecondsSinceEpoch}' : slug,
        'primary_color': _color,
        'welcome_message': "Hello! I'm ${_nameCtrl.text.trim()}'s AI assistant. How can I help?",
        'support_email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'whatsapp_number': _waCtrl.text.trim().isEmpty ? null : _waCtrl.text.trim(),
        'plan': 'free', 'api_key': key, 'is_active': true,
      });

      await sb.from('users').upsert({
        'id': user.id, 'company_id': compId, 'role': 'admin', 'email': user.email,
      });

      if (mounted) context.go('${AppRoutes.dashboard}?companyId=$compId');
    } catch (e, st) {
      setState(() => _loading = false);
      debugPrint('ONBOARDING ERROR TYPE: ${e.runtimeType}');
      debugPrint('ONBOARDING ERROR: $e');
      debugPrint('ONBOARDING STACK: $st');
      _show('Failed: ${e.toString()}');
    }
  }

  void _show(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));

  String _genKey(int n) {
    const c = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    return List.generate(n, (i) => c[(now * (i + 7)) % c.length]).join();
  }

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _waCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Set up your company'), automaticallyImplyLeading: false),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome! 👋', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('Tell us about your company to get started.', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 28),
          _label('Company name *'),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'e.g. Acme Corp')),
          const SizedBox(height: 14),
          _label('Support email'),
          TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'support@company.com')),
          const SizedBox(height: 14),
          _label('WhatsApp number'),
          TextField(controller: _waCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '+216 12 345 678')),
          const SizedBox(height: 20),
          _label('Brand color'),
          const SizedBox(height: 8),
          Wrap(spacing: 10, children: _colors.map((c) {
            final color = Color(int.parse('FF${c.replaceAll('#','')}', radix: 16));
            final selected = c == _color;
            return GestureDetector(
              onTap: () => setState(() => _color = c),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                  border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 3),
                  boxShadow: selected ? [BoxShadow(color: color.withOpacity(.5), blurRadius: 10)] : []),
                child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
              ),
            );
          }).toList()),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _create,
              child: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Create my company'),
            )),
        ]),
      ),
    ),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey600)),
  );
}
