import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/property.dart';
import '../../repositories/tenant_repository.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class TenantDetailScreen extends ConsumerStatefulWidget {
  final String tenantId;

  const TenantDetailScreen({super.key, required this.tenantId});

  @override
  ConsumerState<TenantDetailScreen> createState() =>
      _TenantDetailScreenState();
}

class _TenantDetailScreenState extends ConsumerState<TenantDetailScreen> {
  Tenant? _tenant;
  bool _isLoading = true;
  String? _error;

  final _currencyFormat = NumberFormat.currency(symbol: '\$');
  String _formatMoney(double v) => _currencyFormat.format(v);
  String _formatDate(DateTime? d) =>
      d != null ? DateFormat.yMMMd().format(d) : 'N/A';

  @override
  void initState() {
    super.initState();
    _loadTenant();
  }

  Future<void> _loadTenant() async {
    try {
      final repo = TenantRepository();
      final tenant = await repo.getTenant(widget.tenantId);
      if (mounted) {
        setState(() {
          _tenant = tenant;
          _isLoading = false;
          if (tenant == null) _error = 'Tenant not found';
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

  Color _tenantStatusColor(ZaftoColors colors, TenantStatus status) {
    switch (status) {
      case TenantStatus.active:
        return colors.accentSuccess;
      case TenantStatus.inactive:
        return colors.textTertiary;
      case TenantStatus.evicted:
        return colors.accentError;
      case TenantStatus.pastTenant:
        return colors.accentWarning;
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
          _tenant?.displayName ?? 'Tenant',
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
          : _tenant == null
              ? _buildPlaceholder(colors)
              : _buildContent(colors, _tenant!),
    );
  }

  Widget _buildPlaceholder(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.user, size: 40, color: colors.textQuaternary),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Tenant not found',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ZaftoColors colors, Tenant tenant) {
    final statusColor = _tenantStatusColor(colors, tenant.status);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Name header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.borderDefault),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    colors.accentPrimary.withValues(alpha: 0.12),
                radius: 24,
                child: Text(
                  tenant.name.isNotEmpty
                      ? tenant.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: colors.accentPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.displayName,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tenant.status.name.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Contact
        _SectionCard(
          colors: colors,
          title: 'Contact',
          icon: LucideIcons.phone,
          children: [
            _InfoRow(
                colors: colors,
                label: 'Phone',
                value: tenant.phone ?? 'N/A'),
            _InfoRow(
                colors: colors,
                label: 'Email',
                value: tenant.email ?? 'N/A'),
            _InfoRow(
                colors: colors,
                label: 'Emergency Contact',
                value: tenant.emergencyContactName ?? 'N/A'),
            if (tenant.emergencyContactPhone != null)
              _InfoRow(
                  colors: colors,
                  label: 'Emergency Phone',
                  value: tenant.emergencyContactPhone!),
          ],
        ),
        const SizedBox(height: 12),
        // Employment & financial
        _SectionCard(
          colors: colors,
          title: 'Employment & Financial',
          icon: LucideIcons.briefcase,
          children: [
            _InfoRow(
                colors: colors,
                label: 'Employer',
                value: tenant.employer ?? 'N/A'),
            if (tenant.employerPhone != null)
              _InfoRow(
                  colors: colors,
                  label: 'Employer Phone',
                  value: tenant.employerPhone!),
            _InfoRow(
                colors: colors,
                label: 'Monthly Income',
                value: tenant.monthlyIncome != null
                    ? _formatMoney(tenant.monthlyIncome!)
                    : 'N/A'),
            _InfoRow(
                colors: colors,
                label: 'Credit Score',
                value: tenant.creditScore != null
                    ? '${tenant.creditScore}'
                    : 'N/A'),
            if (tenant.backgroundCheckStatus != null)
              _InfoRow(
                  colors: colors,
                  label: 'Background Check',
                  value: tenant.backgroundCheckStatus!),
          ],
        ),
        const SizedBox(height: 12),
        // Dates
        _SectionCard(
          colors: colors,
          title: 'Dates',
          icon: LucideIcons.calendar,
          children: [
            _InfoRow(
                colors: colors,
                label: 'Move-In',
                value: _formatDate(tenant.moveInDate)),
            _InfoRow(
                colors: colors,
                label: 'Move-Out',
                value: _formatDate(tenant.moveOutDate)),
            if (tenant.dateOfBirth != null)
              _InfoRow(
                  colors: colors,
                  label: 'Date of Birth',
                  value: _formatDate(tenant.dateOfBirth)),
          ],
        ),
        if (tenant.notes != null && tenant.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            colors: colors,
            title: 'Notes',
            icon: LucideIcons.stickyNote,
            children: [
              Text(
                tenant.notes!,
                style:
                    TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================

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
