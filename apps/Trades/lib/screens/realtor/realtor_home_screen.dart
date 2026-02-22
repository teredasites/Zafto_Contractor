// ZAFTO Realtor Home Screen — RE1 Placeholder
// Dashboard shell for realtor entity types.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/error_widgets.dart';

class RealtorHomeScreen extends ConsumerWidget {
  const RealtorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realtor Dashboard'),
      ),
      body: const Center(
        child: ZaftoEmptyState(
          icon: LucideIcons.layoutDashboard,
          title: 'Realtor Dashboard',
          subtitle: 'Your deals, leads, and metrics will appear here.',
        ),
      ),
    );
  }
}
