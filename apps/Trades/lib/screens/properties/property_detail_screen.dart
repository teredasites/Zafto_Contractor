import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/property.dart';
import '../../services/property_service.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import 'unit_detail_screen.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final String propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Property? _property;
  bool _isLoading = true;
  String? _error;

  final _currencyFormat = NumberFormat.currency(symbol: '\$');
  String _formatMoney(double v) => _currencyFormat.format(v);
  String _formatDate(DateTime? d) =>
      d != null ? DateFormat.yMMMd().format(d) : 'N/A';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadProperty();
  }

  Future<void> _loadProperty() async {
    try {
      final service = ref.read(propertyServiceProvider);
      final property = await service.getProperty(widget.propertyId);
      if (mounted) {
        setState(() {
          _property = property;
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        title: Text(
          _property?.name ?? 'Property',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: colors.accentPrimary,
          unselectedLabelColor: colors.textTertiary,
          indicatorColor: colors.accentPrimary,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Units'),
            Tab(text: 'Financials'),
            Tab(text: 'Maintenance'),
            Tab(text: 'Assets'),
          ],
        ),
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
              : _property == null
                  ? Center(
                      child: Text(
                        'Property not found',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _OverviewTab(
                          colors: colors,
                          property: _property!,
                          formatMoney: _formatMoney,
                          formatDate: _formatDate,
                        ),
                        _UnitsTab(
                          colors: colors,
                          propertyId: widget.propertyId,
                        ),
                        _FinancialsTab(
                          colors: colors,
                          property: _property!,
                          propertyId: widget.propertyId,
                          formatMoney: _formatMoney,
                        ),
                        _PlaceholderTab(
                          colors: colors,
                          icon: LucideIcons.wrench,
                          label: 'Maintenance',
                          message: 'Coming soon',
                        ),
                        _PlaceholderTab(
                          colors: colors,
                          icon: LucideIcons.hardDrive,
                          label: 'Assets',
                          message: 'Coming soon',
                        ),
                      ],
                    ),
    );
  }
}

// =============================================================================
// OVERVIEW TAB
// =============================================================================

class _OverviewTab extends StatelessWidget {
  final ZaftoColors colors;
  final Property property;
  final String Function(double) formatMoney;
  final String Function(DateTime?) formatDate;

  const _OverviewTab({
    required this.colors,
    required this.property,
    required this.formatMoney,
    required this.formatDate,
  });

  String _formatPropertyType(PropertyType type) {
    switch (type) {
      case PropertyType.singleFamily:
        return 'Single Family';
      case PropertyType.multiFamily:
        return 'Multi Family';
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.condo:
        return 'Condo';
      case PropertyType.townhouse:
        return 'Townhouse';
      case PropertyType.duplex:
        return 'Duplex';
      case PropertyType.commercial:
        return 'Commercial';
      case PropertyType.mixedUse:
        return 'Mixed Use';
      case PropertyType.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _SectionCard(
          colors: colors,
          title: 'Property Info',
          icon: LucideIcons.building2,
          children: [
            _InfoRow(
                colors: colors,
                label: 'Address',
                value: property.fullAddress),
            _InfoRow(
                colors: colors,
                label: 'Type',
                value: _formatPropertyType(property.propertyType)),
            _InfoRow(
                colors: colors,
                label: 'Total Units',
                value: '${property.totalUnits}'),
            _InfoRow(
                colors: colors,
                label: 'Status',
                value: property.status.name),
            if (property.ownerEntity != null)
              _InfoRow(
                  colors: colors,
                  label: 'Owner Entity',
                  value: property.ownerEntity!),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          colors: colors,
          title: 'Purchase Info',
          icon: LucideIcons.receipt,
          children: [
            _InfoRow(
                colors: colors,
                label: 'Purchase Price',
                value: property.purchasePrice != null
                    ? formatMoney(property.purchasePrice!)
                    : 'N/A'),
            _InfoRow(
                colors: colors,
                label: 'Purchase Date',
                value: formatDate(property.purchaseDate)),
            _InfoRow(
                colors: colors,
                label: 'Current Value',
                value: property.currentValue != null
                    ? formatMoney(property.currentValue!)
                    : 'N/A'),
            _InfoRow(
                colors: colors,
                label: 'Mortgage Balance',
                value: property.mortgageBalance != null
                    ? formatMoney(property.mortgageBalance!)
                    : 'N/A'),
            _InfoRow(
                colors: colors,
                label: 'Mortgage Payment',
                value: property.mortgagePayment != null
                    ? formatMoney(property.mortgagePayment!)
                    : 'N/A'),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          colors: colors,
          title: 'Insurance',
          icon: LucideIcons.shield,
          children: [
            _InfoRow(
                colors: colors,
                label: 'Provider',
                value: property.insuranceProvider ?? 'N/A'),
            _InfoRow(
                colors: colors,
                label: 'Policy #',
                value: property.insurancePolicyNumber ?? 'N/A'),
            _InfoRow(
                colors: colors,
                label: 'Premium',
                value: property.insurancePremium != null
                    ? formatMoney(property.insurancePremium!)
                    : 'N/A'),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          colors: colors,
          title: 'Taxes',
          icon: LucideIcons.landmark,
          children: [
            _InfoRow(
                colors: colors,
                label: 'Tax Assessment',
                value: property.taxAssessment != null
                    ? formatMoney(property.taxAssessment!)
                    : 'N/A'),
            _InfoRow(
                colors: colors,
                label: 'Annual Tax',
                value: property.annualTax != null
                    ? formatMoney(property.annualTax!)
                    : 'N/A'),
          ],
        ),
        if (property.notes != null && property.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            colors: colors,
            title: 'Notes',
            icon: LucideIcons.stickyNote,
            children: [
              Text(
                property.notes!,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// UNITS TAB
// =============================================================================

class _UnitsTab extends ConsumerWidget {
  final ZaftoColors colors;
  final String propertyId;

  const _UnitsTab({required this.colors, required this.propertyId});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsProvider(propertyId));

    return unitsAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: colors.accentPrimary),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: TextStyle(color: colors.textSecondary),
        ),
      ),
      data: (units) => units.isEmpty
          ? Center(
              child: Text(
                'No units added yet',
                style: TextStyle(color: colors.textSecondary),
              ),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: units.length,
              itemBuilder: (context, index) {
                final unit = units[index];
                final statusColor =
                    _unitStatusColor(colors, unit.status);

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UnitDetailScreen(
                          unitId: unit.id,
                          propertyId: propertyId,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.bgElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.borderDefault),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.doorOpen,
                            color: colors.textTertiary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                unit.unitNumber,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${unit.bedrooms ?? '-'}bd / ${unit.bathrooms ?? '-'}ba / ${unit.squareFeet ?? '-'} sqft',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${unit.monthlyRent.toStringAsFixed(0)}/mo',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                unit.status.name.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// =============================================================================
// FINANCIALS TAB
// =============================================================================

class _FinancialsTab extends ConsumerWidget {
  final ZaftoColors colors;
  final Property property;
  final String propertyId;
  final String Function(double) formatMoney;

  const _FinancialsTab({
    required this.colors,
    required this.property,
    required this.propertyId,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsProvider(propertyId));

    return unitsAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: colors.accentPrimary),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: TextStyle(color: colors.textSecondary),
        ),
      ),
      data: (units) {
        final totalRent = units.fold<double>(
            0.0, (sum, u) => sum + u.monthlyRent);
        final occupiedCount =
            units.where((u) => u.status == UnitStatus.occupied).length;

        final monthlyExpenses = (property.mortgagePayment ?? 0) +
            ((property.annualTax ?? 0) / 12) +
            ((property.insurancePremium ?? 0) / 12);
        final netIncome = totalRent - monthlyExpenses;

        return ListView(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            _SectionCard(
              colors: colors,
              title: 'Rent Roll',
              icon: LucideIcons.banknote,
              children: [
                _InfoRow(
                    colors: colors,
                    label: 'Monthly Rent Total',
                    value: formatMoney(totalRent)),
                _InfoRow(
                    colors: colors,
                    label: 'Occupied Units',
                    value: '$occupiedCount / ${property.totalUnits}'),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              colors: colors,
              title: 'Expenses',
              icon: LucideIcons.trendingDown,
              children: [
                _InfoRow(
                    colors: colors,
                    label: 'Mortgage',
                    value: formatMoney(property.mortgagePayment ?? 0)),
                _InfoRow(
                    colors: colors,
                    label: 'Annual Tax',
                    value: formatMoney(property.annualTax ?? 0)),
                _InfoRow(
                    colors: colors,
                    label: 'Insurance Premium',
                    value: formatMoney(property.insurancePremium ?? 0)),
                if (property.managementFeePct != null)
                  _InfoRow(
                      colors: colors,
                      label: 'Mgmt Fee',
                      value:
                          '${property.managementFeePct!.toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.accentPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: colors.accentPrimary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Est. Net Monthly',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    formatMoney(netIncome),
                    style: TextStyle(
                      color: netIncome >= 0
                          ? colors.accentSuccess
                          : colors.accentError,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// PLACEHOLDER TAB (Maintenance, Assets)
// =============================================================================

class _PlaceholderTab extends StatelessWidget {
  final ZaftoColors colors;
  final IconData icon;
  final String label;
  final String message;

  const _PlaceholderTab({
    required this.colors,
    required this.icon,
    required this.label,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: colors.textQuaternary),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 14,
            ),
          ),
        ],
      ),
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
