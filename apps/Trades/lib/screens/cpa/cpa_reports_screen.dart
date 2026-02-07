import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/zafto_theme_builder.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

class CpaReportsScreen extends ConsumerWidget {
  const CpaReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    const reports = [
      _ReportItem(Icons.trending_up, 'P&L', 'Profit & Loss Statement'),
      _ReportItem(Icons.account_balance_outlined, 'Balance Sheet', 'Assets, liabilities, equity'),
      _ReportItem(Icons.water_drop_outlined, 'Cash Flow', 'Cash flow statement'),
      _ReportItem(Icons.balance_outlined, 'Trial Balance', 'Debits and credits'),
      _ReportItem(Icons.description_outlined, 'Schedule C', 'Sole proprietor income'),
      _ReportItem(Icons.home_outlined, 'Schedule E', 'Rental property income'),
      _ReportItem(Icons.receipt_long_outlined, '1099 Report', 'Contractor payments'),
    ];

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Financial Reports')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return ZCard(
            onTap: () {},
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.accentPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(ZaftoThemeBuilder.radiusSM),
                  ),
                  child: Icon(report.icon, size: 20, color: colors.accentPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  report.label,
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.subtitle,
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: colors.textTertiary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReportItem {
  final IconData icon;
  final String label;
  final String subtitle;
  const _ReportItem(this.icon, this.label, this.subtitle);
}
