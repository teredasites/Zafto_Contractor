import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

class CpaReviewScreen extends ConsumerStatefulWidget {
  const CpaReviewScreen({super.key});

  @override
  ConsumerState<CpaReviewScreen> createState() => _CpaReviewScreenState();
}

class _CpaReviewScreenState extends ConsumerState<CpaReviewScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Review Queue')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                for (final filter in ['All', 'Expenses', 'Receipts', 'Invoices']) ...[
                  ZChip(
                    label: filter,
                    isSelected: _selectedFilter == filter,
                    onTap: () => setState(() => _selectedFilter = filter),
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
                    Icon(Icons.fact_check_outlined, size: 48, color: colors.textQuaternary),
                    const SizedBox(height: 12),
                    Text(
                      'No items to review',
                      style: TextStyle(
                        fontFamily: 'SF Pro Text',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Items pending review will appear here',
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
}
