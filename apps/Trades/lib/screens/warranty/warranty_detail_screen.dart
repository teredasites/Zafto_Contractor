// ZAFTO Warranty Detail Screen
// W2: Equipment detail with warranty info, claims, outreach history.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/supabase_client.dart';
import '../../models/warranty_claim.dart';
import '../../models/warranty_outreach_log.dart';
import '../../providers/warranty_intelligence_provider.dart';

// Semantic warranty status colors (matches ZaftoColors tokens)
const _kError = Color(0xFFEF4444);
const _kWarning = Color(0xFFF59E0B);
const _kSuccess = Color(0xFF22C55E);

class WarrantyDetailScreen extends ConsumerStatefulWidget {
  final String equipmentId;

  const WarrantyDetailScreen({super.key, required this.equipmentId});

  @override
  ConsumerState<WarrantyDetailScreen> createState() =>
      _WarrantyDetailScreenState();
}

class _WarrantyDetailScreenState extends ConsumerState<WarrantyDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _equipment;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEquipment();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEquipment() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await supabase
          .from('home_equipment')
          .select(
              '*, customers(name, email, phone, address)')
          .eq('id', widget.equipmentId)
          .single();

      if (mounted) {
        setState(() {
          _equipment = response;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_equipment != null
            ? (_equipment!['name'] as String? ?? 'Equipment')
            : 'Equipment Detail'),
        bottom: _equipment != null
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Warranty'),
                  Tab(text: 'Claims'),
                  Tab(text: 'Outreach'),
                ],
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Error state
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertTriangle,
                  size: 48, color: _kError),
              const SizedBox(height: 12),
              Text('Failed to load equipment',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ElevatedButton(
                  onPressed: _loadEquipment, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    // Loading state
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Empty state (not found)
    if (_equipment == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.search, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('Equipment not found',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    // Data state
    return TabBarView(
      controller: _tabController,
      children: [
        _warrantyTab(),
        _claimsTab(),
        _outreachTab(),
      ],
    );
  }

  // ── Warranty Tab ─────────────────────────────────────────────
  Widget _warrantyTab() {
    final eq = _equipment!;
    final warrantyEnd = eq['warranty_end_date'] as String?;
    final warrantyStart = eq['warranty_start_date'] as String?;
    final warrantyType = eq['warranty_type'] as String?;
    final provider = eq['warranty_provider'] as String?;
    final customer = eq['customers'] as Map<String, dynamic>?;

    Color statusColor;
    String statusLabel;
    if (warrantyEnd == null) {
      statusColor = Colors.grey;
      statusLabel = 'No Warranty';
    } else {
      final daysLeft = DateTime.parse(warrantyEnd).difference(DateTime.now()).inDays;
      if (daysLeft < 0) {
        statusColor = Colors.grey;
        statusLabel = 'Expired';
      } else if (daysLeft < 90) {
        statusColor = _kError;
        statusLabel = '$daysLeft days remaining';
      } else if (daysLeft < 180) {
        statusColor = _kWarning;
        statusLabel = '${(daysLeft / 30).round()} months remaining';
      } else {
        statusColor = _kSuccess;
        statusLabel = '${(daysLeft / 30).round()} months remaining';
      }
    }

    return RefreshIndicator(
      onRefresh: _loadEquipment,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Warranty status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.shield, color: statusColor, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Warranty Status',
                                style: Theme.of(context).textTheme.titleSmall),
                            Text(statusLabel,
                                style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _detailRow('Type', _warrantyTypeLabel(warrantyType)),
                  _detailRow('Provider', provider ?? 'Not specified'),
                  _detailRow('Start', warrantyStart ?? '—'),
                  _detailRow('End', warrantyEnd ?? '—'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Equipment details card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Equipment Details',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 12),
                  _detailRow('Name', eq['name'] as String? ?? '—'),
                  _detailRow(
                      'Manufacturer', eq['manufacturer'] as String? ?? '—'),
                  _detailRow('Model', eq['model_number'] as String? ?? '—'),
                  _detailRow('Serial #', eq['serial_number'] as String? ?? '—'),
                  if (eq['recall_status'] != null &&
                      eq['recall_status'] != 'none')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _kError.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.alertTriangle,
                                size: 16, color: _kError),
                            const SizedBox(width: 8),
                            Text('Active Recall',
                                style: TextStyle(
                                    color: _kError,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Customer info
          if (customer != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 12),
                    _detailRow('Name', customer['name'] as String? ?? '—'),
                    _detailRow('Email', customer['email'] as String? ?? '—'),
                    _detailRow('Phone', customer['phone'] as String? ?? '—'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Claims Tab ───────────────────────────────────────────────
  Widget _claimsTab() {
    final claimsAsync =
        ref.watch(warrantyClaimsByEquipmentProvider(widget.equipmentId));

    return claimsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: TextStyle(color: _kError)),
      ),
      data: (claims) {
        if (claims.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.fileCheck, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('No Claims',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('No warranty claims have been filed.',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: claims.length,
          itemBuilder: (context, index) => _claimCard(claims[index]),
        );
      },
    );
  }

  Widget _claimCard(WarrantyClaim claim) {
    final color = switch (claim.claimStatus) {
      ClaimStatus.submitted => Colors.blue,
      ClaimStatus.underReview => _kWarning,
      ClaimStatus.approved => _kSuccess,
      ClaimStatus.denied => _kError,
      ClaimStatus.resolved => _kSuccess,
      ClaimStatus.closed => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(claim.claimReason,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(claim.claimStatus.label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                    'Filed: ${claim.claimDate.toIso8601String().split('T').first}',
                    style: Theme.of(context).textTheme.bodySmall),
                if (claim.manufacturerClaimNumber != null) ...[
                  const SizedBox(width: 12),
                  Text('Claim #: ${claim.manufacturerClaimNumber}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
            if (claim.amountClaimed != null) ...[
              const SizedBox(height: 4),
              Text(
                  'Claimed: \$${claim.amountClaimed!.toStringAsFixed(2)}${claim.amountApproved != null ? '  •  Approved: \$${claim.amountApproved!.toStringAsFixed(2)}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            if (claim.resolutionNotes != null) ...[
              const SizedBox(height: 4),
              Text(claim.resolutionNotes!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  // ── Outreach Tab ─────────────────────────────────────────────
  Widget _outreachTab() {
    final outreachAsync =
        ref.watch(outreachByEquipmentProvider(widget.equipmentId));

    return outreachAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: TextStyle(color: _kError)),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.mailOpen, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('No Outreach History',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Automated outreach will appear here.',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) => _outreachCard(logs[index]),
        );
      },
    );
  }

  Widget _outreachCard(WarrantyOutreachLog log) {
    final responseColor = switch (log.responseStatus) {
      ResponseStatus.booked => _kSuccess,
      ResponseStatus.clicked => Colors.blue,
      ResponseStatus.opened => Colors.blue,
      ResponseStatus.declined => _kError,
      ResponseStatus.noResponse => Colors.grey,
      ResponseStatus.pending => _kWarning,
      null => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              switch (log.outreachType) {
                OutreachType.warrantyExpiring => LucideIcons.clock,
                OutreachType.maintenanceReminder => LucideIcons.wrench,
                OutreachType.recallNotice => LucideIcons.alertTriangle,
                OutreachType.upsellExtended => LucideIcons.shieldCheck,
                OutreachType.seasonalCheck => LucideIcons.thermometer,
              },
              size: 20,
              color: Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.outreachType.label,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                      log.sentAt != null
                          ? 'Sent ${log.sentAt!.toIso8601String().split('T').first}'
                          : 'Pending',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (log.responseStatus != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: responseColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.responseStatus!.dbValue.replaceAll('_', ' '),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: responseColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey))),
          Expanded(
              child: Text(value,
                  style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

  String _warrantyTypeLabel(String? type) {
    switch (type) {
      case 'manufacturer':
        return 'Manufacturer';
      case 'extended':
        return 'Extended';
      case 'labor':
        return 'Labor Only';
      case 'parts_labor':
        return 'Parts & Labor';
      case 'home_warranty':
        return 'Home Warranty';
      default:
        return 'Not specified';
    }
  }
}
