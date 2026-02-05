/// Bid Detail Screen - Design System v2.6
/// View and manage bid details
/// Sprint 16.0 - February 2026

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/bid.dart';
import '../../models/business/job.dart';
import '../../services/bid_service.dart';
import '../../services/job_service.dart';
import 'bid_create_screen.dart';
import 'bid_builder_screen.dart';
import '../jobs/job_detail_screen.dart';

class BidDetailScreen extends ConsumerStatefulWidget {
  final String bidId;

  const BidDetailScreen({super.key, required this.bidId});

  @override
  ConsumerState<BidDetailScreen> createState() => _BidDetailScreenState();
}

class _BidDetailScreenState extends ConsumerState<BidDetailScreen> {
  Bid? _bid;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBid();
  }

  Future<void> _loadBid() async {
    final service = ref.read(bidServiceProvider);
    final bid = await service.getBid(widget.bidId);
    if (mounted) {
      setState(() {
        _bid = bid;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.bgBase,
        appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0),
        body: Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
      );
    }

    if (_bid == null) {
      return Scaffold(
        backgroundColor: colors.bgBase,
        appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0),
        body: Center(child: Text('Bid not found', style: TextStyle(color: colors.textSecondary))),
      );
    }

    final bid = _bid!;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(bid.bidNumber, style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
        actions: [
          if (bid.isEditable)
            IconButton(
              icon: Icon(LucideIcons.pencil, color: colors.textSecondary),
              onPressed: () => _editBid(context, bid),
            ),
          PopupMenuButton<String>(
            icon: Icon(LucideIcons.moreVertical, color: colors.textSecondary),
            color: colors.bgElevated,
            onSelected: (value) => _handleMenuAction(value, bid),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'duplicate', child: Row(children: [Icon(LucideIcons.copy, size: 18, color: colors.textSecondary), const SizedBox(width: 12), Text('Duplicate', style: TextStyle(color: colors.textPrimary))])),
              if (bid.canSend) PopupMenuItem(value: 'send', child: Row(children: [Icon(LucideIcons.send, size: 18, color: colors.accentPrimary), const SizedBox(width: 12), Text('Send to Customer', style: TextStyle(color: colors.accentPrimary))])),
              if (bid.canConvert) PopupMenuItem(value: 'convert', child: Row(children: [Icon(LucideIcons.briefcase, size: 18, color: colors.accentSuccess), const SizedBox(width: 12), Text('Convert to Job', style: TextStyle(color: colors.accentSuccess))])),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'delete', child: Row(children: [Icon(LucideIcons.trash2, size: 18, color: colors.accentError), const SizedBox(width: 12), Text('Delete', style: TextStyle(color: colors.accentError))])),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(colors, bid),
            const SizedBox(height: 20),
            _buildCustomerCard(colors, bid),
            const SizedBox(height: 20),
            if (bid.scopeOfWork != null && bid.scopeOfWork!.isNotEmpty) ...[
              _buildScopeCard(colors, bid),
              const SizedBox(height: 20),
            ],
            _buildOptionsCard(colors, bid),
            const SizedBox(height: 20),
            if (bid.addOns.isNotEmpty) ...[
              _buildAddOnsCard(colors, bid),
              const SizedBox(height: 20),
            ],
            _buildTotalsCard(colors, bid),
            const SizedBox(height: 20),
            if (bid.hasSigned) ...[
              _buildSignatureCard(colors, bid),
              const SizedBox(height: 20),
            ],
            _buildTimelineCard(colors, bid),
            const SizedBox(height: 32),
            _buildActionButtons(colors, bid),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ZaftoColors colors, Bid bid) {
    final (statusColor, statusBg) = _getStatusColors(colors, bid.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
            child: Text(bid.statusDisplay, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: statusColor)),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(bid.totalDisplay, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              if (bid.validUntil != null && bid.isPending)
                Text('Valid until ${_formatDate(bid.validUntil!)}', style: TextStyle(fontSize: 12, color: bid.isExpired ? colors.accentError : colors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(ZaftoColors colors, Bid bid) {
    return Container(
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
              Icon(LucideIcons.user, size: 16, color: colors.textTertiary),
              const SizedBox(width: 8),
              Text('Customer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(bid.customerName, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          if (bid.projectName != null) ...[
            const SizedBox(height: 4),
            Text(bid.projectName!, style: TextStyle(fontSize: 14, color: colors.textSecondary)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.mapPin, size: 14, color: colors.textTertiary),
              const SizedBox(width: 6),
              Expanded(child: Text(bid.fullCustomerAddress, style: TextStyle(fontSize: 13, color: colors.textSecondary))),
            ],
          ),
          if (bid.customerEmail != null || bid.customerPhone != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (bid.customerEmail != null) ...[
                  Icon(LucideIcons.mail, size: 14, color: colors.textTertiary),
                  const SizedBox(width: 6),
                  Text(bid.customerEmail!, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                ],
                if (bid.customerEmail != null && bid.customerPhone != null) const SizedBox(width: 16),
                if (bid.customerPhone != null) ...[
                  Icon(LucideIcons.phone, size: 14, color: colors.textTertiary),
                  const SizedBox(width: 6),
                  Text(bid.customerPhone!, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScopeCard(ZaftoColors colors, Bid bid) {
    return Container(
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
              Icon(LucideIcons.clipboardList, size: 16, color: colors.textTertiary),
              const SizedBox(width: 8),
              Text('Scope of Work', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(bid.scopeOfWork!, style: TextStyle(fontSize: 14, color: colors.textPrimary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildOptionsCard(ZaftoColors colors, Bid bid) {
    if (bid.options.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(LucideIcons.fileText, size: 32, color: colors.textTertiary),
            const SizedBox(height: 8),
            Text('No pricing options', style: TextStyle(fontSize: 14, color: colors.textTertiary)),
            const SizedBox(height: 8),
            if (bid.isEditable)
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BidBuilderScreen(bid: bid))),
                icon: Icon(LucideIcons.plus, size: 16),
                label: const Text('Add Options'),
              ),
          ],
        ),
      );
    }

    return Container(
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
              Icon(LucideIcons.layers, size: 16, color: colors.textTertiary),
              const SizedBox(width: 8),
              Text('Pricing Options', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          ...bid.options.map((option) {
            final isSelected = bid.selectedOptionId == option.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary.withValues(alpha: 0.1) : colors.fillDefault,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(option.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                            if (option.isRecommended) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(4)),
                                child: Text('Recommended', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors.isDark ? Colors.black : Colors.white)),
                              ),
                            ],
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Icon(LucideIcons.check, size: 16, color: colors.accentSuccess),
                            ],
                          ],
                        ),
                        if (option.description != null) ...[
                          const SizedBox(height: 4),
                          Text(option.description!, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                  Text('\$${option.total.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAddOnsCard(ZaftoColors colors, Bid bid) {
    return Container(
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
              Icon(LucideIcons.plusCircle, size: 16, color: colors.textTertiary),
              const SizedBox(width: 8),
              Text('Add-Ons', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          ...bid.addOns.map((addon) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(addon.isSelected ? LucideIcons.checkSquare : LucideIcons.square, size: 18, color: addon.isSelected ? colors.accentSuccess : colors.textTertiary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(addon.name, style: TextStyle(fontSize: 14, color: colors.textPrimary))),
                    Text('\$${addon.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textSecondary)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(ZaftoColors colors, Bid bid) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          _buildTotalRow(colors, 'Subtotal', '\$${bid.subtotal.toStringAsFixed(2)}'),
          if (bid.discountAmount > 0) _buildTotalRow(colors, 'Discount', '-\$${bid.discountAmount.toStringAsFixed(2)}', color: colors.accentSuccess),
          if (bid.taxAmount > 0) _buildTotalRow(colors, 'Tax (${bid.taxRate}%)', '\$${bid.taxAmount.toStringAsFixed(2)}'),
          const Divider(height: 24),
          _buildTotalRow(colors, 'Total', bid.totalDisplay, isBold: true),
          if (bid.depositAmount > 0) ...[
            const SizedBox(height: 8),
            _buildTotalRow(colors, 'Deposit Required (${bid.depositPercent.toStringAsFixed(0)}%)', bid.depositDisplay, color: colors.accentWarning),
            if (bid.depositPaid)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(LucideIcons.check, size: 14, color: colors.accentSuccess),
                    const SizedBox(width: 4),
                    Text('Deposit paid', style: TextStyle(fontSize: 12, color: colors.accentSuccess)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalRow(ZaftoColors colors, String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.w600 : FontWeight.w400, color: colors.textSecondary)),
          Text(value, style: TextStyle(fontSize: isBold ? 18 : 14, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, color: color ?? colors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildSignatureCard(ZaftoColors colors, Bid bid) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.penTool, size: 16, color: colors.accentSuccess),
              const SizedBox(width: 8),
              Text('Signed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.accentSuccess)),
            ],
          ),
          const SizedBox(height: 12),
          Text(bid.signedByName!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          if (bid.signedAt != null)
            Text(_formatDateTime(bid.signedAt!), style: TextStyle(fontSize: 12, color: colors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(ZaftoColors colors, Bid bid) {
    return Container(
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
              Icon(LucideIcons.clock, size: 16, color: colors.textTertiary),
              const SizedBox(width: 8),
              Text('Timeline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTimelineItem(colors, 'Created', bid.createdAt, true),
          if (bid.sentAt != null) _buildTimelineItem(colors, 'Sent', bid.sentAt!, true),
          if (bid.viewedAt != null) _buildTimelineItem(colors, 'Viewed', bid.viewedAt!, true),
          if (bid.respondedAt != null) _buildTimelineItem(colors, bid.isAccepted ? 'Accepted' : 'Declined', bid.respondedAt!, true),
          if (bid.signedAt != null) _buildTimelineItem(colors, 'Signed', bid.signedAt!, true),
          if (bid.depositPaidAt != null) _buildTimelineItem(colors, 'Deposit Paid', bid.depositPaidAt!, true),
          if (bid.convertedAt != null) _buildTimelineItem(colors, 'Converted to Job', bid.convertedAt!, false),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(ZaftoColors colors, String label, DateTime date, bool hasLine) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: colors.accentPrimary, shape: BoxShape.circle)),
            if (hasLine) Container(width: 2, height: 24, color: colors.borderSubtle),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(fontSize: 14, color: colors.textPrimary)),
                Text(_formatDateTime(date), style: TextStyle(fontSize: 12, color: colors.textTertiary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ZaftoColors colors, Bid bid) {
    if (bid.status == BidStatus.draft) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BidBuilderScreen(bid: bid))),
              icon: Icon(LucideIcons.pencil, size: 18),
              label: const Text('Edit'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: colors.borderDefault),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: bid.canSend ? () => _sendBid(bid) : null,
              icon: Icon(LucideIcons.send, size: 18),
              label: const Text('Send to Customer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: colors.isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    if (bid.canConvert) {
      return ElevatedButton.icon(
        onPressed: () => _convertToJob(bid),
        icon: Icon(LucideIcons.briefcase, size: 18),
        label: const Text('Convert to Job'),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accentSuccess,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  (Color, Color) _getStatusColors(ZaftoColors colors, BidStatus status) {
    return switch (status) {
      BidStatus.draft => (colors.textTertiary, colors.fillDefault),
      BidStatus.sent => (colors.accentInfo, colors.accentInfo.withValues(alpha: 0.15)),
      BidStatus.viewed => (colors.accentWarning, colors.accentWarning.withValues(alpha: 0.15)),
      BidStatus.accepted => (colors.accentSuccess, colors.accentSuccess.withValues(alpha: 0.15)),
      BidStatus.declined => (colors.accentError, colors.accentError.withValues(alpha: 0.15)),
      BidStatus.expired => (colors.textTertiary, colors.fillDefault),
      BidStatus.converted => (colors.accentPrimary, colors.accentPrimary.withValues(alpha: 0.15)),
      BidStatus.cancelled => (colors.textTertiary, colors.fillDefault),
    };
  }

  void _editBid(BuildContext context, Bid bid) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => BidCreateScreen(editBid: bid)));
  }

  Future<void> _sendBid(Bid bid) async {
    HapticFeedback.mediumImpact();
    final service = ref.read(bidServiceProvider);
    try {
      final sentBid = await service.sendBid(bid);
      await ref.read(bidsProvider.notifier).loadBids();
      setState(() => _bid = sentBid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bid sent to ${bid.customerName}'), backgroundColor: ref.read(zaftoColorsProvider).accentSuccess));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _convertToJob(Bid bid) async {
    HapticFeedback.mediumImpact();

    // Confirm conversion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert to Job'),
        content: Text('Create a new job from bid ${bid.bidNumber}?\n\nThis will copy all customer info, pricing, and line items to the new job.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Convert', style: TextStyle(color: ref.read(zaftoColorsProvider).accentSuccess)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final jobService = ref.read(jobServiceProvider);
      final bidService = ref.read(bidServiceProvider);
      final now = DateTime.now();

      // Get selected option's line items
      final selectedOption = bid.selectedOption;
      final lineItems = selectedOption?.lineItems.map((li) => JobLineItem(
        id: 'jli_${now.millisecondsSinceEpoch}_${li.id}',
        description: li.description,
        quantity: li.quantity,
        unitPrice: li.unitPrice,
        total: li.total,
      )).toList() ?? [];

      // Calculate total from selected option + selected add-ons
      final optionTotal = selectedOption?.total ?? 0.0;
      final addOnsTotal = bid.selectedAddOns.fold(0.0, (sum, a) => sum + a.price);
      final estimatedAmount = optionTotal + addOnsTotal;

      // Create job from bid data
      final job = Job(
        id: jobService.generateId(),
        customerId: bid.customerId,
        title: bid.projectName ?? 'Job from ${bid.bidNumber}',
        customerName: bid.customerName,
        address: bid.fullCustomerAddress,
        status: JobStatus.scheduled,
        estimatedAmount: estimatedAmount,
        notes: bid.scopeOfWork,
        photoUrls: bid.photos.map((p) => p.cloudUrl ?? p.localPath).toList(),
        lineItems: lineItems,
        createdAt: now,
        updatedAt: now,
      );

      // Save job
      await jobService.saveJob(job);

      // Update bid with converted status
      final updatedBid = await bidService.convertToJob(bid.id, job.id);
      await ref.read(bidsProvider.notifier).loadBids();
      await ref.read(jobsProvider.notifier).loadJobs();

      setState(() => _bid = updatedBid);

      if (mounted) {
        final colors = ref.read(zaftoColorsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job created: ${job.title}'),
            backgroundColor: colors.accentSuccess,
            action: SnackBarAction(
              label: 'View Job',
              textColor: Colors.white,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id)),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating job: $e')),
        );
      }
    }
  }

  Future<void> _handleMenuAction(String action, Bid bid) async {
    switch (action) {
      case 'duplicate':
        final service = ref.read(bidServiceProvider);
        final duplicate = await service.duplicateBid(bid.id);
        await service.saveBid(duplicate);
        await ref.read(bidsProvider.notifier).loadBids();
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BidDetailScreen(bidId: duplicate.id)));
        }
        break;
      case 'send':
        await _sendBid(bid);
        break;
      case 'convert':
        await _convertToJob(bid);
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Bid'),
            content: Text('Are you sure you want to delete bid ${bid.bidNumber}?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: ref.read(zaftoColorsProvider).accentError))),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(bidServiceProvider).deleteBid(bid.id);
          await ref.read(bidsProvider.notifier).loadBids();
          if (mounted) Navigator.pop(context);
        }
        break;
    }
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';

  String _formatDateTime(DateTime date) => '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}
