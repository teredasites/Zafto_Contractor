import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

class InspectorHistoryScreen extends ConsumerStatefulWidget {
  const InspectorHistoryScreen({super.key});

  @override
  ConsumerState<InspectorHistoryScreen> createState() => _InspectorHistoryScreenState();
}

class _InspectorHistoryScreenState extends ConsumerState<InspectorHistoryScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Inspection History')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            ZTextField(
              hint: 'Search inspections...',
              prefix: Icon(Icons.search, color: colors.textQuaternary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final filter in ['All', 'Pass', 'Fail', 'Conditional']) ...[
                  ZChip(
                    label: filter,
                    isSelected: _selectedFilter == filter,
                    onTap: () => setState(() => _selectedFilter = filter),
                    color: _chipColor(colors, filter),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_outlined, size: 48, color: colors.textQuaternary),
                    const SizedBox(height: 12),
                    Text(
                      'No inspection history',
                      style: TextStyle(
                        fontFamily: 'SF Pro Text',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Completed inspections will appear here',
                      style: TextStyle(
                        fontFamily: 'SF Pro Text',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color? _chipColor(ZaftoColors colors, String filter) {
    switch (filter) {
      case 'Pass':
        return colors.accentSuccess;
      case 'Fail':
        return colors.accentError;
      case 'Conditional':
        return colors.accentWarning;
      default:
        return null;
    }
  }
}
