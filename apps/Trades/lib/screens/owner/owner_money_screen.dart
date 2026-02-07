import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

class OwnerMoneyScreen extends ConsumerStatefulWidget {
  const OwnerMoneyScreen({super.key});

  @override
  ConsumerState<OwnerMoneyScreen> createState() => _OwnerMoneyScreenState();
}

class _OwnerMoneyScreenState extends ConsumerState<OwnerMoneyScreen>
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
      appBar: AppBar(
        title: const Text('Money'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSummaryCards(colors),
          ),
          const SizedBox(height: 16),
          _buildTabBar(colors),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEmptyTab(colors, Icons.receipt_long_outlined, 'No invoices yet'),
                _buildEmptyTab(colors, Icons.description_outlined, 'No bids yet'),
                _buildEmptyTab(colors, Icons.book_outlined, 'ZBooks coming soon'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ZaftoColors colors) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            colors,
            label: 'Unpaid Invoices',
            value: '\$0',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            colors,
            label: 'Pending Bids',
            value: '\$0',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            colors,
            label: 'This Month',
            value: '\$0',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    ZaftoColors colors, {
    required String label,
    required String value,
  }) {
    return ZCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: colors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ZaftoColors colors) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.borderSubtle),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: colors.accentPrimary,
        unselectedLabelColor: colors.textTertiary,
        indicatorColor: colors.accentPrimary,
        indicatorWeight: 2,
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
          Tab(text: 'ZBooks'),
        ],
      ),
    );
  }

  Widget _buildEmptyTab(ZaftoColors colors, IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: colors.textQuaternary,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
