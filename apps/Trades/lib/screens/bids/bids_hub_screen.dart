/// Bids Hub Screen - Design System v2.6
/// Sprint 16.0 - February 2026

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/bid.dart';
import '../../services/bid_service.dart';
import 'bid_detail_screen.dart';
import 'bid_create_screen.dart';
import '../contract_analyzer/contract_analyzer_hub_screen.dart';

class BidsHubScreen extends ConsumerStatefulWidget {
  const BidsHubScreen({super.key});
  @override
  ConsumerState<BidsHubScreen> createState() => _BidsHubScreenState();
}

class _BidsHubScreenState extends ConsumerState<BidsHubScreen> {
  BidStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final bidsAsync = ref.watch(bidsProvider);
    final stats = ref.watch(bidStatsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Bids', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
        actions: [
          // Contract Analyzer button with AI badge
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ContractAnalyzerHubScreen()));
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.fileSearch, size: 16, color: colors.accentPrimary),
                  const SizedBox(width: 6),
                  Text('Contracts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary)),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: colors.accentPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: colors.accentPrimary.withOpacity(0.3), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.sparkles, size: 8, color: colors.accentPrimary),
                        const SizedBox(width: 2),
                        Text('AI', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: colors.accentPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.search, color: colors.textSecondary),
            onPressed: () => HapticFeedback.lightImpact(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsBar(colors, stats),
          _buildFilterChips(colors),
          Expanded(
            child: bidsAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
              error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: colors.textSecondary))),
              data: (bids) {
                final filtered = _filterStatus == null ? bids : bids.where((b) => b.status == _filterStatus).toList();
                if (filtered.isEmpty) return _buildEmptyState(colors);
                return _buildBidsList(colors, filtered);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createBid(context),
        backgroundColor: colors.accentPrimary,
        child: Icon(LucideIcons.plus, color: colors.isDark ? Colors.black : Colors.white),
      ),
    );
  }

  Widget _buildStatsBar(ZaftoColors colors, BidStats stats) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          _buildStatItem(colors, '${stats.sentBids}', 'Pending', colors.accentWarning),
          _buildStatDivider(colors),
          _buildStatItem(colors, '${stats.acceptedBids}', 'Won', colors.accentSuccess),
          _buildStatDivider(colors),
          _buildStatItem(colors, stats.winRateDisplay, 'Win Rate', colors.accentPrimary),
          _buildStatDivider(colors),
          _buildStatItem(colors, '\$${_formatAmount(stats.pendingValue)}', 'Pipeline', colors.textPrimary),
        ],
      ),
    );
  }

  Widget _buildStatItem(ZaftoColors colors, String value, String label, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: valueColor)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: colors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildStatDivider(ZaftoColors colors) {
    return Container(width: 1, height: 32, color: colors.borderSubtle);
  }

  Widget _buildFilterChips(ZaftoColors colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildChip(colors, 'All', null),
          _buildChip(colors, 'Draft', BidStatus.draft),
          _buildChip(colors, 'Sent', BidStatus.sent),
          _buildChip(colors, 'Viewed', BidStatus.viewed),
          _buildChip(colors, 'Accepted', BidStatus.accepted),
          _buildChip(colors, 'Declined', BidStatus.rejected),
        ],
      ),
    );
  }

  Widget _buildChip(ZaftoColors colors, String label, BidStatus? status) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _filterStatus = status);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary : colors.fillDefault,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBidsList(ZaftoColors colors, List<Bid> bids) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bids.length,
      itemBuilder: (context, index) => _buildBidCard(colors, bids[index]),
    );
  }

  Widget _buildBidCard(ZaftoColors colors, Bid bid) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BidDetailScreen(bidId: bid.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusBadge(colors, bid.status),
                const Spacer(),
                Text(bid.bidNumber, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textTertiary)),
              ],
            ),
            const SizedBox(height: 10),
            Text(bid.displayTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            const SizedBox(height: 4),
            Text(bid.customerName, style: TextStyle(fontSize: 14, color: colors.textSecondary)),
            if (bid.customerAddress.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(LucideIcons.mapPin, size: 12, color: colors.textTertiary),
                  const SizedBox(width: 4),
                  Expanded(child: Text(bid.customerAddress, style: TextStyle(fontSize: 12, color: colors.textTertiary), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(bid.totalDisplay, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                const SizedBox(width: 12),
                if (bid.options.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.fillDefault,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('${bid.options.length} option${bid.options.length > 1 ? 's' : ''}', style: TextStyle(fontSize: 11, color: colors.textTertiary)),
                  ),
                const Spacer(),
                if (bid.validUntil != null && bid.isPending)
                  Text('Expires ${_formatDate(bid.validUntil!)}', style: TextStyle(fontSize: 11, color: bid.isExpired ? colors.accentError : colors.textTertiary)),
                const SizedBox(width: 8),
                Icon(LucideIcons.chevronRight, size: 18, color: colors.textQuaternary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ZaftoColors colors, BidStatus status) {
    final (color, bgColor, label) = switch (status) {
      BidStatus.draft => (colors.textTertiary, colors.fillDefault, 'Draft'),
      BidStatus.sent => (colors.accentInfo, colors.accentInfo.withValues(alpha: 0.15), 'Sent'),
      BidStatus.viewed => (colors.accentWarning, colors.accentWarning.withValues(alpha: 0.15), 'Viewed'),
      BidStatus.accepted => (colors.accentSuccess, colors.accentSuccess.withValues(alpha: 0.15), 'Accepted'),
      BidStatus.rejected => (colors.accentError, colors.accentError.withValues(alpha: 0.15), 'Declined'),
      BidStatus.expired => (colors.textTertiary, colors.fillDefault, 'Expired'),
      BidStatus.converted => (colors.accentPrimary, colors.accentPrimary.withValues(alpha: 0.15), 'Converted'),
      BidStatus.cancelled => (colors.textTertiary, colors.fillDefault, 'Cancelled'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildEmptyState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: colors.fillDefault, shape: BoxShape.circle),
            child: Icon(LucideIcons.fileText, size: 40, color: colors.textTertiary),
          ),
          const SizedBox(height: 16),
          Text('No bids yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          const SizedBox(height: 6),
          Text('Tap + to create your first bid', style: TextStyle(fontSize: 14, color: colors.textTertiary)),
        ],
      ),
    );
  }

  void _createBid(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BidCreateScreen()));
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}k';
    return amount.toStringAsFixed(0);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 0) return 'Expired';
    if (diff <= 7) return 'in $diff days';
    return '${date.month}/${date.day}';
  }
}
