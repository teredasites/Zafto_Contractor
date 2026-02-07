import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

class CpaAccountsScreen extends ConsumerWidget {
  const CpaAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    final groups = ['Assets', 'Liabilities', 'Equity', 'Revenue', 'Expenses'];

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Chart of Accounts')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ZTextField(
              hint: 'Search accounts...',
              prefix: Icon(Icons.search, color: colors.textQuaternary),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        group.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'SF Pro Text',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: colors.textTertiary,
                        ),
                      ),
                    ),
                    ZCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Center(
                        child: Text(
                          'No $group accounts',
                          style: TextStyle(
                            fontFamily: 'SF Pro Text',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: colors.textQuaternary,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
