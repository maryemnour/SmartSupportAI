import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../services/auth_service.dart';

// ── Shared field widget ───────────────────────────────────────────────────────
class _AuthField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final bool obscure;
  final TextInputType keyboard;
  const _AuthField({
    required this.ctrl, required this.label, required this.hint,
    this.obscure = false, this.keyboard = TextInputType.text,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey600)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, obscureText: obscure, keyboardType: keyboard,
          decoration: InputDecoration(hintText: hint)),
      const SizedBox(height: 14),
    ],
  );
}

// ── Login ─────────────────────────────────────────────────────────────────────
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.instance.signIn(email: _email.text.trim(), password: _pass.text);
      if (!mounted) return;
      final companyId = await AuthService.instance.getCompanyId();
      if (!mounted) return;
      if (companyId != null) {
        context.go('${AppRoutes.dashboard}?companyId=$companyId');
      } else {
        context.go(AppRoutes.onboarding);
      }
    } catch (e) {
      setState(() { _loading = false; _error = 'Invalid email or password.'; });
    }
  }

  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(children: [
            Container(
              width: 68, height: 68,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 20),
            Text('Smart Support AI', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text('Sign in to your dashboard', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            _AuthField(ctrl: _email, label: 'Email', hint: 'you@company.com', keyboard: TextInputType.emailAddress),
            _AuthField(ctrl: _pass,  label: 'Password', hint: 'Your password', obscure: true),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Sign in'),
              ),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text("Don't have an account? "),
              TextButton(
                onPressed: () => context.go(AppRoutes.register),
                child: const Text('Sign up'),
              ),
            ]),
          ]),
        ),
      ),
    ),
  );
}

// ── Register ──────────────────────────────────────────────────────────────────
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await AuthService.instance.signUp(
        email: _email.text.trim(),
        password: _pass.text,
      );
      
      if (response.session != null) {
        if (mounted) context.go(AppRoutes.onboarding);
      } else {
        try {
          await AuthService.instance.signIn(
            email: _email.text.trim(),
            password: _pass.text,
          );
          if (mounted) context.go(AppRoutes.onboarding);
        } catch (_) {
          setState(() {
            _loading = false;
            _error = 'Check your email to confirm your account, then sign in.';
          });
        }
      }
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(children: [
            Container(
              width: 68, height: 68,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 20),
            Text('Create Account', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text('Start automating your customer support', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            _AuthField(ctrl: _email, label: 'Email', hint: 'you@company.com', keyboard: TextInputType.emailAddress),
            _AuthField(ctrl: _pass,  label: 'Password', hint: 'Minimum 8 characters', obscure: true),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create account'),
              ),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Already have an account? '),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Sign in'),
              ),
            ]),
          ]),
        ),
      ),
    ),
  );
}
