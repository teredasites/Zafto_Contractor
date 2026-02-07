import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

class OfficeCustomersScreen extends ConsumerStatefulWidget {
  const OfficeCustomersScreen({super.key});

  @override
  ConsumerState<OfficeCustomersScreen> createState() => _OfficeCustomersScreenState();
}

class _OfficeCustomersScreenState extends ConsumerState<OfficeCustomersScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.add, color: colors.accentPrimary),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            ZTextField(
              hint: 'Search customers...',
              prefix: Icon(Icons.search, color: colors.textQuaternary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final filter in ['All', 'Active', 'Leads']) ...[
                  ZChip(
                    label: filter,
                    isSelected: _selectedFilter == filter,
                    onTap: () => setState(() => _selectedFilter = filter),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline, size: 48, color: colors.textQuaternary),
                    const SizedBox(height: 12),
                    Text(
                      'No customers yet',
                      style: TextStyle(
                        fontFamily: 'SF Pro Text',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customers will appear here',
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
