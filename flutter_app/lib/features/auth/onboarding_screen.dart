import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  String _color = '#6366F1';
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _waCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _show('Company name is required');
      return;
    }

    setState(() => _loading = true);

    try {
      final sb = Supabase.instance.client;
      final user = sb.auth.currentUser;
      if (user == null) throw 'Not authenticated';

      final compId = const Uuid().v4();
      final key = _genKey(32);

    await sb.from('companies').insert({
        'id': compId,
        'name': _nameCtrl.text.trim(),
        'slug': '${_nameCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-')}-${DateTime.now().millisecondsSinceEpoch}',
        'primary_color': _color,
        'welcome_message': "Hello! I'm ${_nameCtrl.text.trim()}'s AI assistant. How can I help?",
        'support_email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'whatsapp_number': _waCtrl.text.trim().isEmpty ? null : _waCtrl.text.trim(),
        'plan': 'free',
        'api_key': key,
        'is_active': true,
      });

      await sb.from('users').upsert({
        'id': user.id,
        'company_id': compId,
        'role': 'admin',
        'email': user.email,
      });

      // Send welcome email
      try {
        await sb.functions.invoke('send-welcome-email', body: {
          'to': user.email,
          'companyName': _nameCtrl.text.trim(),
          'companyId': compId,
          'apiKey': key,
        });
      } catch (emailError) {
        // Email failed but don't block registration
        debugPrint('Welcome email failed: $emailError');
      }

      if (mounted) context.go('${AppRoutes.dashboard}?companyId=$compId');
    } catch (e) {
      setState(() => _loading = false);
      _show('Failed: ${e.toString()}');
    }
  }

  void _show(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error));

  String _genKey(int n) {
    const c = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    return List.generate(n, (i) => c[(now * (i + 7)) % c.length]).join();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Set up your company'), automaticallyImplyLeading: false),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome! 👋', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text('Tell us about your company to get started.',
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 28),
                const Text('Company name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. Acme Inc')),
                const SizedBox(height: 16),
                const Text('Support email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(hintText: 'support@acme.com')),
                const SizedBox(height: 16),
                const Text('WhatsApp number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                    controller: _waCtrl,
                    decoration: const InputDecoration(hintText: '+1234567890')),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Create Company'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
