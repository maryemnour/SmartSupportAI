import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween<double>(begin: .5, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, .6, curve: Curves.elasticOut)));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(.3, .8, curve: Curves.easeIn)));
    _ctrl.forward().then((_) => _navigate());
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    if (!SupabaseService.instance.isAuthenticated) {
      context.go(AppRoutes.login);
      return;
    }
    try {
      final companyId = await AuthService.instance.getCompanyId();
      if (!mounted) return;
      if (companyId == null) {
        context.go(AppRoutes.onboarding);
      } else {
        context.go('${AppRoutes.dashboard}?companyId=$companyId');
      }
    } catch (_) {
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF818CF8)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.2), blurRadius: 32, offset: const Offset(0, 8))],
                ),
                child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 52),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _fade,
              child: Column(children: [
                const Text('Smart Support AI', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Intelligent customer support platform',
                    style: TextStyle(color: Colors.white.withOpacity(.75), fontSize: 14)),
              ]),
            ),
            const SizedBox(height: 80),
            FadeTransition(
              opacity: _fade,
              child: SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(.6)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
