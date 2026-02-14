import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/maintenance_request.dart';
import '../../services/pm_maintenance_service.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  MaintenanceStatus? _statusFilter;
  MaintenanceUrgency? _urgencyFilter;

  String _formatDate(DateTime d) => DateFormat('MMM d').format(d);

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final requestsAsync = ref.watch(maintenanceRequestsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        title: Text(
          'Maintenance',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(maintenanceRequestsProvider.notifier).load();
            },
            icon: Icon(LucideIcons.refreshCw, size: 20, color: colors.textSecondary),
          ),
        ],
      ),
      body: requestsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: colors.accentPrimary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertCircle, size: 48, color: colors.accentError),
              const SizedBox(height: 12),
              Text(
                'Failed to load requests',
                style: TextStyle(color: colors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.read(maintenanceRequestsProvider.notifier).load(),
                child: Text('Retry', style: TextStyle(color: colors.accentPrimary)),
              ),
            ],
          ),
        ),
        data: (requests) => _buildContent(colors, requests),
      ),
    );
  }

  Widget _buildContent(ZaftoColors colors, List<MaintenanceRequest> requests) {
    final filtered = requests.where((r) {
      if (_statusFilter != null && r.status != _statusFilter) return false;
      if (_urgencyFilter != null && r.urgency != _urgencyFilter) return false;
      return true;
    }).toList();

    return Column(
      children: [
        // Status filters
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                colors: colors,
                label: 'All',
                isSelected: _statusFilter == null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _statusFilter = null);
                },
              ),
              _FilterChip(
                colors: colors,
                label: 'Submitted',
                isSelected: _statusFilter == MaintenanceStatus.submitted,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _statusFilter = MaintenanceStatus.submitted);
                },
              ),
              _FilterChip(
                colors: colors,
                label: 'Reviewed',
                isSelected: _statusFilter == MaintenanceStatus.reviewed,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _statusFilter = MaintenanceStatus.reviewed);
                },
              ),
              _FilterChip(
                colors: colors,
                label: 'Scheduled',
                isSelected: _statusFilter == MaintenanceStatus.scheduled,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _statusFilter = MaintenanceStatus.scheduled);
                },
              ),
              _FilterChip(
                colors: colors,
                label: 'In Progress',
                isSelected: _statusFilter == MaintenanceStatus.inProgress,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _statusFilter = MaintenanceStatus.inProgress);
                },
              ),
              _FilterChip(
                colors: colors,
                label: 'Completed',
                isSelected: _statusFilter == MaintenanceStatus.completed,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _statusFilter = MaintenanceStatus.completed);
                },
              ),
            ],
          ),
        ),
        // Urgency filters
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                colors: colors,
                label: 'Any Urgency',
                isSelected: _urgencyFilter == null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _urgencyFilter = null);
                },
              ),
              _FilterChip(
                colors: colors,
                label: 'Emergency',
                isSelected: _urgencyFilter == MaintenanceUrgency.emergency,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _urgencyFilter = MaintenanceUrgency.emergency);
                },
              ),
              _FilterChip(
                colors: colors,
                label: 'High',
                isSelected: _urgencyFilter == MaintenanceUrgency.high,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _urgencyFilter = MaintenanceUrgency.high);
                },
              ),
              _FilterChip(
                colors: colors,
                label: 'Normal',
                isSelected: _urgencyFilter == MaintenanceUrgency.normal,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _urgencyFilter = MaintenanceUrgency.normal);
                },
              ),
              _FilterChip(
                colors: colors,
                label: 'Low',
                isSelected: _urgencyFilter == MaintenanceUrgency.low,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _urgencyFilter = MaintenanceUrgency.low);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Request list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.wrench, size: 48, color: colors.textTertiary),
                      const SizedBox(height: 12),
                      Text(
                        'No requests match filters',
                        style: TextStyle(color: colors.textSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _MaintenanceCard(
                    colors: colors,
                    request: filtered[index],
                    formatDate: _formatDate,
                    onHandleMyself: () => _handleMyself(filtered[index]),
                    onAssign: () => _assignToTeam(filtered[index]),
                    onDispatch: () => _dispatchVendor(filtered[index]),
                  ),
                ),
        ),
      ],
    );
  }

  void _handleMyself(MaintenanceRequest request) {
    HapticFeedback.selectionClick();
    ref.read(maintenanceRequestsProvider.notifier).handleIt(request.id);
  }

  void _assignToTeam(MaintenanceRequest request) async {
    HapticFeedback.selectionClick();
    final colors = ref.read(zaftoColorsProvider);
    try {
      final users = await Supabase.instance.client
          .from('users')
          .select('id, display_name, role')
          .inFilter('role', ['technician', 'apprentice'])
          .order('display_name');
      if (!mounted) return;
      final selected = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: colors.bgElevated,
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Assign to Team Member',
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
            ),
            if ((users as List).isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No technicians found',
                    style: TextStyle(color: colors.textSecondary)),
              )
            else
              ...users.map<Widget>((u) => ListTile(
                    leading: Icon(LucideIcons.user, color: colors.textSecondary),
                    title: Text(u['display_name'] ?? 'Unknown',
                        style: TextStyle(color: colors.textPrimary)),
                    subtitle: Text(u['role'] ?? '',
                        style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                    onTap: () => Navigator.pop(ctx, u['id'] as String),
                  )),
            const SizedBox(height: 16),
          ],
        ),
      );
      if (selected != null) {
        ref.read(maintenanceRequestsProvider.notifier).assignTeam(request.id, selected);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load team: $e')),
        );
      }
    }
  }

  void _dispatchVendor(MaintenanceRequest request) async {
    HapticFeedback.selectionClick();
    final colors = ref.read(zaftoColorsProvider);
    try {
      final vendors = await Supabase.instance.client
          .from('vendors')
          .select('id, name, trade')
          .order('name');
      if (!mounted) return;
      final selected = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: colors.bgElevated,
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Dispatch to Vendor',
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
            ),
            if ((vendors as List).isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No vendors found',
                    style: TextStyle(color: colors.textSecondary)),
              )
            else
              ...vendors.map<Widget>((v) => ListTile(
                    leading: Icon(LucideIcons.truck, color: colors.textSecondary),
                    title: Text(v['name'] ?? 'Unknown',
                        style: TextStyle(color: colors.textPrimary)),
                    subtitle: Text(v['trade'] ?? '',
                        style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                    onTap: () => Navigator.pop(ctx, v['id'] as String),
                  )),
            const SizedBox(height: 16),
          ],
        ),
      );
      if (selected != null) {
        ref.read(maintenanceRequestsProvider.notifier).assignVendor(request.id, selected);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load vendors: $e')),
        );
      }
    }
  }
}

Color _urgencyColor(ZaftoColors colors, MaintenanceUrgency urgency) {
  return switch (urgency) {
    MaintenanceUrgency.emergency => colors.error,
    MaintenanceUrgency.high => colors.warning,
    MaintenanceUrgency.normal => colors.accentPrimary,
    MaintenanceUrgency.low => colors.textTertiary,
  };
}

Color _statusColor(ZaftoColors colors, MaintenanceStatus status) {
  return switch (status) {
    MaintenanceStatus.submitted => colors.accentInfo,
    MaintenanceStatus.reviewed => colors.warning,
    MaintenanceStatus.scheduled => colors.accentPrimary,
    MaintenanceStatus.inProgress => colors.accentPrimary,
    MaintenanceStatus.completed => colors.success,
    MaintenanceStatus.cancelled => colors.textTertiary,
  };
}

String _statusLabel(MaintenanceStatus status) {
  return switch (status) {
    MaintenanceStatus.submitted => 'SUBMITTED',
    MaintenanceStatus.reviewed => 'REVIEWED',
    MaintenanceStatus.scheduled => 'SCHEDULED',
    MaintenanceStatus.inProgress => 'IN PROGRESS',
    MaintenanceStatus.completed => 'COMPLETED',
    MaintenanceStatus.cancelled => 'CANCELLED',
  };
}

String _urgencyLabel(MaintenanceUrgency urgency) {
  return switch (urgency) {
    MaintenanceUrgency.emergency => 'EMERGENCY',
    MaintenanceUrgency.high => 'HIGH',
    MaintenanceUrgency.normal => 'NORMAL',
    MaintenanceUrgency.low => 'LOW',
  };
}

class _FilterChip extends StatelessWidget {
  final ZaftoColors colors;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.colors,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accentPrimary.withValues(alpha: 0.12)
              : colors.bgElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.accentPrimary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colors.accentPrimary : colors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  final ZaftoColors colors;
  final MaintenanceRequest request;
  final String Function(DateTime) formatDate;
  final VoidCallback onHandleMyself;
  final VoidCallback onAssign;
  final VoidCallback onDispatch;

  const _MaintenanceCard({
    required this.colors,
    required this.request,
    required this.formatDate,
    required this.onHandleMyself,
    required this.onAssign,
    required this.onDispatch,
  });

  @override
  Widget build(BuildContext context) {
    final uColor = _urgencyColor(colors, request.urgency);
    final sColor = _statusColor(colors, request.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + badges
          Row(
            children: [
              Expanded(
                child: Text(
                  request.title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: uColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _urgencyLabel(request.urgency),
                  style: TextStyle(
                    color: uColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: sColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel(request.status),
                  style: TextStyle(
                    color: sColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Category + date
          Row(
            children: [
              Icon(LucideIcons.tag, size: 13, color: colors.textTertiary),
              const SizedBox(width: 4),
              Text(
                request.category.name,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const Spacer(),
              Icon(LucideIcons.calendar, size: 13, color: colors.textTertiary),
              const SizedBox(width: 4),
              Text(
                formatDate(request.createdAt),
                style: TextStyle(color: colors.textTertiary, fontSize: 12),
              ),
            ],
          ),
          if (request.description != null) ...[
            const SizedBox(height: 8),
            Text(
              request.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ],
          if (request.estimatedCost != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(LucideIcons.dollarSign, size: 13, color: colors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  'Est. \$${request.estimatedCost!.toStringAsFixed(2)}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                if (request.actualCost != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Actual \$${request.actualCost!.toStringAsFixed(2)}',
                    style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ],
          // Show action buttons only for actionable statuses
          if (request.status != MaintenanceStatus.completed &&
              request.status != MaintenanceStatus.cancelled) ...[
            const SizedBox(height: 12),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    colors: colors,
                    label: "I'll Handle It",
                    icon: LucideIcons.hammer,
                    isPrimary: true,
                    onTap: onHandleMyself,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    colors: colors,
                    label: 'Assign',
                    icon: LucideIcons.userPlus,
                    isPrimary: false,
                    onTap: onAssign,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    colors: colors,
                    label: 'Dispatch',
                    icon: LucideIcons.truck,
                    isPrimary: false,
                    onTap: onDispatch,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final ZaftoColors colors;
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionBtn({
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary
              ? colors.accentPrimary.withValues(alpha: 0.12)
              : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary ? colors.accentPrimary : colors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isPrimary ? colors.accentPrimary : colors.textSecondary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isPrimary ? colors.accentPrimary : colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
