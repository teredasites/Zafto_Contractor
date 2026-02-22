// ZAFTO Realtor Pipeline Screen — RE1 Placeholder
// Deal pipeline / lead pipeline view.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/error_widgets.dart';

class RealtorPipelineScreen extends ConsumerWidget {
  const RealtorPipelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pipeline'),
      ),
      body: const Center(
        child: ZaftoEmptyState(
          icon: LucideIcons.trendingUp,
          title: 'Deal Pipeline',
          subtitle: 'Your active deals and leads will appear here.',
        ),
      ),
    );
  }
}
