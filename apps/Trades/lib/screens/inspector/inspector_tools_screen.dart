import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';

class InspectorToolsScreen extends ConsumerWidget {
  const InspectorToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    const tools = [
      _ToolItem(Icons.menu_book_outlined, 'Code Lookup', 'Search building and trade codes'),
      _ToolItem(Icons.straighten_outlined, 'Measurement Tools', 'Distance, area, and volume'),
      _ToolItem(Icons.map_outlined, 'Floor Plan Viewer', 'View and annotate floor plans'),
      _ToolItem(Icons.edit_outlined, 'Photo Annotation', 'Mark up inspection photos'),
    ];

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Inspector Tools')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: tools.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: colors.borderSubtle),
        itemBuilder: (context, index) {
          final tool = tools[index];
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.accentPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(tool.icon, size: 20, color: colors.accentPrimary),
            ),
            title: Text(
              tool.label,
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            subtitle: Text(
              tool.subtitle,
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: colors.textTertiary,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: colors.textQuaternary, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            onTap: () {},
          );
        },
      ),
    );
  }
}

class _ToolItem {
  final IconData icon;
  final String label;
  final String subtitle;
  const _ToolItem(this.icon, this.label, this.subtitle);
}
