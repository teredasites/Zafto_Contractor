import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/property.dart';
import '../../services/property_service.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import 'tenant_detail_screen.dart';
import 'lease_detail_screen.dart';

class UnitDetailScreen extends ConsumerStatefulWidget {
  final String unitId;
  final String propertyId;

  const UnitDetailScreen({
    super.key,
    required this.unitId,
    required this.propertyId,
  });

  @override
  ConsumerState<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends ConsumerState<UnitDetailScreen> {
  Unit? _unit;
  bool _isLoading = true;
  String? _error;

  String _formatMoney(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  void initState() {
    super.initState();
    _loadUnit();
  }

  Future<void> _loadUnit() async {
    try {
      final service = ref.read(propertyServiceProvider);
      final units = await service.getUnits(propertyId: widget.propertyId);
      final match = units.where((u) => u.id == widget.unitId);
      if (mounted) {
        setState(() {
          _unit = match.isNotEmpty ? match.first : null;
          _isLoading = false;
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

  Color _unitStatusColor(ZaftoColors colors, UnitStatus status) {
    switch (status) {
      case UnitStatus.occupied:
        return colors.accentSuccess;
      case UnitStatus.vacant:
        return colors.accentWarning;
      case UnitStatus.maintenance:
        return colors.accentError;
      case UnitStatus.unitTurn:
        return colors.accentInfo;
      case UnitStatus.listed:
        return colors.accentPrimary;
      case UnitStatus.offline:
        return colors.textTertiary;
    }
  }

  String _formatStatus(UnitStatus status) {
    switch (status) {
      case UnitStatus.occupied:
        return 'OCCUPIED';
      case UnitStatus.vacant:
        return 'VACANT';
      case UnitStatus.maintenance:
        return 'MAINTENANCE';
      case UnitStatus.unitTurn:
        return 'UNIT TURN';
      case UnitStatus.listed:
        return 'LISTED';
      case UnitStatus.offline:
        return 'OFFLINE';
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
          _unit?.unitNumber ?? 'Unit',
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
          : _error != null
              ? Center(
                  child: Text(
                    'Error: $_error',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                )
              : _unit == null
                  ? Center(
                      child: Text(
                        'Unit not found',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    )
                  : _buildContent(colors, _unit!),
    );
  }

  Widget _buildContent(ZaftoColors colors, Unit unit) {
    final statusColor = _unitStatusColor(colors, unit.status);

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
                _formatStatus(unit.status),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Unit info
        _InfoCard(
          colors: colors,
          title: 'Unit Info',
          icon: LucideIcons.home,
          rows: [
            _InfoRowData('Unit Number', unit.unitNumber),
            _InfoRowData('Bedrooms', '${unit.bedrooms ?? 'N/A'}'),
            _InfoRowData('Bathrooms', '${unit.bathrooms ?? 'N/A'}'),
            _InfoRowData(
                'Square Feet', '${unit.squareFeet ?? 'N/A'}'),
            if (unit.floorLevel != null)
              _InfoRowData('Floor Level', '${unit.floorLevel}'),
            _InfoRowData('Monthly Rent', _formatMoney(unit.monthlyRent)),
            if (unit.securityDeposit != null)
              _InfoRowData(
                  'Security Deposit', _formatMoney(unit.securityDeposit!)),
          ],
        ),
        if (unit.features.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InfoCard(
            colors: colors,
            title: 'Features',
            icon: LucideIcons.sparkles,
            rows: unit.features
                .map((f) => _InfoRowData(f, ''))
                .toList(),
          ),
        ],
        const SizedBox(height: 12),
        // Current tenant link
        if (unit.currentTenantId != null)
          _TappableCard(
            colors: colors,
            title: 'Current Tenant',
            icon: LucideIcons.user,
            subtitle: 'View Tenant Details',
            detail: '',
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TenantDetailScreen(
                      tenantId: unit.currentTenantId!),
                ),
              );
            },
          ),
        if (unit.currentTenantId != null) const SizedBox(height: 12),
        // Active lease link
        if (unit.currentLeaseId != null)
          _TappableCard(
            colors: colors,
            title: 'Active Lease',
            icon: LucideIcons.fileText,
            subtitle: 'View Lease Details',
            detail: '',
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      LeaseDetailScreen(leaseId: unit.currentLeaseId!),
                ),
              );
            },
          ),
        if (unit.currentLeaseId != null) const SizedBox(height: 12),
        // Notes
        if (unit.notes != null && unit.notes!.isNotEmpty) ...[
          Container(
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
                    Icon(LucideIcons.stickyNote,
                        size: 16, color: colors.accentPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Notes',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  unit.notes!,
                  style:
                      TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Unit history stub
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.borderDefault),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.history,
                  size: 16, color: colors.accentPrimary),
              const SizedBox(width: 8),
              Text(
                'Unit History',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Icon(LucideIcons.chevronRight,
                  size: 16, color: colors.textTertiary),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

class _InfoRowData {
  final String label;
  final String value;
  const _InfoRowData(this.label, this.value);
}

class _InfoCard extends StatelessWidget {
  final ZaftoColors colors;
  final String title;
  final IconData icon;
  final List<_InfoRowData> rows;

  const _InfoCard({
    required this.colors,
    required this.title,
    required this.icon,
    required this.rows,
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
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: r.value.isEmpty
                    ? Row(
                        children: [
                          Icon(LucideIcons.check,
                              size: 14, color: colors.accentSuccess),
                          const SizedBox(width: 8),
                          Text(
                            r.label,
                            style: TextStyle(
                                color: colors.textPrimary, fontSize: 14),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(r.label,
                              style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 14)),
                          Flexible(
                            child: Text(
                              r.value,
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
              )),
        ],
      ),
    );
  }
}

class _TappableCard extends StatelessWidget {
  final ZaftoColors colors;
  final String title;
  final IconData icon;
  final String subtitle;
  final String detail;
  final VoidCallback onTap;

  const _TappableCard({
    required this.colors,
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderDefault),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: colors.accentPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (detail.isNotEmpty)
                    Text(
                      detail,
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 13),
                    ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 16, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}
