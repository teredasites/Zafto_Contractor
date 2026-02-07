// ZAFTO Claim Detail Screen — Full claim detail with 6 tabs.
// Tabs: Overview, Supplements, TPI, Moisture, Drying, Equipment

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/insurance_claim.dart';
import '../../models/claim_supplement.dart';
import '../../models/tpi_inspection.dart';
import '../../models/moisture_reading.dart';
import '../../models/drying_log.dart';
import '../../models/restoration_equipment.dart';
import '../../services/insurance_claim_service.dart';
import '../../services/restoration_service.dart';
import '../../widgets/error_widgets.dart';

class ClaimDetailScreen extends ConsumerStatefulWidget {
  final String claimId;

  const ClaimDetailScreen({super.key, required this.claimId});

  @override
  ConsumerState<ClaimDetailScreen> createState() => _ClaimDetailScreenState();
}

class _ClaimDetailScreenState extends ConsumerState<ClaimDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  InsuranceClaim? _claim;
  bool _loading = true;
  bool _transitioning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadClaim();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClaim() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(insuranceClaimRepositoryProvider);
      final claim = await repo.getClaim(widget.claimId);
      if (mounted) setState(() { _claim = claim; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(ClaimStatus newStatus) async {
    setState(() => _transitioning = true);
    try {
      final repo = ref.read(insuranceClaimRepositoryProvider);
      await repo.updateClaimStatus(widget.claimId, newStatus);
      await _loadClaim();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _transitioning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgBase = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA);

    if (_loading) {
      return Scaffold(
        backgroundColor: bgBase,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const ZaftoLoadingState(message: 'Loading claim...'),
      );
    }

    if (_claim == null) {
      return Scaffold(
        backgroundColor: bgBase,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const ZaftoEmptyState(icon: LucideIcons.alertTriangle, title: 'Claim not found'),
      );
    }

    final claim = _claim!;

    return Scaffold(
      backgroundColor: bgBase,
      appBar: AppBar(
        title: Text(claim.claimNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (claim.isActive) _buildTransitionButton(claim.claimStatus),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFFF59E0B),
          unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
          indicatorColor: const Color(0xFFF59E0B),
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Supplements'),
            Tab(text: 'TPI'),
            Tab(text: 'Moisture'),
            Tab(text: 'Drying'),
            Tab(text: 'Equipment'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(claim, isDark),
          _buildSupplementsTab(isDark),
          _buildTpiTab(isDark),
          _buildMoistureTab(isDark),
          _buildDryingTab(isDark),
          _buildEquipmentTab(isDark),
        ],
      ),
    );
  }

  Widget _buildTransitionButton(ClaimStatus currentStatus) {
    String? label;
    ClaimStatus? nextStatus;

    switch (currentStatus) {
      case ClaimStatus.newClaim:
        label = 'Request Scope'; nextStatus = ClaimStatus.scopeRequested; break;
      case ClaimStatus.scopeRequested:
        label = 'Scope Submitted'; nextStatus = ClaimStatus.scopeSubmitted; break;
      case ClaimStatus.scopeSubmitted:
        label = 'Estimate Pending'; nextStatus = ClaimStatus.estimatePending; break;
      case ClaimStatus.estimatePending:
        label = 'Approve'; nextStatus = ClaimStatus.estimateApproved; break;
      case ClaimStatus.estimateApproved:
        label = 'Start Work'; nextStatus = ClaimStatus.workInProgress; break;
      case ClaimStatus.workInProgress:
        label = 'Complete'; nextStatus = ClaimStatus.workComplete; break;
      case ClaimStatus.workComplete:
        label = 'Final Inspection'; nextStatus = ClaimStatus.finalInspection; break;
      case ClaimStatus.finalInspection:
        label = 'Settle'; nextStatus = ClaimStatus.settled; break;
      case ClaimStatus.settled:
        label = 'Close'; nextStatus = ClaimStatus.closed; break;
      default:
        break;
    }

    if (label == null || nextStatus == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton(
        onPressed: _transitioning ? null : () => _updateStatus(nextStatus!),
        child: _transitioning
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B))),
      ),
    );
  }

  // ==================== OVERVIEW TAB ====================

  Widget _buildOverviewTab(InsuranceClaim claim, bool isDark) {
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.white38 : Colors.black45;

    final netPayable = claim.netPayable;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + Carrier
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.shield, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(claim.insuranceCompany, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor))),
                    _buildStatusBadge(claim.claimStatus),
                  ],
                ),
                const SizedBox(height: 10),
                _buildInfoRow(labelColor, textColor, 'Claim #', claim.claimNumber),
                if (claim.policyNumber != null) _buildInfoRow(labelColor, textColor, 'Policy #', claim.policyNumber!),
                _buildInfoRow(labelColor, textColor, 'Category', claim.claimCategory.label),
                _buildInfoRow(labelColor, textColor, 'Loss Type', claim.lossType.label),
                _buildInfoRow(labelColor, textColor, 'Date of Loss', '${claim.dateOfLoss.month}/${claim.dateOfLoss.day}/${claim.dateOfLoss.year}'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Category-specific data
          if (claim.claimCategory != ClaimCategory.restoration && claim.data.isNotEmpty) ...[
            _buildCategoryDataCard(claim, cardColor, borderColor, textColor, labelColor),
            const SizedBox(height: 12),
          ],

          // Adjuster
          if (claim.hasAdjuster) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.user, size: 14, color: labelColor),
                      const SizedBox(width: 6),
                      Text('Adjuster', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(labelColor, textColor, 'Name', claim.adjusterName!),
                  if (claim.adjusterCompany != null) _buildInfoRow(labelColor, textColor, 'Company', claim.adjusterCompany!),
                  if (claim.adjusterPhone != null) _buildInfoRow(labelColor, textColor, 'Phone', claim.adjusterPhone!),
                  if (claim.adjusterEmail != null) _buildInfoRow(labelColor, textColor, 'Email', claim.adjusterEmail!),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Financials
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.dollarSign, size: 14, color: labelColor),
                    const SizedBox(width: 6),
                    Text('Financials', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildFinancialChip('Approved', claim.approvedAmount, const Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    _buildFinancialChip('Deductible', claim.deductible, const Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    _buildFinancialChip('Supplements', claim.supplementTotal, const Color(0xFF8B5CF6)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: netPayable >= 0 ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Net Payable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor)),
                      Text(
                        '\$${netPayable.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: netPayable >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Notes
          if (claim.notes != null && claim.notes!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 6),
                  Text(claim.notes!, style: TextStyle(fontSize: 13, color: labelColor)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ==================== SUPPLEMENTS TAB ====================

  Widget _buildSupplementsTab(bool isDark) {
    final supplementsAsync = ref.watch(claimSupplementsProvider(widget.claimId));
    return supplementsAsync.when(
      loading: () => const ZaftoLoadingState(message: 'Loading supplements...'),
      error: (e, _) => ZaftoEmptyState(icon: LucideIcons.alertTriangle, title: 'Error', subtitle: e.toString()),
      data: (supplements) {
        return Column(
          children: [
            // Header with add button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${supplements.length} supplement${supplements.length != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black45),
                  ),
                  GestureDetector(
                    onTap: () => _showCreateSupplementSheet(isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.plus, size: 13, color: Color(0xFFF59E0B)),
                          SizedBox(width: 4),
                          Text('Add Supplement', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (supplements.isEmpty)
              const Expanded(child: ZaftoEmptyState(icon: LucideIcons.fileText, title: 'No supplements', subtitle: 'Tap + to add additional scope'))
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: supplements.length,
                  itemBuilder: (_, i) => _buildSupplementCard(supplements[i], isDark),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showCreateSupplementSheet(bool isDark) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: '0');
    final rcvCtrl = TextEditingController();
    final acvCtrl = TextEditingController();
    var reason = SupplementReason.hiddenDamage;
    var saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          final textColor = isDark ? Colors.white : Colors.black87;
          final hintColor = isDark ? Colors.white38 : Colors.black38;
          final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);

          return Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('New Supplement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                      const Spacer(),
                      TextButton(
                        onPressed: saving ? null : () async {
                          if (titleCtrl.text.trim().isEmpty) return;
                          setSheetState(() => saving = true);
                          try {
                            final service = ref.read(restorationServiceProvider);
                            await service.createSupplement(
                              claimId: widget.claimId,
                              title: titleCtrl.text.trim(),
                              description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                              reason: reason,
                              amount: double.tryParse(amountCtrl.text) ?? 0,
                            );
                            ref.invalidate(claimSupplementsProvider(widget.claimId));
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          } finally {
                            if (ctx.mounted) setSheetState(() => saving = false);
                          }
                        },
                        child: saving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Save', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sheetField('Title *', titleCtrl, 'Hidden water damage behind wall', textColor, hintColor, borderColor),
                  const SizedBox(height: 10),
                  _sheetField('Description', descCtrl, 'Describe additional scope...', textColor, hintColor, borderColor, maxLines: 2),
                  const SizedBox(height: 10),
                  Text('Reason', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor.withValues(alpha: 0.6))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: SupplementReason.values.map((r) {
                      final isSelected = reason == r;
                      return GestureDetector(
                        onTap: () => setSheetState(() => reason = r),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFF59E0B) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? const Color(0xFFF59E0B) : borderColor),
                          ),
                          child: Text(r.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : textColor)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _sheetField('Amount (\$)', amountCtrl, '0.00', textColor, hintColor, borderColor, isNumber: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _sheetField('RCV', rcvCtrl, 'Optional', textColor, hintColor, borderColor, isNumber: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _sheetField('ACV', acvCtrl, 'Optional', textColor, hintColor, borderColor, isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _sheetField(String label, TextEditingController ctrl, String hint, Color textColor, Color hintColor, Color borderColor, {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor.withValues(alpha: 0.6))),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: TextStyle(fontSize: 14, color: textColor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: hintColor, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplementCard(ClaimSupplement s, bool isDark) {
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.white38 : Colors.black45;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('#${s.supplementNumber}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? Colors.white38 : Colors.black38)),
              const SizedBox(width: 8),
              Expanded(child: Text(s.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor))),
              _buildSmallBadge(s.status.label, _supplementStatusColor(s.status)),
            ],
          ),
          if (s.description != null) ...[
            const SizedBox(height: 4),
            Text(s.description!, style: TextStyle(fontSize: 12, color: mutedColor)),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Text(s.reason.label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : Colors.black38)),
              const Spacer(),
              Text('\$${s.amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
              if (s.approvedAmount != null) Text(' → \$${s.approvedAmount!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
            ],
          ),
          if (s.rcvAmount != null || s.acvAmount != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (s.rcvAmount != null) Text('RCV: \$${s.rcvAmount!.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: mutedColor)),
                if (s.rcvAmount != null && s.acvAmount != null) Text(' · ', style: TextStyle(fontSize: 10, color: mutedColor)),
                if (s.acvAmount != null) Text('ACV: \$${s.acvAmount!.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: mutedColor)),
                if (s.depreciationAmount > 0) Text(' · Dep: \$${s.depreciationAmount.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: mutedColor)),
              ],
            ),
          ],
          // Action buttons for draft supplements
          if (s.isDraft) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildSupplementAction('Submit', LucideIcons.send, const Color(0xFF3B82F6), () => _updateSupplementStatus(s.id, SupplementStatus.submitted)),
                const SizedBox(width: 8),
                _buildSupplementAction('Delete', LucideIcons.trash2, const Color(0xFFEF4444), () => _deleteSupplement(s.id)),
              ],
            ),
          ],
          if (s.isPending) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildSupplementAction('Approve', LucideIcons.checkCircle, const Color(0xFF10B981), () => _updateSupplementStatus(s.id, SupplementStatus.approved)),
                const SizedBox(width: 8),
                _buildSupplementAction('Deny', LucideIcons.xCircle, const Color(0xFFEF4444), () => _updateSupplementStatus(s.id, SupplementStatus.denied)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupplementAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }

  Color _supplementStatusColor(SupplementStatus status) {
    switch (status) {
      case SupplementStatus.draft:
        return const Color(0xFF6B7280);
      case SupplementStatus.submitted:
        return const Color(0xFF3B82F6);
      case SupplementStatus.underReview:
        return const Color(0xFF8B5CF6);
      case SupplementStatus.approved:
        return const Color(0xFF10B981);
      case SupplementStatus.denied:
        return const Color(0xFFEF4444);
      case SupplementStatus.partiallyApproved:
        return const Color(0xFFF59E0B);
    }
  }

  Future<void> _updateSupplementStatus(String supplementId, SupplementStatus newStatus) async {
    try {
      final repo = ref.read(claimSupplementRepositoryProvider);
      final existing = await repo.getSupplement(supplementId);
      if (existing == null) return;
      final Map<String, dynamic> update = {'status': newStatus.dbValue};
      final now = DateTime.now().toUtc().toIso8601String();
      if (newStatus == SupplementStatus.submitted) update['submitted_at'] = now;
      if (newStatus == SupplementStatus.approved || newStatus == SupplementStatus.denied || newStatus == SupplementStatus.partiallyApproved) update['reviewed_at'] = now;
      await ref.read(claimSupplementRepositoryProvider).updateSupplementFields(supplementId, update);
      ref.invalidate(claimSupplementsProvider(widget.claimId));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteSupplement(String supplementId) async {
    try {
      await ref.read(claimSupplementRepositoryProvider).deleteSupplement(supplementId);
      ref.invalidate(claimSupplementsProvider(widget.claimId));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ==================== TPI TAB ====================

  Widget _buildTpiTab(bool isDark) {
    final tpiAsync = ref.watch(claimTpiInspectionsProvider(widget.claimId));
    return tpiAsync.when(
      loading: () => const ZaftoLoadingState(message: 'Loading inspections...'),
      error: (e, _) => ZaftoEmptyState(icon: LucideIcons.alertTriangle, title: 'Error', subtitle: e.toString()),
      data: (inspections) {
        if (inspections.isEmpty) {
          return const ZaftoEmptyState(icon: LucideIcons.clipboardCheck, title: 'No inspections', subtitle: 'TPI inspections will appear here');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: inspections.length,
          itemBuilder: (_, i) => _buildTpiCard(inspections[i], isDark),
        );
      },
    );
  }

  Widget _buildTpiCard(TpiInspection t, bool isDark) {
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('${t.inspectionType.label} Inspection', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor))),
              _buildSmallBadge(t.status.label, t.isCompleted ? const Color(0xFF10B981) : const Color(0xFF3B82F6)),
            ],
          ),
          const SizedBox(height: 4),
          if (t.hasInspector) Text('${t.inspectorName}${t.inspectorCompany != null ? ' · ${t.inspectorCompany}' : ''}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black45)),
          if (t.scheduledDate != null) Text('Scheduled: ${t.scheduledDate!.month}/${t.scheduledDate!.day}/${t.scheduledDate!.year}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : Colors.black38)),
          if (t.result != null) ...[
            const SizedBox(height: 4),
            Text('Result: ${t.result!.label}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.isPassed ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
          ],
        ],
      ),
    );
  }

  // ==================== MOISTURE TAB ====================

  Widget _buildMoistureTab(bool isDark) {
    final moistureAsync = ref.watch(jobMoistureReadingsProvider(_claim?.jobId ?? ''));
    return moistureAsync.when(
      loading: () => const ZaftoLoadingState(message: 'Loading readings...'),
      error: (e, _) => ZaftoEmptyState(icon: LucideIcons.alertTriangle, title: 'Error', subtitle: e.toString()),
      data: (readings) {
        if (readings.isEmpty) {
          return const ZaftoEmptyState(icon: LucideIcons.droplets, title: 'No moisture readings', subtitle: 'Record moisture readings in the field');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: readings.length,
          itemBuilder: (_, i) => _buildMoistureCard(readings[i], isDark),
        );
      },
    );
  }

  Widget _buildMoistureCard(MoistureReading r, bool isDark) {
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: r.isDry ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.areaName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                Text('${r.materialType.label} · ${r.floorLevel ?? ''}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${r.readingValue}${r.readingUnit.label}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: r.isDry ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
              if (r.targetValue != null) Text('target: ${r.targetValue}%', style: TextStyle(fontSize: 10, color: isDark ? Colors.white24 : Colors.black38)),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== DRYING TAB ====================

  Widget _buildDryingTab(bool isDark) {
    final dryingAsync = ref.watch(jobDryingLogsProvider(_claim?.jobId ?? ''));
    return dryingAsync.when(
      loading: () => const ZaftoLoadingState(message: 'Loading drying logs...'),
      error: (e, _) => ZaftoEmptyState(icon: LucideIcons.alertTriangle, title: 'Error', subtitle: e.toString()),
      data: (logs) {
        if (logs.isEmpty) {
          return const ZaftoEmptyState(icon: LucideIcons.thermometer, title: 'No drying logs', subtitle: 'Drying log entries will appear here');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (_, i) => _buildDryingCard(logs[i], isDark),
        );
      },
    );
  }

  Widget _buildDryingCard(DryingLog d, bool isDark) {
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSmallBadge(d.logType.label, d.isCompletion ? const Color(0xFF10B981) : d.isSetup ? const Color(0xFF3B82F6) : const Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Expanded(child: Text(d.summary, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor))),
              Text('${d.recordedAt.month}/${d.recordedAt.day}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : Colors.black38)),
            ],
          ),
          if (d.totalEquipmentRunning > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Dehus: ${d.dehumidifiersRunning} · Movers: ${d.airMoversRunning} · Scrubbers: ${d.airScrubbersRunning}',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : Colors.black38),
            ),
          ],
          if (d.indoorTempF != null) ...[
            const SizedBox(height: 2),
            Text('Indoor: ${d.indoorTempF}°F / ${d.indoorHumidity ?? 0}% RH', style: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : Colors.black38)),
          ],
        ],
      ),
    );
  }

  // ==================== EQUIPMENT TAB ====================

  Widget _buildEquipmentTab(bool isDark) {
    final equipAsync = ref.watch(jobEquipmentProvider(_claim?.jobId ?? ''));
    return equipAsync.when(
      loading: () => const ZaftoLoadingState(message: 'Loading equipment...'),
      error: (e, _) => ZaftoEmptyState(icon: LucideIcons.alertTriangle, title: 'Error', subtitle: e.toString()),
      data: (equipment) {
        if (equipment.isEmpty) {
          return const ZaftoEmptyState(icon: LucideIcons.wrench, title: 'No equipment', subtitle: 'Deployed equipment will appear here');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: equipment.length,
          itemBuilder: (_, i) => _buildEquipmentCard(equipment[i], isDark),
        );
      },
    );
  }

  Widget _buildEquipmentCard(RestorationEquipment e, bool isDark) {
    final cardColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
      child: Row(
        children: [
          Icon(LucideIcons.wrench, size: 16, color: isDark ? Colors.white38 : Colors.black38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(e.equipmentType.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor))),
                    _buildSmallBadge(e.status.label, e.isDeployed ? const Color(0xFF10B981) : const Color(0xFF6B7280)),
                  ],
                ),
                const SizedBox(height: 2),
                Text('${e.areaDeployed}${e.make != null ? ' · ${e.make} ${e.model ?? ""}' : ''}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${e.totalCost.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
              Text('\$${e.dailyRate}/day × ${e.daysDeployed}d', style: TextStyle(fontSize: 10, color: isDark ? Colors.white24 : Colors.black38)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDataCard(InsuranceClaim claim, Color cardColor, Color borderColor, Color textColor, Color labelColor) {
    final iconData = switch (claim.claimCategory) {
      ClaimCategory.storm => LucideIcons.cloudLightning,
      ClaimCategory.reconstruction => LucideIcons.hardHat,
      ClaimCategory.commercial => LucideIcons.building2,
      ClaimCategory.restoration => LucideIcons.droplets,
    };
    final accentColor = switch (claim.claimCategory) {
      ClaimCategory.storm => const Color(0xFF8B5CF6),
      ClaimCategory.reconstruction => const Color(0xFFF97316),
      ClaimCategory.commercial => const Color(0xFF10B981),
      ClaimCategory.restoration => const Color(0xFF3B82F6),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, size: 14, color: accentColor),
              const SizedBox(width: 6),
              Text('${claim.claimCategory.label} Details',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildCategoryDataRows(claim, labelColor, textColor),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryDataRows(InsuranceClaim claim, Color labelColor, Color textColor) {
    switch (claim.claimCategory) {
      case ClaimCategory.storm:
        final d = claim.stormData;
        return [
          _buildInfoRow(labelColor, textColor, 'Severity', d.stormSeverity[0].toUpperCase() + d.stormSeverity.substring(1)),
          if (d.weatherEventType != null) _buildInfoRow(labelColor, textColor, 'Event', d.weatherEventType!.replaceAll('_', ' ')),
          if (d.emergencyTarped) _buildInfoRow(labelColor, textColor, 'Tarped', 'Yes'),
          if (d.aerialAssessmentNeeded) _buildInfoRow(labelColor, textColor, 'Aerial', 'Assessment needed'),
          if (d.temporaryRepairs != null) _buildInfoRow(labelColor, textColor, 'Temp Repairs', d.temporaryRepairs!),
        ];
      case ClaimCategory.reconstruction:
        final d = claim.reconstructionData;
        return [
          _buildReconstructionWorkflow(d.currentPhase, textColor, labelColor),
          if (d.expectedDurationMonths != null) _buildInfoRow(labelColor, textColor, 'Duration', '${d.expectedDurationMonths} months'),
          if (d.permitsRequired) _buildInfoRow(labelColor, textColor, 'Permits', d.permitStatus?.replaceAll('_', ' ') ?? 'Required'),
          if (d.multiContractor) _buildInfoRow(labelColor, textColor, 'Contractors', 'Multi-contractor'),
        ];
      case ClaimCategory.commercial:
        final d = claim.commercialData;
        return [
          if (d.propertyType != null) _buildInfoRow(labelColor, textColor, 'Property', d.propertyType!.replaceAll('_', ' ')),
          if (d.businessName != null) _buildInfoRow(labelColor, textColor, 'Business', d.businessName!),
          if (d.tenantName != null) _buildInfoRow(labelColor, textColor, 'Tenant', d.tenantName!),
          if (d.tenantContact != null) _buildInfoRow(labelColor, textColor, 'Contact', d.tenantContact!),
          if (d.businessIncomeLoss != null) _buildInfoRow(labelColor, textColor, 'Income Loss', '\$${d.businessIncomeLoss!.toStringAsFixed(0)}'),
          if (d.businessInterruptionDays != null) _buildInfoRow(labelColor, textColor, 'Interruption', '${d.businessInterruptionDays} days'),
          if (d.emergencyAuthAmount != null) _buildInfoRow(labelColor, textColor, 'Emergency Auth', '\$${d.emergencyAuthAmount!.toStringAsFixed(0)}'),
        ];
      case ClaimCategory.restoration:
        return [];
    }
  }

  // 10-stage reconstruction workflow
  static const _reconStages = [
    ('scope_review', 'Scope Review'),
    ('selections', 'Selections'),
    ('materials', 'Materials'),
    ('demo', 'Demo'),
    ('rough_in', 'Rough-In'),
    ('inspection', 'Inspection'),
    ('finish', 'Finish'),
    ('walkthrough', 'Walkthrough'),
    ('supplements', 'Supplements'),
    ('payment', 'Payment'),
  ];

  Widget _buildReconstructionWorkflow(String currentPhase, Color textColor, Color labelColor) {
    const accent = Color(0xFFF97316);
    final currentIdx = _reconStages.indexWhere((s) => s.$1 == currentPhase);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Workflow', style: TextStyle(fontSize: 11, color: labelColor, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _reconStages.length,
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(width: 16, height: 2, child: ColoredBox(color: labelColor.withValues(alpha: 0.2))),
              ),
              itemBuilder: (_, i) {
                final (key, label) = _reconStages[i];
                final isComplete = currentIdx >= 0 && i < currentIdx;
                final isCurrent = key == currentPhase;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrent ? accent : isComplete ? accent.withValues(alpha: 0.3) : Colors.transparent,
                        border: Border.all(color: isCurrent || isComplete ? accent : labelColor.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: isComplete ? const Icon(LucideIcons.check, size: 10, color: Colors.white) : null,
                    ),
                    const SizedBox(height: 4),
                    Text(label, style: TextStyle(fontSize: 8, color: isCurrent ? accent : labelColor, fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  Widget _buildStatusBadge(ClaimStatus status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case ClaimStatus.settled: bgColor = const Color(0xFFD1FAE5); textColor = const Color(0xFF059669); break;
      case ClaimStatus.denied: bgColor = const Color(0xFFFEE2E2); textColor = const Color(0xFFDC2626); break;
      case ClaimStatus.closed: bgColor = const Color(0xFFF3F4F6); textColor = const Color(0xFF6B7280); break;
      case ClaimStatus.workInProgress: bgColor = const Color(0xFFDBEAFE); textColor = const Color(0xFF1D4ED8); break;
      default: bgColor = const Color(0xFFFEF3C7); textColor = const Color(0xFFD97706);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Text(status.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  Widget _buildSmallBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildInfoRow(Color labelColor, Color valueColor, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: TextStyle(fontSize: 12, color: labelColor))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: valueColor))),
        ],
      ),
    );
  }

  Widget _buildFinancialChip(String label, double? value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
            const SizedBox(height: 2),
            Text(
              value != null ? '\$${value.toStringAsFixed(0)}' : '—',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
