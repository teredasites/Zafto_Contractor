// ZAFTO Estimate Preview Screen — Design System v2.6
// Sprint D8c (Session 86)
// Read-only summary view with totals, per-area breakdown, insurance details.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/estimate.dart';
import '../../services/estimate_engine_service.dart';

class EstimatePreviewScreen extends ConsumerStatefulWidget {
  final String estimateId;

  const EstimatePreviewScreen({super.key, required this.estimateId});

  @override
  ConsumerState<EstimatePreviewScreen> createState() => _EstimatePreviewScreenState();
}

class _EstimatePreviewScreenState extends ConsumerState<EstimatePreviewScreen> {
  Estimate? _estimate;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final service = ref.read(estimateEngineServiceProvider);
      final estimate = await service.getEstimate(widget.estimateId);
      setState(() {
        _estimate = estimate;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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

    final estimate = _estimate;
    if (estimate == null) {
      return Scaffold(
        backgroundColor: colors.bgBase,
        appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0),
        body: Center(child: Text('Estimate not found', style: TextStyle(color: colors.textSecondary))),
      );
    }

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Preview', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.share2, color: colors.textSecondary),
            onPressed: _isExporting ? null : () => _openPdf('standard'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors, estimate),
            const SizedBox(height: 16),
            if (estimate.isInsurance) ...[
              _buildInsuranceSection(colors, estimate),
              const SizedBox(height: 16),
            ],
            _buildPropertySection(colors, estimate),
            const SizedBox(height: 16),
            ...estimate.areas.map((area) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildAreaSection(colors, estimate, area),
            )),
            if (estimate.areas.isEmpty)
              _buildUnassignedItems(colors, estimate),
            const SizedBox(height: 8),
            _buildTotalsSection(colors, estimate),
            if (estimate.isInsurance) ...[
              const SizedBox(height: 16),
              _buildInsuranceTotals(colors, estimate),
            ],
            if (estimate.notes != null && estimate.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildNotesSection(colors, estimate),
            ],
            const SizedBox(height: 24),
            _buildActions(colors, estimate),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ZaftoColors colors, Estimate estimate) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Expanded(
                child: Text(estimate.displayTitle, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              ),
              _buildStatusBadge(colors, estimate.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(LucideIcons.hash, size: 14, color: colors.textTertiary),
              const SizedBox(width: 4),
              Text(estimate.estimateNumber, style: TextStyle(fontSize: 14, color: colors.textSecondary)),
              const Spacer(),
              Text(estimate.estimateType.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.accentPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            estimate.grandTotalDisplay,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ZaftoColors colors, EstimateStatus status) {
    final (color, bgColor, label) = switch (status) {
      EstimateStatus.draft => (colors.textTertiary, colors.fillDefault, 'Draft'),
      EstimateStatus.sent => (colors.accentInfo, colors.accentInfo.withValues(alpha: 0.15), 'Sent'),
      EstimateStatus.viewed => (colors.accentWarning, colors.accentWarning.withValues(alpha: 0.15), 'Viewed'),
      EstimateStatus.approved => (colors.accentSuccess, colors.accentSuccess.withValues(alpha: 0.15), 'Approved'),
      EstimateStatus.rejected => (colors.accentError, colors.accentError.withValues(alpha: 0.15), 'Rejected'),
      EstimateStatus.expired => (colors.textTertiary, colors.fillDefault, 'Expired'),
      EstimateStatus.converted => (colors.accentPrimary, colors.accentPrimary.withValues(alpha: 0.15), 'Converted'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildPropertySection(ZaftoColors colors, Estimate estimate) {
    if (estimate.fullPropertyAddress.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.mapPin, size: 20, color: colors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Property', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colors.textTertiary)),
                const SizedBox(height: 2),
                Text(estimate.fullPropertyAddress, style: TextStyle(fontSize: 14, color: colors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceSection(ZaftoColors colors, Estimate estimate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentInfo.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.shield, size: 16, color: colors.accentInfo),
              const SizedBox(width: 8),
              Text('Insurance Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.accentInfo)),
            ],
          ),
          const SizedBox(height: 12),
          if (estimate.claimNumber != null)
            _buildDetailRow(colors, 'Claim #', estimate.claimNumber!),
          if (estimate.policyNumber != null)
            _buildDetailRow(colors, 'Policy #', estimate.policyNumber!),
          if (estimate.insuranceCarrier != null)
            _buildDetailRow(colors, 'Carrier', estimate.insuranceCarrier!),
          if (estimate.adjusterName != null)
            _buildDetailRow(colors, 'Adjuster', estimate.adjusterName!),
          if (estimate.dateOfLoss != null)
            _buildDetailRow(colors, 'Date of Loss', '${estimate.dateOfLoss!.month}/${estimate.dateOfLoss!.day}/${estimate.dateOfLoss!.year}'),
          if (estimate.deductible != null)
            _buildDetailRow(colors, 'Deductible', '\$${estimate.deductible!.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: colors.textTertiary)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildAreaSection(ZaftoColors colors, Estimate estimate, EstimateArea area) {
    final areaItems = estimate.lineItems.where((li) => li.areaId == area.id).toList();
    final areaTotal = areaItems.fold<double>(0.0, (sum, li) => sum + li.lineTotal);

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
              Icon(LucideIcons.home, size: 16, color: colors.accentPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(area.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
              ),
              Text('\$${areaTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            ],
          ),
          if (area.calculatedArea > 0 || area.calculatedPerimeter > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${area.calculatedArea > 0 ? "${area.calculatedArea.toStringAsFixed(0)} SF" : ""}${area.calculatedArea > 0 && area.calculatedPerimeter > 0 ? "  |  " : ""}${area.calculatedPerimeter > 0 ? "${area.calculatedPerimeter.toStringAsFixed(0)} LF peri." : ""}',
              style: TextStyle(fontSize: 12, color: colors.textTertiary),
            ),
          ],
          if (areaItems.isNotEmpty) ...[
            const Divider(height: 20),
            ...areaItems.map((item) => _buildLineItemRow(colors, item)),
          ],
        ],
      ),
    );
  }

  Widget _buildUnassignedItems(ZaftoColors colors, Estimate estimate) {
    final unassigned = estimate.lineItems.where((li) => li.areaId == null).toList();
    if (unassigned.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Line Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          const Divider(height: 20),
          ...unassigned.map((item) => _buildLineItemRow(colors, item)),
        ],
      ),
    );
  }

  Widget _buildLineItemRow(ZaftoColors colors, EstimateLineItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description, style: TextStyle(fontSize: 13, color: colors.textPrimary)),
                Text(
                  '${item.quantity} ${item.unitCode} x \$${(item.laborRate + item.materialCost + item.equipmentCost).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 11, color: colors.textTertiary),
                ),
              ],
            ),
          ),
          Text('\$${item.lineTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildTotalsSection(ZaftoColors colors, Estimate estimate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildTotalRow(colors, 'Subtotal', '\$${estimate.subtotal.toStringAsFixed(2)}'),
          if (estimate.overheadPct > 0)
            _buildTotalRow(colors, 'Overhead (${estimate.overheadPct.toStringAsFixed(1)}%)', '\$${estimate.overheadAmount.toStringAsFixed(2)}'),
          if (estimate.profitPct > 0)
            _buildTotalRow(colors, 'Profit (${estimate.profitPct.toStringAsFixed(1)}%)', '\$${estimate.profitAmount.toStringAsFixed(2)}'),
          if (estimate.taxPct > 0)
            _buildTotalRow(colors, 'Tax (${estimate.taxPct.toStringAsFixed(1)}%)', '\$${estimate.taxAmount.toStringAsFixed(2)}'),
          const Divider(height: 20),
          _buildTotalRow(colors, 'Grand Total', estimate.grandTotalDisplay, isBold: true, isLarge: true),
        ],
      ),
    );
  }

  Widget _buildInsuranceTotals(ZaftoColors colors, Estimate estimate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentInfo.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Insurance Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.accentInfo)),
          const SizedBox(height: 12),
          _buildTotalRow(colors, 'RCV (Replacement Cost)', '\$${estimate.totalRcv.toStringAsFixed(2)}'),
          _buildTotalRow(colors, 'Depreciation', '-\$${estimate.totalDepreciation.toStringAsFixed(2)}'),
          _buildTotalRow(colors, 'ACV (Actual Cash Value)', '\$${estimate.totalAcv.toStringAsFixed(2)}'),
          if (estimate.deductible != null)
            _buildTotalRow(colors, 'Deductible', '-\$${estimate.deductible!.toStringAsFixed(2)}'),
          const Divider(height: 20),
          _buildTotalRow(colors, 'Net Claim Amount', '\$${estimate.netClaimAmount.toStringAsFixed(2)}', isBold: true),
        ],
      ),
    );
  }

  Widget _buildTotalRow(ZaftoColors colors, String label, String value, {bool isBold = false, bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isLarge ? 15 : 13, color: colors.textSecondary)),
          Text(value, style: TextStyle(
            fontSize: isLarge ? 18 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: colors.textPrimary,
          )),
        ],
      ),
    );
  }

  Widget _buildNotesSection(ZaftoColors colors, Estimate estimate) {
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
          Text('Notes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textTertiary)),
          const SizedBox(height: 8),
          Text(estimate.notes!, style: TextStyle(fontSize: 14, color: colors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildActions(ZaftoColors colors, Estimate estimate) {
    return Column(
      children: [
        if (estimate.canSend)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : () => _sendEstimate(estimate),
              icon: _isSending ? null : const Icon(LucideIcons.send, size: 18),
              label: _isSending
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.isDark ? Colors.black : Colors.white))
                  : const Text('Send to Customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: colors.isDark ? Colors.black : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _isExporting ? null : () => _openPdf('standard'),
            icon: _isExporting
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.textSecondary))
                : Icon(LucideIcons.fileText, size: 18, color: colors.textSecondary),
            label: Text('Generate PDF', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textSecondary)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.borderDefault),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final template in ['detailed', 'summary'])
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: template == 'summary' ? 8 : 0),
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: _isExporting ? null : () => _openPdf(template),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        '${template[0].toUpperCase()}${template.substring(1)} PDF',
                        style: TextStyle(fontSize: 13, color: colors.textTertiary),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _sendEstimate(Estimate estimate) async {
    setState(() => _isSending = true);
    HapticFeedback.mediumImpact();
    try {
      final service = ref.read(estimateEngineServiceProvider);
      await service.sendEstimate(estimate);
      await ref.read(estimatesProvider.notifier).loadEstimates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Estimate sent'), backgroundColor: ref.read(zaftoColorsProvider).accentSuccess),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  Future<void> _openPdf(String template) async {
    setState(() => _isExporting = true);
    HapticFeedback.lightImpact();
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke(
        'export-estimate-pdf',
        method: HttpMethod.get,
        queryParameters: {
          'estimate_id': widget.estimateId,
          'template': template,
        },
      );
      final html = response.data as String;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/estimate_$template.html');
      await file.writeAsString(html);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/html')],
        subject: 'Estimate',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

}
