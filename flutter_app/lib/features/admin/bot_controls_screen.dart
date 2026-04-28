import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/admin_scaffold.dart';

class BotControlsScreen extends StatelessWidget {
  final String companyId;
  const BotControlsScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      companyId: companyId,
      title: 'Bot Controls',
      currentRoute: AppRoutes.botControls,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tune, size: 64, color: AppColors.grey400),
            SizedBox(height: 16),
            Text('Bot Controls', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('Advanced bot configuration', style: TextStyle(color: AppColors.grey600)),
            SizedBox(height: 24),
            Text('Coming soon...', style: TextStyle(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
