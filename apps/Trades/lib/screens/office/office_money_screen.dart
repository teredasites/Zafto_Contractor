import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

class OfficeMoneyScreen extends ConsumerStatefulWidget {
  const OfficeMoneyScreen({super.key});

  @override
  ConsumerState<OfficeMoneyScreen> createState() => _OfficeMoneyScreenState();
}

class _OfficeMoneyScreenState extends ConsumerState<OfficeMoneyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Money')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _buildSummaryCard(colors, 'Unpaid', '\$0', colors.accentWarning)),
                const SizedBox(width: 8),
                Expanded(child: _buildSummaryCard(colors, 'Overdue', '\$0', colors.accentError)),
                const SizedBox(width: 8),
                Expanded(child: _buildSummaryCard(colors, 'This Month', '\$0', colors.accentSuccess)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: colors.accentPrimary,
            unselectedLabelColor: colors.textTertiary,
            indicatorColor: colors.accentPrimary,
            labelStyle: const TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Invoices'),
              Tab(text: 'Bids'),
              Tab(text: 'Payments'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEmptyTab(colors, 'No invoices yet'),
                _buildEmptyTab(colors, 'No bids yet'),
                _buildEmptyTab(colors, 'No payments yet'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ZaftoColors colors, String label, String value, Color accent) {
    return ZCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTab(ZaftoColors colors, String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          fontFamily: 'SF Pro Text',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colors.textTertiary,
        ),
      ),
    );
  }
}
