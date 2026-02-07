import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';

class InspectorMoreScreen extends ConsumerWidget {
  const InspectorMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    const items = [
      _MoreItem(Icons.verified_outlined, 'Certifications'),
      _MoreItem(Icons.person_outline, 'Profile & Settings'),
    ];

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('More')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: colors.borderSubtle),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: Icon(item.icon, color: colors.textSecondary, size: 22),
            title: Text(
              item.label,
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: colors.textQuaternary, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            onTap: () {},
          );
        },
      ),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String label;
  const _MoreItem(this.icon, this.label);
}
