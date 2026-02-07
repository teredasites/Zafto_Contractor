import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/property.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class LeaseDetailScreen extends ConsumerStatefulWidget {
  final String leaseId;

  const LeaseDetailScreen({super.key, required this.leaseId});

  @override
  ConsumerState<LeaseDetailScreen> createState() => _LeaseDetailScreenState();
}

class _LeaseDetailScreenState extends ConsumerState<LeaseDetailScreen> {
  Lease? _lease;
  bool _isLoading = true;
  String? _error;

  final _currencyFormat = NumberFormat.currency(symbol: '\$');
  String _formatMoney(double v) => _currencyFormat.format(v);
  String _formatDate(DateTime? d) =>
      d != null ? DateFormat.yMMMd().format(d) : 'N/A';

  @override
  void initState() {
    super.initState();
    _loadLease();
  }

  Future<void> _loadLease() async {
    try {
      // TODO: Add getLease(id) to PropertyService when lease CRUD is wired.
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Lease detail loading not yet wired';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _leaseStatusColor(ZaftoColors colors, LeaseStatus status) {
    switch (status) {
      case LeaseStatus.active:
        return colors.accentSuccess;
      case LeaseStatus.expiring:
        return colors.accentWarning;
      case LeaseStatus.expired:
        return colors.accentError;
      case LeaseStatus.terminated:
        return colors.accentError;
      case LeaseStatus.draft:
        return colors.textTertiary;
      case LeaseStatus.renewed:
        return colors.accentInfo;
    }
  }

  String _formatLeaseStatus(LeaseStatus status) {
    switch (status) {
      case LeaseStatus.active:
        return 'ACTIVE';
      case LeaseStatus.expiring:
        return 'EXPIRING';
      case LeaseStatus.expired:
        return 'EXPIRED';
      case LeaseStatus.terminated:
        return 'TERMINATED';
      case LeaseStatus.draft:
        return 'DRAFT';
      case LeaseStatus.renewed:
        return 'RENEWED';
    }
  }

  String _formatLeaseType(LeaseType type) {
    switch (type) {
      case LeaseType.fixedTerm:
        return 'Fixed Term';
      case LeaseType.monthToMonth:
        return 'Month-to-Month';
      case LeaseType.shortTerm:
        return 'Short Term';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        title: Text(
          'Lease',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: colors.accentPrimary),
            )
          : _lease == null
              ? _buildPlaceholder(colors)
              : _buildContent(colors, _lease!),
    );
  }

  Widget _buildPlaceholder(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.fileText,
              size: 40, color: colors.textQuaternary),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Lease not found',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ZaftoColors colors, Lease lease) {
    final statusColor = _leaseStatusColor(colors, lease.status);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Status badge
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _formatLeaseStatus(lease.status),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (lease.isExpiringSoon) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.accentWarning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'EXPIRING SOON',
                  style: TextStyle(
                    color: colors.accentWarning,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        // Lease terms
        _SectionCard(
          colors: colors,
          title: 'Lease Terms',
          icon: LucideIcons.fileText,
          children: [
            _InfoRow(
                colors: colors,
                label: 'Lease Type',
                value: _formatLeaseType(lease.leaseType)),
            _InfoRow(
                colors: colors,
                label: 'Start Date',
                value: _formatDate(lease.startDate)),
            _InfoRow(
                colors: colors,
                label: 'End Date',
                value: _formatDate(lease.endDate)),
            _InfoRow(
                colors: colors,
                label: 'Auto-Renew',
                value: lease.autoRenew ? 'Yes' : 'No'),
            if (lease.renewalTerms != null)
              _InfoRow(
                  colors: colors,
                  label: 'Renewal Terms',
                  value: lease.renewalTerms!),
            if (lease.paymentDueDay != null)
              _InfoRow(
                  colors: colors,
                  label: 'Payment Due Day',
                  value: '${lease.paymentDueDay}'),
          ],
        ),
        const SizedBox(height: 12),
        // Rent & fees
        _SectionCard(
          colors: colors,
          title: 'Rent & Fees',
          icon: LucideIcons.banknote,
          children: [
            _InfoRow(
                colors: colors,
                label: 'Monthly Rent',
                value: _formatMoney(lease.monthlyRent)),
            _InfoRow(
                colors: colors,
                label: 'Security Deposit',
                value: lease.securityDeposit != null
                    ? _formatMoney(lease.securityDeposit!)
                    : 'N/A'),
            _InfoRow(
                colors: colors,
                label: 'Late Fee',
                value: lease.lateFeeAmount != null
                    ? _formatMoney(lease.lateFeeAmount!)
                    : 'N/A'),
            if (lease.lateFeeGraceDays != null)
              _InfoRow(
                  colors: colors,
                  label: 'Grace Days',
                  value: '${lease.lateFeeGraceDays}'),
            _InfoRow(
                colors: colors,
                label: 'Pet Deposit',
                value: lease.petDeposit != null
                    ? _formatMoney(lease.petDeposit!)
                    : 'N/A'),
            if (lease.petRent != null)
              _InfoRow(
                  colors: colors,
                  label: 'Pet Rent',
                  value: _formatMoney(lease.petRent!)),
          ],
        ),
        const SizedBox(height: 12),
        // Signing info
        _SectionCard(
          colors: colors,
          title: 'Signing',
          icon: LucideIcons.penTool,
          children: [
            _InfoRow(
                colors: colors,
                label: 'Signed Date',
                value: _formatDate(lease.signedDate)),
            _InfoRow(
                colors: colors,
                label: 'Document',
                value: lease.signedDocumentUrl != null
                    ? 'Attached'
                    : 'None'),
          ],
        ),
        // Termination info
        if (lease.status == LeaseStatus.terminated) ...[
          const SizedBox(height: 12),
          _SectionCard(
            colors: colors,
            title: 'Termination',
            icon: LucideIcons.xCircle,
            children: [
              _InfoRow(
                  colors: colors,
                  label: 'Termination Date',
                  value: _formatDate(lease.terminationDate)),
              if (lease.terminationReason != null)
                _InfoRow(
                    colors: colors,
                    label: 'Reason',
                    value: lease.terminationReason!),
            ],
          ),
        ],
        // Notes
        if (lease.notes != null && lease.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            colors: colors,
            title: 'Notes',
            icon: LucideIcons.stickyNote,
            children: [
              Text(
                lease.notes!,
                style:
                    TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        // Actions
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                colors: colors,
                label: 'Renew Lease',
                icon: LucideIcons.refreshCw,
                isPrimary: true,
                onTap: () {
                  HapticFeedback.selectionClick();
                  // TODO: Renew lease flow
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                colors: colors,
                label: 'Terminate',
                icon: LucideIcons.xCircle,
                isPrimary: false,
                onTap: () => _showTerminateDialog(colors),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showTerminateDialog(ZaftoColors colors) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgElevated,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Terminate Lease?',
          style: TextStyle(
              color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will terminate the lease. This action cannot be undone.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Call terminate lease service
            },
            child: Text('Terminate',
                style: TextStyle(color: colors.accentError)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================

class _ActionButton extends StatelessWidget {
  final ZaftoColors colors;
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.colors,
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? colors.accentPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary ? colors.accentPrimary : colors.borderDefault,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  isPrimary ? colors.textOnAccent : colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary
                    ? colors.textOnAccent
                    : colors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final ZaftoColors colors;
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.colors,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colors.accentPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final ZaftoColors colors;
  final String label;
  final String value;

  const _InfoRow({
    required this.colors,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
